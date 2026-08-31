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


---

## AD-004 — 🔒 Locked — AI Requests Only Through a Secured Backend

All AI requests (Gemini or any future model) are executed exclusively
through a backend service. The Flutter mobile app never communicates
directly with Gemini (or any AI provider) and never embeds an AI API key.

**Chosen backend: a self-hosted FastAPI service**, not Firebase Cloud
Functions, for this phase — chosen because the developer already has
working FastAPI experience from other projects, avoiding a dependency on
Cloud Functions' Blaze-plan and deployment requirements before they're
otherwise needed.

**Target architecture:**

```
Flutter -> FastAPI -> Gemini -> FastAPI -> Flutter
```

FastAPI is responsible for: holding the Gemini API key server-side, image
validation, rate limiting, logging, prompt construction per storyteller
personality (see product-vision.md), and writing results to Firestore.

**Why this matters beyond Gemini:** this decision is model-agnostic. If
CupWhisper later switches to OpenAI, Claude, or another provider, only the
backend changes — the mobile app's contract with the backend stays the
same.

**Future expansion path (not required to build now):**

```
Flutter -> FastAPI
1. Photo validity check
2. Cup detection
3. Interior visibility detection
4. Symbol detection
5. Prompt Builder
6. Gemini
7. Write to Firestore
8. Return result
```

## AD-005: Reading Credits via Cloud Run + Firebase Admin SDK (not separate Cloud Functions)

**Decision**: Reading Credits are enforced server-side using the existing
FastAPI backend on Cloud Run, via the Firebase Admin SDK - not a separate
Cloud Functions deployment as originally scoped in AD-001/AD-003.

**Rationale**: We already have a working, secure, server-side FastAPI
service. Firebase officially supports the Admin SDK from any trusted
server environment (including Cloud Run), with privileged Firestore
access controlled through Google IAM rather than Firestore Security
Rules. Building a second server-side layer (Cloud Functions) purely for
credit management would duplicate infrastructure without benefit.

**Architecture**:
1. Flutter obtains a Firebase Auth ID token (`user.getIdToken()`) and
   sends it as `Authorization: Bearer <token>` with each `/reading`
   request.
2. Backend verifies the token via `firebase_admin.auth.verify_id_token()`,
   extracting the trusted `uid` - the client-supplied `uid` is never
   trusted directly.
3. Backend checks and decrements `readingCredits` inside a single
   Firestore transaction (`@firestore.transactional`), preventing race
   conditions from rapid double-submission. A missing `readingCredits`
   field is treated as a new user's first free credit (1), initialized
   and consumed atomically in that same transaction - no separate
   "new user" grant step needed.
4. Only after a credit is successfully consumed does the backend call
   Gemini to generate the reading.
5. The backend also now saves reading history server-side (moved from
   client-side Firestore writes), for the same trust reasons.

**Firestore Security Rules**: Client SDK writes to `readingCredits` are
explicitly forbidden (checked via `diff().affectedKeys()`), and writes to
the `readings` subcollection are fully disabled for the client - both are
now exclusively backend/Admin-SDK operations, which bypass Security Rules
entirely via IAM.

**Deferred**: Firebase App Check (verifying requests come from the
genuine app binary, not just a valid user) was considered as an
additional security layer but explicitly not treated as a blocker for
v1 of the credit system. Auth + server-side credits + Firestore
transaction is the required baseline; App Check can be added later.

**Rollout note**: This code was written and merged to `main` while
CupWhisper was in Google Play Closed Testing, but deliberately NOT
deployed to production Cloud Run/Play Store until after standard
(production) Play Store access was granted - to avoid breaking the app
for active testers or disrupting Google's review of the pending
production access application. Deploy both the backend and a new Flutter
build together in one coordinated release once it's safe to do so.
