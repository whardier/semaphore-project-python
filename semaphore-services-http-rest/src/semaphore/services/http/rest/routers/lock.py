from fastapi import APIRouter
from semaphore.services.http.rest.models.api.lock import (
    LockAcquireRequest,
    LockAcquireResponse,
    LockExtendRequest,
    LockExtendResponse,
    LockReleaseRequest,
    LockReleaseResponse,
)

lock_router = APIRouter()


@lock_router.post("/acquire")
async def acquire_lock(request: LockAcquireRequest) -> LockAcquireResponse:
    return LockAcquireResponse(status="ok", token="token")  # noqa: S106


@lock_router.post("/extend")
async def extend_lock(request: LockExtendRequest) -> LockExtendResponse:
    return LockExtendResponse(status="ok", token="token")  # noqa: S106


@lock_router.post("/release")
async def release_lock(request: LockReleaseRequest) -> LockReleaseResponse:
    return LockReleaseResponse(status="ok")
