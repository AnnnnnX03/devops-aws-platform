# app/backend/main.py
# ─────────────────────────────────────────────────────────────
# FastAPI Backend — REST API with health check and AI endpoint
# ─────────────────────────────────────────────────────────────

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import time
import logging

# Configure logging — feeds into CloudWatch
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="DevOps Platform API",
    description="3-tier AWS app with AI capabilities",
    version="1.0.0"
)

# CORS — allows frontend to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── HEALTH CHECK ENDPOINT ─────────────────────────────────────
# ALB calls this every 30 seconds to check if container is healthy
# If this returns anything other than 200, ALB stops sending traffic here
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "environment": os.getenv("ENVIRONMENT", "local"),
        "timestamp": time.time()
    }

# ── ROOT ENDPOINT ─────────────────────────────────────────────
@app.get("/")
async def root():
    return {"message": "DevOps Platform API is running 🚀"}

# ── ITEMS ENDPOINTS (CRUD example) ───────────────────────────
items_db = {}  # In-memory store for demo (real app uses RDS)

class Item(BaseModel):
    name: str
    description: str

@app.get("/items")
async def get_items():
    logger.info("GET /items called")
    return {"items": list(items_db.values())}

@app.post("/items")
async def create_item(item: Item):
    item_id = str(len(items_db) + 1)
    items_db[item_id] = {"id": item_id, **item.dict()}
    logger.info(f"Created item {item_id}")
    return items_db[item_id]

@app.get("/items/{item_id}")
async def get_item(item_id: str):
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")
    return items_db[item_id]

# ── METRICS ENDPOINT (4 Golden Signals) ──────────────────────
# Latency, Traffic, Errors, Saturation
request_count = 0
error_count = 0

@app.get("/metrics")
async def get_metrics():
    return {
        "request_count": request_count,
        "error_count": error_count,
        "environment": os.getenv("ENVIRONMENT", "local"),
    }
