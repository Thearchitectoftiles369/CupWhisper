import os
import json
import asyncio
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
from google import genai
from google.genai import types

from prompts import build_prompt
from tts import synthesize_speech
from auth import verify_token
from credits import consume_credit, save_reading

load_dotenv()

app = FastAPI(title="CupWhisper AI Gateway")

api_key = os.environ.get("GEMINI_API_KEY")
model_name = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")
tts_enabled = os.environ.get("ENABLE_TTS", "false").lower() == "true"

client = genai.Client(api_key=api_key) if api_key else None


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.post("/reading")
async def create_reading(
    storyteller: str = Form(...),
    language: str = Form(...),
    image: UploadFile = File(...),
    uid: str = Depends(verify_token),
):
    if client is None:
        raise HTTPException(status_code=500, detail="Gemini client not configured")

    image_bytes = await image.read()
    prompt = build_prompt(storyteller, language)

    def call_gemini():
        return client.models.generate_content(
            model=model_name,
            contents=[
                types.Part.from_bytes(data=image_bytes, mime_type=image.content_type),
                prompt,
            ],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                thinking_config=types.ThinkingConfig(thinking_budget=0),
            ),
        )

    loop = asyncio.get_event_loop()
    credit_task = loop.run_in_executor(None, consume_credit, uid)
    gemini_task = loop.run_in_executor(None, call_gemini)

    try:
        remaining_credits, response = await asyncio.gather(credit_task, gemini_task)
    except ValueError:
        raise HTTPException(status_code=402, detail="No reading credits remaining")

    try:
        parsed = json.loads(response.text)
        symbols = parsed.get("symbols", [])
        conclusion = parsed.get("conclusion", "")
    except (json.JSONDecodeError, AttributeError):
        symbols = []
        conclusion = ""

    conclusion_audio = ""
    if tts_enabled:
        tts_tasks = [
            loop.run_in_executor(None, synthesize_speech, client, storyteller, s.get("phrase", ""))
            for s in symbols
        ]
        conclusion_task = (
            loop.run_in_executor(None, synthesize_speech, client, storyteller, conclusion)
            if conclusion
            else None
        )

        results = await asyncio.gather(*tts_tasks)
        for symbol, audio in zip(symbols, results):
            symbol["audio"] = audio

        if conclusion_task:
            conclusion_audio = await conclusion_task
    else:
        for symbol in symbols:
            symbol["audio"] = ""

    full_text = " ".join(s.get("phrase", "") for s in symbols) + " " + conclusion
    save_reading(uid, storyteller, language, full_text)

    return {
        "symbols": symbols,
        "conclusion": conclusion,
        "conclusion_audio": conclusion_audio,
        "remaining_credits": remaining_credits,
    }
