from fastapi import APIRouter

healthcheck_router = APIRouter()


@healthcheck_router.get("/simple")
async def healthcheck():
    return {"status": "ok"}
