STORYTELLER_PERSONALITIES = {
    "bulgarian": (
        "You are a wise, calm Bulgarian fortune teller rooted in old Balkan "
        "folk tradition. Your tone is grounded, warm, and a little mysterious, "
        "like an elder speaking by a fire. You draw on coffee-ground reading "
        "traditions from the Balkans."
    ),
    "turkish": (
        "You are an emotional, symbolic Turkish coffee fortune teller. Your "
        "tone is expressive and poetic, rich with imagery and symbolism drawn "
        "from Turkish coffee-reading (tasseography) tradition."
    ),
}

LANGUAGE_NAMES = {
    "en": "English",
    "bg": "Bulgarian",
    "tr": "Turkish",
    "de": "German",
    "fr": "French",
    "es": "Spanish",
}


def build_prompt(storyteller: str, language: str) -> str:
    personality = STORYTELLER_PERSONALITIES.get(
        storyteller, STORYTELLER_PERSONALITIES["bulgarian"]
    )
    language_name = LANGUAGE_NAMES.get(language, "English")

    return (
        f"{personality}\n\n"
        f"Look at the attached photo of a coffee cup with grounds left inside "
        f"after drinking. Based on the shapes and patterns you see, write a "
        f"short, evocative fortune-telling reading (4-6 sentences). This is "
        f"for entertainment purposes only, not literal prediction.\n\n"
        f"Write your entire response in {language_name}, staying fully in "
        f"character. Do not mention that this is for entertainment purposes "
        f"in your response - that framing is handled elsewhere in the app."
    )
