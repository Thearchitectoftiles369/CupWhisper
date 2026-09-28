import json
import os
import urllib.request
import urllib.error
from dotenv import load_dotenv

load_dotenv()

LANG_BCP47 = {
    "en": "en-US", "bg": "bg-BG", "tr": "tr-TR",
    "de": "de-DE", "fr": "fr-FR", "es": "es-ES",
}

STORYTELLER_VOICES = {
    "bulgarian": {"voice_id": "Aoede", "rate": 1.0, "pitch": 0.0},
    "turkish": {"voice_id": "Despina", "rate": 0.9, "pitch": None},
}

TTS_API_KEY = os.environ.get("TTS_API_KEY") or os.environ.get("GEMINI_API_KEY")

def synthesize_speech(storyteller: str, text: str, language: str = "en") -> str:
    if not text:
        return ""
    config = STORYTELLER_VOICES.get(storyteller, STORYTELLER_VOICES["bulgarian"])
    bcp47 = LANG_BCP47.get(language, "en-US")
    voice_name = f"{bcp47}-Chirp3-HD-{config['voice_id']}"

    audio_config = {
        "audioEncoding": "MP3",
        "speakingRate": config["rate"],
    }
    if config.get("pitch") is not None:
        audio_config["pitch"] = config["pitch"]

    payload = {
        "input": {"text": text},
        "voice": {"languageCode": bcp47, "name": voice_name},
        "audioConfig": audio_config,
    }
    req = urllib.request.Request(
        f"https://texttospeech.googleapis.com/v1/text:synthesize?key={TTS_API_KEY}",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            result = json.load(resp)
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        raise RuntimeError(f"TTS failed ({e.code}) for voice={voice_name} text={text[:60]!r}: {body}") from None
    return result.get("audioContent", "")
