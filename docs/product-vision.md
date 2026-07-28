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

---

## Treat a Friend (Future Feature)

**Category:** Viral Growth / Emotional Engagement
**Priority:** After Cloud Functions and Reading Credits (AD-003) are in place —
this feature is fundamentally a credit-transfer mechanism and must not be
built on a temporary, insecure foundation.

### Goal

Let a user "treat" someone else to a coffee reading, the way you'd buy a
friend an actual coffee. The gift is framed as an emotional gesture, not a
referral mechanic — the growth effect is a side benefit, not the pitch.

### Flow

1. User taps **"☕ Treat a Friend with Coffee"**.
2. They choose a recipient: phone number, email, or a contact from their
   phone.
3. They can add a short personal message, e.g.:
   *"Yulian ❤️ Today I'm treating you to a coffee. Let's see what stories
   your cup holds."*
4. The app sends a message to the recipient.

### If the recipient does NOT have CupWhisper

They receive a message like:

> ☕ Yulian treated you to a coffee.
> Every cup holds its own secret.
> Tap here to discover what the fortune teller will reveal.
>
> [ Google Play / App Store link ]

### If the recipient already has CupWhisper

They receive an in-app notification:

> ☕
> Yulian treated you to a coffee.
> One of the fortune tellers is waiting for you.
> You have a gifted reading.
>
> [ Begin the Ritual ]

### Key Rules

- **The gift does not expire.** It sits in the recipient's account like a
  voucher until they choose to use it.
- **The recipient pays nothing** for the gifted reading. After using it,
  they decide on their own whether they want more.
- Personal messages should support occasion-based variants (Christmas,
  birthday, new job, etc.), e.g.:
  - 🎄 "Merry Christmas! I'm gifting you a mystical coffee."
  - ☕ "Happy Birthday! Treating you to a coffee."
  - "Good luck! Let your cup tell a story."

### Why This Matters

This is a viral mechanism that asks nothing of the sender except a warm
gesture — no ads, no pressure, no discount codes. Recipients aren't limited
to "friends" in the app sense: mother, grandmother, spouse, partner,
colleague. People start gifting each other an emotion, not an AI feature or
a credit. Each new user can organically bring in the next.

### Technical Dependencies (why this waits)

- **Credit transfer** is a variant of the Reading Credits system (AD-001),
  which is intentionally paused (AD-003) until a secure server-side mutation
  path (Cloud Functions or equivalent) exists. Gifting a reading must not
  bypass that protection.
- **Sending email/SMS** requires a new backend capability (e.g. SendGrid for
  email, Twilio or equivalent for SMS), each with a per-message cost to
  budget for.
- **Deep linking** into a specific gifted reading requires a dynamic-link
  solution. Firebase Dynamic Links is being sunset by Google, so this needs
  an alternative (e.g. Branch.io or a custom domain-based link scheme) —
  to be decided when this feature is actually built, not before.

Building this now, before Cloud Functions exist, would mean either violating
AD-003 or writing a temporary insecure version that gets thrown away later.
Revisit once the Reading Credits server-side infrastructure is live.
