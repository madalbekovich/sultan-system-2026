from fastapi import APIRouter

from app.api.v1 import auth, categories, clients, orders, products

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth.router)
api_router.include_router(categories.router)
api_router.include_router(clients.router)
api_router.include_router(products.router)
api_router.include_router(orders.router)
# regions.router intentionally not mounted any more — region-based pricing
# is retired in favor of per-client prices; the table/model stay for
# history (already-placed orders still reference it).
