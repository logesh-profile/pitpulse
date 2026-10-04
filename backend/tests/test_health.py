import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_health_check_endpoint():
    """Verify that GET /health returns 200 OK and valid JSON metadata."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        response = await client.get("/health")

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "pitpulse-api"
    assert data["version"] == "0.1.0"
    assert "timestamp" in data
    assert "environment" in data


@pytest.mark.asyncio
async def test_root_endpoint():
    """Verify that GET / returns 200 OK and service status."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        response = await client.get("/")

    assert response.status_code == 200
    data = response.json()
    assert data["app"] == "pitpulse-api"
    assert data["status"] == "online"
