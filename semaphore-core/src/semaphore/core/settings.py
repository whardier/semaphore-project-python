from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class CoreSettings(BaseSettings):
    backend: str = Field(default=None)

    model_config = SettingsConfigDict(
        env_prefix="SEMAPHORE_CORE_",
    )


core_backend_settings = CoreSettings()
