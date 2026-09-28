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
    credits = data.get("readingCredits", 0)
    if credits <= 0:
        raise ValueError("NO_CREDITS")
    transaction.set(user_ref, {"readingCredits": credits - 1}, merge=True)
    return credits - 1


def consume_credit(uid: str) -> int:
    db = get_db()
    user_ref = db.collection("users").document(uid)
    transaction = db.transaction()
    return _consume_credit_txn(transaction, user_ref)


@firestore.transactional
def _claim_free_reading_txn(transaction, user_ref):
    snapshot = user_ref.get(transaction=transaction)
    data = snapshot.to_dict() or {}
    if data.get("hasUsedFreeReading", False):
        raise ValueError("FREE_READING_USED")
    transaction.set(user_ref, {"hasUsedFreeReading": True}, merge=True)
    return True


def claim_free_reading(uid: str) -> bool:
    db = get_db()
    user_ref = db.collection("users").document(uid)
    transaction = db.transaction()
    return _claim_free_reading_txn(transaction, user_ref)


def get_reading_credits(uid: str) -> int:
    db = get_db()
    snapshot = db.collection("users").document(uid).get()
    data = snapshot.to_dict() or {}
    return data.get("readingCredits", 0)


@firestore.transactional
def _credit_purchase_txn(transaction, purchase_ref, user_ref):
    purchase_snapshot = purchase_ref.get(transaction=transaction)
    if purchase_snapshot.exists:
        raise ValueError("ALREADY_PROCESSED")
    user_snapshot = user_ref.get(transaction=transaction)
    data = user_snapshot.to_dict() or {}
    current = data.get("readingCredits", 0)
    new_balance = current + 1
    transaction.set(user_ref, {"readingCredits": new_balance}, merge=True)
    transaction.set(purchase_ref, {
        "uid": user_ref.id,
        "creditedAt": firestore.SERVER_TIMESTAMP,
    })
    return new_balance


def credit_purchase(uid: str, purchase_token: str) -> int:
    db = get_db()
    user_ref = db.collection("users").document(uid)
    purchase_ref = db.collection("processedPurchases").document(purchase_token)
    transaction = db.transaction()
    return _credit_purchase_txn(transaction, purchase_ref, user_ref)


def save_reading(uid: str, storyteller: str, language: str, result_text: str):
    db = get_db()
    db.collection("users").document(uid).collection("readings").add({
        "storyteller": storyteller,
        "language": language,
        "result": result_text,
        "date": firestore.SERVER_TIMESTAMP,
    })
