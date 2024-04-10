from fastapi import APIRouter
from semaphore.services.http.rest.models.api.throttle import ThrottleAcquireRequest, ThrottleAcquireResponse

throttle_router = APIRouter()


@throttle_router.post("/acquire")
async def acquire_throttle(request: ThrottleAcquireRequest) -> ThrottleAcquireResponse:
    return ThrottleAcquireResponse(status="ok", token="token")  # noqa: S106
