# CupWhisper — Product Vision Documents

## Storyteller Ritual Experience (Future Feature)

**Category:** Premium UX / Emotional Engagement
**Priority:** After Firebase, AI Service Layer, and Reading Credits

### Goal

Before the analysis begins, the user doesn't just tap "Take Photo." They enter a
short ritual that makes it feel like they are speaking with a real storyteller,
not operating a form. This is not a cosmetic extra — it is a core part of
CupWhisper's identity.

### User Flow

```
Choose Storyteller
        ↓
Storyteller Introduction
        ↓
Voice Greeting
        ↓
Camera / Gallery
        ↓
Preview
        ↓
AI Reading Experience
```

### Each Storyteller Has

- A distinct visual/art style
- A distinct personality
- A distinct voice
- A distinct greeting
- Optional background music/ambience
- A short entrance animation (2–4 seconds)

### Example Greetings (localized, poetic — not literal translations)

- 🇧🇬 Bulgarian: "Всяка чаша пази тайна... нека разкрия твоята."
- 🇹🇷 Turkish: "Her fincan bir sır saklar... şimdi seninkini dinleyelim."
- 🇬🇧 English: "Every cup hides a story... let's uncover yours."

### Technical Notes

- Static or lightly animated illustration per storyteller.
- Voice-over clip, 2–4 seconds, per storyteller per language.
- Fade in / fade out transition.
- Automatic transition to Camera Screen after the greeting plays.
- All assets cached locally for fast, offline-capable loading.

---

## Storytellers Have Personalities, Not Just Translations

This is one of the most important ideas in the project so far, and should guide
all future AI prompt design and content work.

**Core principle:** Each storyteller must not simply speak a different
language — they must *think* differently. The reading style, tone, and
symbolism they draw on should reflect a distinct cultural personality, not a
translated copy of the same text.

### Personality Directions (initial concept, to be refined with real AI prompts)

- 🇧🇬 Bulgarian storyteller — wise, folk-rooted, calm.
- 🇹🇷 Turkish storyteller — emotional and symbolic.
- 🇬🇧 English storyteller — modern, psychological in style.
- 🇩🇪 German storyteller — structured and analytical.
- 🇫🇷 French storyteller — poetic and romantic.
- 🇪🇸 Spanish storyteller — warm, energetic, optimistic.

### Why This Matters

Most coffee-reading apps offer six translations of the same content. If
CupWhisper implements this correctly, it won't just offer six languages — it
will offer six distinct experiences. This is a meaningful product
differentiator and should be treated as a first-class design goal, not a
"nice to have."

This principle should directly inform the real AI prompt design in Step 13+
(one prompt template per storyteller, not one template + six translations).
