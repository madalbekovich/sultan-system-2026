# Sultan System — Mobile App (Flutter)

Worker (factory floor) and Manager (owner) modes per `tech.txt` Components B & C.
State management: GetX. Talks to the FastAPI backend (`../backend`) over HTTP,
with an offline-first cache (SharedPreferences) so the summary/catalog/orders
screens render instantly from the last-synced data while a fresh fetch runs.

**This directory was hand-written without a local Flutter SDK to run
`flutter create`/`pub get`/`analyze` against — there was none available in the
environment that built it.** It has since had a manual line-by-line review
(not a substitute for `flutter analyze`, but it did catch two real bugs — see
below), and every file's braces/parens balance. Still, run the steps below
and fix whatever `flutter analyze`/`pub get` surface.

Bugs found and fixed in review:
- `ApiClient`'s error interceptor wrapped `ApiException` inside a new
  `DioException`, so every `on ApiException catch (e)` at call sites (login,
  waybill fetch) silently never matched — errors fell through to the generic
  handler instead of showing the server's actual message. Fixed by having
  each `ApiClient` method catch `DioException` and rethrow `ApiException`
  directly.
- Screens like `ProductionSummaryScreen` called `Get.put(...)` directly
  inside `build()`. `Get.put` always overwrites the previous registration
  under that tag without disposing it, so navigating back to a screen and
  returning re-created its controller — and for
  `ProductionSummaryController`, which runs a `Timer.periodic` polling the
  summary endpoint, silently leaked one uncancelled timer per revisit.
  Fixed with a `putOnce()` helper (`lib/core/get_utils.dart`) that reuses an
  already-registered controller instead of replacing it.

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
