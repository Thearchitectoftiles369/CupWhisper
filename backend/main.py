import os
import glob
import json
import random
import asyncio
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
from google import genai
from google.genai import types
from google.oauth2 import service_account as google_service_account
from google.auth.transport.requests import Request as GoogleAuthRequest
import urllib.request as urlreq
import urllib.error as urlerr

from prompts import build_prompt
from tts import synthesize_speech
from auth import verify_token
from credits import (
    consume_credit,
    save_reading,
    claim_free_reading,
    get_reading_credits,
    credit_purchase,
)

load_dotenv()

app = FastAPI(title="CupWhisper AI Gateway")

api_key = os.environ.get("GEMINI_API_KEY")
model_name = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")
tts_enabled = os.environ.get("ENABLE_TTS", "false").lower() == "true"

client = genai.Client(api_key=api_key) if api_key else None

STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static", "free_readings")
FREE_READINGS: dict = {}

PLAY_PACKAGE_NAME = "com.cupwhisper.cupwhisper"
PLAY_SERVICE_ACCOUNT_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "play-billing-key.json")
_play_credentials = None


def _load_free_readings():
    FREE_READINGS.clear()
    if not os.path.isdir(STATIC_DIR):
        return
    for path in glob.glob(os.path.join(STATIC_DIR, "*.json")):
        filename = os.path.basename(path)[:-5]
        parts = filename.rsplit("_v", 1)
        if len(parts) != 2:
            continue
        prefix, _variation = parts
        if "_" not in prefix:
            continue
        storyteller, language = prefix.split("_", 1)
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        FREE_READINGS.setdefault((storyteller, language), []).append(data)


_load_free_readings()


def _get_play_access_token() -> str:
    global _play_credentials
    if _play_credentials is None:
        _play_credentials = google_service_account.Credentials.from_service_account_file(
            PLAY_SERVICE_ACCOUNT_FILE,
            scopes=["https://www.googleapis.com/auth/androidpublisher"],
        )
    if not _play_credentials.valid:
        _play_credentials.refresh(GoogleAuthRequest())
    return _play_credentials.token


def _check_play_purchase(product_id: str, purchase_token: str) -> dict:
    token = _get_play_access_token()
    url = (
        f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
        f"{PLAY_PACKAGE_NAME}/purchases/products/{product_id}/tokens/{purchase_token}"
    )
    req = urlreq.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urlreq.urlopen(req) as resp:
            return json.load(resp)
    except urlerr.HTTPError as e:
        body = e.read().decode()
        raise RuntimeError(f"Play verify failed ({e.code}): {body}") from None


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "free_reading_variants": sum(len(v) for v in FREE_READINGS.values()),
    }


@app.post("/free-reading")
async def create_free_reading(
    storyteller: str = Form(...),
    language: str = Form(...),
    uid: str = Depends(verify_token),
):
    variations = FREE_READINGS.get((storyteller, language)) or FREE_READINGS.get(("bulgarian", "en"), [])
    if not variations:
        raise HTTPException(status_code=500, detail="No free reading content available")

    loop = asyncio.get_event_loop()
    try:
        await loop.run_in_executor(None, claim_free_reading, uid)
    except ValueError:
        raise HTTPException(status_code=409, detail="Free reading already used")

    chosen = random.choice(variations)
    remaining_credits = await loop.run_in_executor(None, get_reading_credits, uid)

    full_text = " ".join(s.get("phrase", "") for s in chosen.get("symbols", [])) + " " + chosen.get("conclusion", "")
    save_reading(uid, storyteller, language, full_text)

    return {
        "symbols": chosen.get("symbols", []),
        "conclusion": chosen.get("conclusion", ""),
        "conclusion_audio": chosen.get("conclusion_audio", ""),
        "remaining_credits": remaining_credits,
    }


@app.post("/verify-purchase")
async def verify_purchase(
    purchaseToken: str = Form(...),
    productId: str = Form(...),
    uid: str = Depends(verify_token),
):
    loop = asyncio.get_event_loop()
    try:
        result = await loop.run_in_executor(None, _check_play_purchase, productId, purchaseToken)
    except RuntimeError as e:
        raise HTTPException(status_code=502, detail=str(e))

    if result.get("purchaseState") != 0:
        raise HTTPException(status_code=402, detail="Purchase not in a valid state")

    try:
        new_balance = await loop.run_in_executor(None, credit_purchase, uid, purchaseToken)
    except ValueError:
        new_balance = await loop.run_in_executor(None, get_reading_credits, uid)

    return {"credited": True, "readingCredits": new_balance}


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
            loop.run_in_executor(None, synthesize_speech, storyteller, s.get("phrase", ""), language)
            for s in symbols
        ]
        conclusion_task = (
            loop.run_in_executor(None, synthesize_speech, storyteller, conclusion, language)
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
