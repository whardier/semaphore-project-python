from fastapi import APIRouter
from semaphore.services.http.rest.routers.lock import lock_router
from semaphore.services.http.rest.routers.throttle import throttle_router

api_router = APIRouter()

api_router.include_router(lock_router, prefix="/lock")
api_router.include_router(throttle_router, prefix="/throttle")
