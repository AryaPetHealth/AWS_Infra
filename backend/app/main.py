from fastapi import FastAPI

from app.api.v1 import documents

app = FastAPI(title="Arya API")

app.include_router(documents.router, prefix="/api/v1")


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
