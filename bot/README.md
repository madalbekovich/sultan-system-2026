# Sultan System — Telegram Bot

`aiogram 3.x` client ordering bot per `tech.txt` Component A. Talks to the FastAPI
backend over HTTP — no direct DB access.

## Flow

1. `/start` — registers/updates the client (by Telegram user id) via `POST /clients/register`,
   shows product categories.
2. Tap a category → products are listed with price/unit.
3. Tap a product → type a quantity → item is added to an in-memory cart (FSM state, per-chat).
4. Add more items or **Confirm order** → `POST /orders/` creates the order for delivery
   tomorrow, which instantly shows up in `GET /orders/summary` for the workshop app
   (Redis cache is invalidated on order creation, so the sync is immediate).

## Run locally

```bash
cd bot
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # set TELEGRAM_BOT_TOKEN, adjust API_BASE_URL if needed

python -m bot.main
```

Requires the backend (`../backend`) running and reachable at `API_BASE_URL`.

## Notes / next steps

- Cart and FSM state are in-memory (`MemoryStorage`) — fine for local dev; swap to
  `RedisStorage` (aiogram already ships one) before running more than one bot worker
  or wanting state to survive restarts.
- Delivery date is hardcoded to "tomorrow" — add a date-picker step if same-day or
  multi-day ordering is needed.
- No client-facing order-status notifications yet (e.g. "your order is READY") —
  would need the backend to push updates (webhook/queue) back to the bot.
