from pydantic import BaseModel


class ThrottleAcquireRequest(BaseModel):
    key: str
    owner: str
    interval: int | None
    concurrency: int | None


class ThrottleAcquireResponse(BaseModel):
    status: str
    token: str
