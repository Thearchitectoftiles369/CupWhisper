import firebase_admin
from firebase_admin import auth as firebase_auth
from fastapi import Header, HTTPException

if not firebase_admin._apps:
    firebase_admin.initialize_app()


def verify_token(authorization: str = Header(...)) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1]
    try:
        decoded = firebase_auth.verify_id_token(token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return decoded["uid"]
