"""Runs against the real dev database (the one docker-compose brings up),
not an isolated test DB — there's no separate test-infra in this project
yet. Every fixture that creates rows cleans them up itself, scoped to
names/ids it created, so this is safe to run against a DB that already
has real catalog/client data (as the dev/staging one does).
"""
import asyncio

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from app.core.security import create_access_token
from app.db.session import async_session_maker
from app.main import app


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test/api/v1") as c:
        yield c


@pytest.fixture
def auth_headers():
    token = create_access_token(subject="admin")
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def bot_headers():
    from app.core.config import settings

    return {"X-Bot-Key": settings.BOT_API_KEY}


@pytest_asyncio.fixture
async def db():
    async with async_session_maker() as session:
        yield session
