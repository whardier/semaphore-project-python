from pydantic import BaseModel


class LockAcquireRequest(BaseModel):
    key: str
    owner: str
    timeout: int | None
    concurrency: int | None


class LockAcquireResponse(BaseModel):
    status: str
    token: str


class LockExtendRequest(BaseModel):
    token: str
    timeout: int


class LockExtendResponse(BaseModel):
    status: str
    token: str


class LockReleaseRequest(BaseModel):
    token: str


class LockReleaseResponse(BaseModel):
    status: str
