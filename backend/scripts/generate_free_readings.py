"""
One-time script: generates static "free reading" content for CupWhisper.
Produces 4 variations x 2 storytellers x 6 languages of pre-written
coffee-cup readings (symbols + phrases + outline points + conclusion),
each with pre-synthesized TTS audio (Cloud Text-to-Speech, Chirp3-HD
voices), so a user's very first reading costs zero live AI calls.

Run once from ~/CupWhisper/backend:
    python scripts/generate_free_readings.py

Safe to re-run: it skips any (storyteller, language, variation) file
that already exists, so a failed run can be resumed.
"""

import os
import sys
import json
import time
from dotenv import load_dotenv

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"))

from google import genai
from prompts import STORYTELLER_PERSONALITIES, LANGUAGE_NAMES
from tts import synthesize_speech

OUTPUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "static", "free_readings",
)

GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")

VARIATION_THEMES = {
    1: "a balanced, general fortune touching on several areas of life",
    2: "a fortune centered on love, relationships, and emotional connections",
    3: "a fortune centered on travel, change, and new paths opening up",
    4: "a fortune centered on luck, success, and prosperity",
}


def build_free_reading_prompt(storyteller: str, language: str, variation: int) -> str:
    personality = STORYTELLER_PERSONALITIES.get(
        storyteller, STORYTELLER_PERSONALITIES["bulgarian"]
    )
    language_name = LANGUAGE_NAMES.get(language, "English")
    theme = VARIATION_THEMES[variation]

    return (
        f"{personality}\n\n"
        f"You are reading an imagined coffee cup - there is no real photo. "
        f"Invent 5 to 7 distinct shapes or symbols that a coffee-ground "
        f"reading could plausibly reveal (for example: a bird, a heart, a "
        f"path, a mountain, a ring, a key, a star, a tree, an eye, a wave, "
        f"and so on). This particular reading should feel like {theme}.\n\n"
        f"For each symbol, provide:\n"
        f"- A short, evocative spoken phrase (8-15 words) in character, as "
        f"if you are pointing it out to the person live, e.g. \"I see a "
        f"bird here, and it tells me news is coming...\"\n"
        f"- A plausible outline of the shape as a series of 6 to 10 points "
        f"tracing its silhouette, in order around the shape (like "
        f"connecting dots to draw it). Each point is normalized x, y (0.0 "
        f"to 1.0) relative to a full coffee-cup interior photo. Keep every "
        f"point within roughly 0.1-0.9 on both axes, and spread the 5-7 "
        f"symbols across different regions of the cup so they don't all "
        f"overlap in the same spot.\n\n"
        f"After listing all symbols, write a short concluding passage (4-6 "
        f"sentences) that weaves the symbols together into one cohesive, "
        f"flowing fortune - as if you are now stepping back and "
        f"summarizing what it all means together.\n\n"
        f"Write everything in {language_name}, using its native alphabet "
        f"and spelling consistently throughout (for example, full Cyrillic "
        f"script for Bulgarian, never Latin transliteration mixed in) - "
        f"fully in character. This is for entertainment purposes only - do "
        f"not mention that framing in your response.\n\n"
        f"Respond ONLY with valid JSON in this exact structure, no other "
        f"text:\n"
        f'{{"symbols": [{{"phrase": "...", "points": [{{"x": 0.0, "y": 0.0}}, '
        f'{{"x": 0.0, "y": 0.0}}]}}], "conclusion": "..."}}'
    )


def generate_one(client, storyteller, language, variation):
    prompt = build_free_reading_prompt(storyteller, language, variation)

    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=prompt,
    )
    raw = response.text.strip()
    if raw.startswith("```"):
        raw = raw.strip("`")
        if raw.startswith("json"):
            raw = raw[4:]
    data = json.loads(raw)

    for symbol in data["symbols"]:
        symbol["audio"] = synthesize_speech(storyteller, symbol["phrase"], language)
        time.sleep(0.1)

    data["conclusion_audio"] = synthesize_speech(storyteller, data["conclusion"], language)
    return data


def main():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("GEMINI_API_KEY not set")
        sys.exit(1)

    client = genai.Client(api_key=api_key)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for storyteller in STORYTELLER_PERSONALITIES:
        for language in LANGUAGE_NAMES:
            for variation in range(1, 5):
                out_path = os.path.join(
                    OUTPUT_DIR, f"{storyteller}_{language}_v{variation}.json"
                )
                if os.path.exists(out_path):
                    print(f"skip (exists): {out_path}")
                    continue

                print(f"generating: {storyteller}/{language}/v{variation}")
                try:
                    data = generate_one(client, storyteller, language, variation)
                except Exception as e:
                    print(f"  FAILED: {e}")
                    continue

                with open(out_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, ensure_ascii=False)

                print(f"  saved ({len(data['symbols'])} symbols)")
                time.sleep(0.2)

    print("Done.")


if __name__ == "__main__":
    main()
