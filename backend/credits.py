from firebase_admin import firestore

_db = None


def get_db():
    global _db
    if _db is None:
        _db = firestore.client()
    return _db


@firestore.transactional
def _consume_credit_txn(transaction, user_ref):
    snapshot = user_ref.get(transaction=transaction)
    data = snapshot.to_dict() or {}
    credits = data.get("readingCredits", 5)

    if credits <= 0:
        raise ValueError("NO_CREDITS")

    transaction.set(user_ref, {"readingCredits": credits - 1}, merge=True)
    return credits - 1


def consume_credit(uid: str) -> int:
    db = get_db()
    user_ref = db.collection("users").document(uid)
    transaction = db.transaction()
    return _consume_credit_txn(transaction, user_ref)


def save_reading(uid: str, storyteller: str, language: str, result_text: str):
    db = get_db()
    db.collection("users").document(uid).collection("readings").add({
        "storyteller": storyteller,
        "language": language,
        "result": result_text,
        "date": firestore.SERVER_TIMESTAMP,
    })
