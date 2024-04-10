from fastapi import FastAPI
from semaphore.services.http.rest.constants import SERVICE_TITLE, SERVICE_VERSION
from semaphore.services.http.rest.routers.api import api_router
from semaphore.services.http.rest.routers.healthcheck import healthcheck_router

app = FastAPI(
    title=SERVICE_TITLE,
    version=SERVICE_VERSION,
    openapi_tags=[
        {
            "name": "healthcheck",
            "description": "Service healthcheck endpoints",
        },
        {
            "name": "api",
            "description": "Service API endpoints",
        },
    ],
)

app.include_router(healthcheck_router, prefix="/healthcheck", tags=["healthcheck"])
app.include_router(api_router, prefix="/api", tags=["api"])
