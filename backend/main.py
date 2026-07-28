import os
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from google import genai
from google.genai import types

from prompts import build_prompt

load_dotenv()

app = FastAPI(title="CupWhisper AI Gateway")

api_key = os.environ.get("GEMINI_API_KEY")
model_name = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")

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
    )

    return {"story": response.text}
