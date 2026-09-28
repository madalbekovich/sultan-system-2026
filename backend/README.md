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

# run the API
uvicorn app.main:app --reload
```

API docs: http://localhost:8000/docs

## Implemented endpoints

- `POST /api/v1/auth/` — issues a JWT (placeholder credentials `admin`/`admin` until a real staff table exists)
- `GET /api/v1/products/` — list active products
- `POST /api/v1/products/` / `PATCH /api/v1/products/{id}` — manage catalog (auth required)
- `POST /api/v1/orders/` — create an order (used by the Telegram bot)
- `GET /api/v1/orders/summary?delivery_date=YYYY-MM-DD` — aggregated planned weight per product, Redis-cached for 15s, invalidated on order create / weight update
- `PATCH /api/v1/orders/items/{id}/weight` — set actual weighed qty (auth required)
- `GET /api/v1/orders/{id}/waybill-pdf` — renders the waybill as PDF (auth required)

## Next steps (not yet built)

- Telegram bot (`aiogram 3.x`) in `../bot`, calling these APIs for catalog browsing / order placement.
- Flutter mobile app (worker + manager modes).
- Replace the placeholder auth credentials with a real staff/role table (worker vs manager).
