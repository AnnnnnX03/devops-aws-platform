# app/backend/ai_service.py
# ─────────────────────────────────────────────────────────────
# AI Service — Python LLM API
# This is your competitive advantage: DevOps + AI skills combined
# ─────────────────────────────────────────────────────────────

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="AI Service", version="1.0.0")

class ChatRequest(BaseModel):
    message: str
    system_prompt: str = "You are a helpful assistant."

class ChatResponse(BaseModel):
    response: str
    model: str
    tokens_used: int

# ── HEALTH CHECK ──────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "healthy", "service": "ai-service"}

# ── CHAT ENDPOINT ─────────────────────────────────────────────
@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Calls an LLM API and returns the response.
    In production: use AWS Bedrock (no API key needed, IAM auth)
    For dev: uses OpenAI or any compatible API
    """
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        # Return mock response for local dev without API key
        logger.warning("No API key found, returning mock response")
        return ChatResponse(
            response=f"[MOCK] You said: {request.message}. Set OPENAI_API_KEY to get real responses.",
            model="mock",
            tokens_used=0
        )

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={"Authorization": f"Bearer {api_key}"},
                json={
                    "model": "gpt-3.5-turbo",
                    "messages": [
                        {"role": "system", "content": request.system_prompt},
                        {"role": "user", "content": request.message}
                    ],
                    "max_tokens": 500
                },
                timeout=30.0
            )
            response.raise_for_status()
            data = response.json()

            return ChatResponse(
                response=data["choices"][0]["message"]["content"],
                model=data["model"],
                tokens_used=data["usage"]["total_tokens"]
            )
        except httpx.HTTPError as e:
            logger.error(f"AI API call failed: {e}")
            raise HTTPException(status_code=502, detail="AI service temporarily unavailable")

# ── SUMMARISE ENDPOINT ────────────────────────────────────────
@app.post("/summarise")
async def summarise(text: str):
    """Summarise a block of text using LLM"""
    request = ChatRequest(
        message=f"Please summarise the following text in 3 bullet points:\n\n{text}",
        system_prompt="You are a precise summarisation assistant. Always respond with exactly 3 bullet points."
    )
    return await chat(request)
