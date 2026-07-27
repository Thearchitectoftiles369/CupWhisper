# CupWhisper — Architecture Decisions Log

Status tags: 🟢 Draft, 🟡 Approved, 🔒 Locked — locked decisions are not
revisited without a strong technical reason.

---

## AD-001 — 🔒 Locked — Reading Credits System

Firestore field `users/{uid}/readingCredits` (integer).

- New user: 1 free credit.
- Successful reading: `credits -= 1` (server-side check only).
- Successful Google Play Billing purchase: `credits += 1`.
- The Flutter client can only **READ** `readingCredits`. It can never write
  to this field directly. All mutations must go through Firebase Cloud
  Functions.

Chosen over separate `freeReadingUsed`/`readingsRemaining` flags for
flexibility (future promos/referrals) and reduced state-sync bugs.

---

## AD-002 — 🔒 Locked — State Management

`flutter_riverpod` (^3.3.2) is the app's state management solution.

Chosen for clean handling of async Firebase/Firestore streams, HTTP calls
to the AI backend, and future caching/settings needs.

---

## AD-003 — 🔒 Locked — No Temporary Client-Side Credits

Reading Credits (AD-001) will **not** be implemented with a temporary,
insecure client-side mechanism while Cloud Functions are unavailable in the
current Termux-only development environment.

**Reasoning:**

- AD-001 already establishes that credit mutations must be server-side only.
  A client-side stand-in (e.g. a Firestore field the app increments/decrements
  directly) would violate that decision and create a real security hole —
  users could trivially grant themselves free readings.
- Writing temporary logic now means writing it twice: once as a throwaway
  version, and again "for real" once Cloud Functions exist. That's wasted
  work and a guaranteed round of regression testing.
- Deploying Cloud Functions does not require developing them inside Termux.
  Options when the time comes: a one-off deploy from a regular computer,
  a GitHub Actions CI/CD pipeline, or even swapping Cloud Functions for a
  different backend (Cloud Run, custom API) if the architecture calls for
  it later. This is an infrastructure choice to make when Reading Credits
  is actually being built, not before.

**Consequence:** Step 13.5 (Reading Credits) is paused. Development
continues with the AI Service Layer, real AI integration, and UI polishing.
Reading Credits will be picked back up once a server-side mutation path
(Cloud Functions or equivalent) is in place.
