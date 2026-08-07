import os
import wave
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

GREETINGS = {
    "bulgarian": {
        "text": "Every cup keeps a secret... let me reveal yours.",
        "voice": "Aoede",
        "style": None,
    },
    "turkish": {
        "text": "Let's see what your fortune holds today...",
        "voice": "Despina",
        "style": "Say this at a relaxed, unhurried pace, in a low, deep, mysterious tone:",
    },
}

for storyteller, config in GREETINGS.items():
    prompt_text = f"{config['style']} {config['text']}" if config["style"] else config["text"]

    response = client.models.generate_content(
        model="gemini-2.5-flash-preview-tts",
        contents=prompt_text,
        config=types.GenerateContentConfig(
            response_modalities=["AUDIO"],
            speech_config=types.SpeechConfig(
                voice_config=types.VoiceConfig(
                    prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=config["voice"])
                )
            ),
        ),
    )
    audio_data = response.candidates[0].content.parts[0].inline_data.data

    filename = f"{storyteller}_greeting_audio.wav"
    with wave.open(filename, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(24000)
        wf.writeframes(audio_data)

    print(f"Saved {filename}")

print("Done")
