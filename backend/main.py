import os
import json
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from google import genai
from google.genai import types

from prompts import build_prompt
from tts import synthesize_speech

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
):
    if client is None:
        raise HTTPException(status_code=500, detail="Gemini client not configured")

    image_bytes = await image.read()
    prompt = build_prompt(storyteller, language)

    response = client.models.generate_content(
        model=model_name,
        contents=[
            types.Part.from_bytes(data=image_bytes, mime_type=image.content_type),
            prompt,
        ],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
        ),
    )

    try:
        parsed = json.loads(response.text)
        symbols = parsed.get("symbols", [])
        conclusion = parsed.get("conclusion", "")
    except (json.JSONDecodeError, AttributeError):
        symbols = []
        conclusion = ""

    conclusion_audio = ""
    if tts_enabled:
        for symbol in symbols:
            symbol["audio"] = synthesize_speech(client, storyteller, symbol.get("phrase", ""))
        conclusion_audio = synthesize_speech(client, storyteller, conclusion) if conclusion else ""
    else:
        for symbol in symbols:
            symbol["audio"] = ""

    return {
        "symbols": symbols,
        "conclusion": conclusion,
        "conclusion_audio": conclusion_audio,
    }
