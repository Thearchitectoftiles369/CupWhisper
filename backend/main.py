from fastapi import FastAPI

app = FastAPI(title="CupWhisper AI Gateway")


@app.get("/health")
def health_check():
    return {"status": "ok"}
