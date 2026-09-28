from fastapi import FastAPI
from fastapi.middleware.gzip import GZipMiddleware

from app.api.v1.router import api_router

app = FastAPI(title="Sultan System API", version="0.1.0")
app.add_middleware(GZipMiddleware, minimum_size=512)
app.include_router(api_router)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}
