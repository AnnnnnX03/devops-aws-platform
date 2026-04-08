# app/backend/tests/test_main.py
# ─────────────────────────────────────────────────────────────
# Unit Tests for FastAPI backend
# Run locally: pytest tests/ -v
# ─────────────────────────────────────────────────────────────

import pytest
from fastapi.testclient import TestClient
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app

client = TestClient(app)


class TestHealthCheck:
    """Test the health check endpoint — ALB depends on this"""

    def test_health_returns_200(self):
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_returns_healthy_status(self):
        response = client.get("/health")
        data = response.json()
        assert data["status"] == "healthy"

    def test_health_contains_timestamp(self):
        response = client.get("/health")
        data = response.json()
        assert "timestamp" in data


class TestRootEndpoint:

    def test_root_returns_200(self):
        response = client.get("/")
        assert response.status_code == 200

    def test_root_returns_message(self):
        response = client.get("/")
        data = response.json()
        assert "message" in data


class TestItemsCRUD:
    """Test CRUD operations"""

    def test_get_items_empty(self):
        response = client.get("/items")
        assert response.status_code == 200
        assert "items" in response.json()

    def test_create_item(self):
        response = client.post("/items", json={
            "name": "Test Item",
            "description": "A test item"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Test Item"
        assert "id" in data

    def test_get_item_by_id(self):
        # Create first
        create_response = client.post("/items", json={
            "name": "My Item",
            "description": "Description"
        })
        item_id = create_response.json()["id"]

        # Then get
        response = client.get(f"/items/{item_id}")
        assert response.status_code == 200
        assert response.json()["name"] == "My Item"

    def test_get_nonexistent_item_returns_404(self):
        response = client.get("/items/999")
        assert response.status_code == 404


class TestMetrics:

    def test_metrics_endpoint(self):
        response = client.get("/metrics")
        assert response.status_code == 200
        data = response.json()
        assert "request_count" in data
        assert "error_count" in data
