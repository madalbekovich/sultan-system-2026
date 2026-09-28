# Sultan System — Mobile App (Flutter)

Worker (factory floor) and Manager (owner) modes per `tech.txt` Components B & C.
State management: GetX. Talks to the FastAPI backend (`../backend`) over HTTP,
with an offline-first cache (SharedPreferences) so the summary/catalog/orders
screens render instantly from the last-synced data while a fresh fetch runs.

**This directory was hand-written without a local Flutter SDK to run
`flutter create`/`pub get`/`analyze` against — there was none available in the
environment that built it.** The `lib/` code follows standard Flutter/GetX
patterns and every file's braces/parens balance, but it has **not** been
compiled. Treat it as a strong first draft: run the steps below and fix
whatever `flutter analyze`/`pub get` surface (expect minor things like a
stale package API or a missed import).

## First-time setup

```bash
cd mobile

# Generate the missing platform folders (android/ios/web/...) — this merges
# into the existing pubspec.yaml/lib without touching them:
flutter create --org com.sultansystem --project-name sultan_system .

flutter pub get
flutter analyze   # fix whatever it flags
```

## Run

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

On a physical device/tablet, replace `localhost` with your machine's LAN IP
so the workshop tablet can actually reach the backend.

Login uses the backend's placeholder credentials (`admin` / `admin`) until a
real staff/role table exists — see `../backend/README.md`.

## Structure

```
lib/
  core/          API client (Dio + auth interceptor), config, local storage/cache
  models/        Category, Product, Client, Order, OrderItem, OrdersSummary
  data/          Repositories (one per resource), offline cache read/write
  screens/
    mode_select/       Worker vs Manager entry point
    auth/               Shared login screen
    worker/summary/     Live "Total Weight Needed" screen (polls every 10s)
    worker/assembly/    Order list -> per-order weighing screen
    manager/dashboard/  Daily sales/weight overview
    manager/catalog/    Product list + add-product sheet
    manager/clients/    Client directory
    manager/waybill/    Fetch + print/share waybill PDF by order #
```

## Known gaps / next steps

- Weight/status updates that fail while offline show an error but aren't
  queued for retry yet — add a local outbox + retry-on-reconnect for true
  offline resilience on the factory floor.
- No product-edit or client-create screens yet (catalog only supports
  add + toggle-active; clients are directory/read-only — they're created via
  the Telegram bot's `/start`).
- Waybill screen takes a manual order number; wiring it as a button from the
  order list/detail screens would be more convenient for the manager.
- No role separation yet (worker vs manager use the same login) — depends on
  the same staff/role table gap noted in the backend README.
