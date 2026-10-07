from datetime import datetime, timezone
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.api.v1 import api_v1_router
from app.core.config import settings


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    environment: str
    timestamp: str


def create_application() -> FastAPI:
    app = FastAPI(
        title="PitPulse Healthcare API",
        description="Authoritative Backend API for PitPulse Healthcare Mobile Application",
        version=settings.APP_VERSION,
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
    )

    # CORS configuration
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS if isinstance(settings.CORS_ORIGINS, list) else [settings.CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Include API v1 Routers
    app.include_router(api_v1_router)

    @app.get(
        "/health",
        response_model=HealthResponse,
        status_code=status.HTTP_200_OK,
        tags=["System"],
        summary="Service Health Check",
    )
    async def health_check() -> HealthResponse:
        return HealthResponse(
            status="ok",
            service=settings.APP_NAME,
            version=settings.APP_VERSION,
            environment=settings.ENVIRONMENT,
            timestamp=datetime.now(timezone.utc).isoformat(),
        )

    @app.get(
        "/",
        status_code=status.HTTP_200_OK,
        tags=["System"],
        summary="Root API Info",
    )
    async def root():
        return {
            "app": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "status": "online",
            "docs": "/docs" if settings.DEBUG else "disabled",
        }

    @app.on_event("startup")
    async def on_startup():
        import logging
        from sqlalchemy import text
        from app.core.database import engine
        from app.models import Base

        logger = logging.getLogger("pitpulse.startup")
        logger.info("[STARTUP] Running automatic schema migration and table verification...")

        try:
            async with engine.begin() as conn:
                # 1. Create all missing tables in PostgreSQL/SQLite
                await conn.run_sync(Base.metadata.create_all)

                # 2. Add missing columns to 'users' table if they don't exist
                is_sqlite = str(engine.url).startswith("sqlite")
                if is_sqlite:
                    for col_stmt in [
                        "ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT 1",
                        "ALTER TABLE users ADD COLUMN age INTEGER",
                        "ALTER TABLE users ADD COLUMN gender VARCHAR(50)",
                        "ALTER TABLE users ADD COLUMN is_profile_completed BOOLEAN DEFAULT 1",
                    ]:
                        try:
                            await conn.execute(text(col_stmt))
                        except Exception:
                            pass
                else:
                    for col_stmt in [
                        "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT TRUE",
                        "ALTER TABLE users ADD COLUMN IF NOT EXISTS age INTEGER",
                        "ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(50)",
                        "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_profile_completed BOOLEAN DEFAULT TRUE",
                        "UPDATE users SET is_verified = TRUE WHERE is_verified IS NULL",
                        "UPDATE users SET is_profile_completed = TRUE WHERE is_profile_completed IS NULL",
                    ]:
                        try:
                            await conn.execute(text(col_stmt))
                        except Exception as ex:
                            logger.warning(f"[MIGRATION NOTICE] {col_stmt}: {ex}")

            logger.info("[STARTUP] Database tables and schema verified successfully.")
        except Exception as e:
            logger.error(f"[STARTUP ERROR] Database schema migration error: {e}")

        # 3. Seed or verify master administrator (admin123@gmail.com)
        try:
            from app.scripts.seed_admin import seed_initial_admin
            await seed_initial_admin()
        except Exception as e:
            logger.error(f"[STARTUP ERROR] Admin seeding error: {e}")

    return app


app = create_application()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
