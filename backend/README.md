# Sultan System — Backend

FastAPI + SQLModel (async) + PostgreSQL + Redis, per `tech.txt`.

## Run locally

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # adjust DATABASE_URL / REDIS_URL if needed

# start Postgres + Redis
docker compose up -d

# apply migrations
alembic upgrade head

# run the API (use --host 0.0.0.0 if a phone/tablet on the LAN needs to reach it)
uvicorn app.main:app --reload
# or: uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Note: `docker-compose.yml` maps Postgres to host port **5433**, not 5432 — this
avoids clashing with a locally-installed (non-Docker) Postgres, which is a real
conflict encountered running this on a dev machine that already had one. If
you get `role "..." does not exist` from Postgres, check `lsof -nP -iTCP:5432
-sTCP:LISTEN` for a stray local Postgres before assuming the container is
broken.

API docs: http://localhost:8000/docs

### Seed data

`python seed.py` (with the venv active and the DB migrated) inserts a few
categories/products/clients so the mobile app / bot have something to show.
It's a plain script using the app's models directly — not an API client —
since there's currently no `POST /categories/` endpoint (see gaps below).

## Implemented endpoints

- `POST /api/v1/auth/` — issues a JWT (placeholder credentials `admin`/`admin` until a real staff table exists)
- `GET /api/v1/categories/` — list categories (no create/edit endpoint yet — see gaps)
- `GET /api/v1/clients/` — list clients (auth required)
- `POST /api/v1/clients/register` — get-or-create a client by Telegram id
- `GET /api/v1/clients/by-tg/{tg_user_id}`
- `GET /api/v1/products/` — list products (`active_only`, `category_id` filters)
- `POST /api/v1/products/` / `PATCH /api/v1/products/{id}` — manage catalog (auth required)
- `GET /api/v1/orders/` — list orders (`delivery_date`, `status` filters)
- `GET /api/v1/orders/{id}` — order detail
- `POST /api/v1/orders/` — create an order (used by the Telegram bot / mobile app)
- `GET /api/v1/orders/summary?delivery_date=YYYY-MM-DD` — aggregated planned weight per product, Redis-cached for 15s, invalidated on order create / weight update
- `PATCH /api/v1/orders/items/{id}/weight` — set actual weighed qty (auth required)
- `PATCH /api/v1/orders/{id}/status` — update order status, e.g. mark READY (auth required)
- `GET /api/v1/orders/{id}/waybill-pdf` — renders the waybill as PDF (auth required)

## Known gaps

- No `POST /categories/` (or PATCH) — categories can only be listed, not
  managed, even though the manager app is supposed to handle "add/edit
  categories" per the spec.
- Replace the placeholder auth credentials with a real staff/role table
  (worker vs manager), needed before this goes anywhere near production.
