# CupWhisper — Google Play Content Rating & Data Safety Reference

Reference answers for the Play Console Content Rating questionnaire and
Data Safety section, prepared in advance of submission.

## Content Rating (IARC Questionnaire)

CupWhisper is an entertainment app with no sensitive content. Expected
answers:

- Violence: No
- Sexual content: No
- Profanity/crude language: No
- Drugs/alcohol/tobacco references: No
- Gambling: No
- Horror/fear content: No (the reading experience is warm and pleasant,
  not dark or scary)
- User-generated content shared publicly: No (photos stay private to the
  user, never shown to other users)
- Location sharing: No
- In-app purchases: **Yes** (planned for the future - "treat a friend
  with coffee" / reading credits - not yet active at initial launch)

Expected result: lowest age category (Everyone / PEGI 3), no special
content warnings.

## Data Safety Section

**Data collected:**

| Data type | Collected | Purpose | Shared with third parties |
|---|---|---|---|
| Photos (camera) | Yes | App functionality (AI analysis) | Processed by Google Gemini API (not sold, not used for advertising) |
| Anonymous device/account ID | Yes | App functionality, account management | No |
| App activity (reading history) | Yes | App functionality | No |
| Analytics data | Yes (Firebase Analytics) | App improvement | No (aggregated data processed by Google as service provider) |

**Data NOT collected:**

- User's name, email, phone number
- Location
- Financial information
- Health information
- Contacts

**Note on wording:** Google Play treats data processed by Google's own
infrastructure (Firebase, Gemini API, Cloud Run) differently from
third-party advertising data sharing, but the exact phrasing of Play
Console's questions can shift over time - read each question carefully
at submission time and answer honestly based on the table above.

See also: [privacy-policy.md](privacy-policy.md) for the full public
privacy policy this reference is based on.
