import wave
import io
import base64
from google.genai import types

STORYTELLER_VOICES = {
    "bulgarian": {"voice": "Aoede", "style": None},
    "turkish": {
        "voice": "Despina",
        "style": "Say this at a relaxed, unhurried pace, in a low, deep, mysterious tone:",
    },
}


def synthesize_speech(client, storyteller: str, text: str) -> str:
    if not text:
        return ""

    config = STORYTELLER_VOICES.get(storyteller, STORYTELLER_VOICES["bulgarian"])
    voice = config["voice"]
    style = config["style"]
    prompt_text = f"{style} {text}" if style else text

    response = client.models.generate_content(
        model="gemini-2.5-flash-preview-tts",
        contents=prompt_text,
        config=types.GenerateContentConfig(
            response_modalities=["AUDIO"],
            speech_config=types.SpeechConfig(
                voice_config=types.VoiceConfig(
                    prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=voice)
                )
            ),
        ),
    )
    audio_data = response.candidates[0].content.parts[0].inline_data.data

    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(24000)
        wf.writeframes(audio_data)

    return base64.b64encode(buffer.getvalue()).decode("utf-8")
