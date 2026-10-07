from datetime import datetime, timezone
import logging
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import text

from app.api.v1 import api_v1_router
from app.core.config import settings
from app.core.database import engine, Base

logger = logging.getLogger("pitpulse.api")


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

    # Global Exception Handler so any 500 error outputs clear debugging info
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        import traceback
        tb = traceback.format_exc()
        logger.error(f"[SERVER ERROR] {request.method} {request.url.path}: {exc}\n{tb}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "detail": f"Internal Server Error: {str(exc)}",
                "error_type": type(exc).__name__,
            },
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

    @app.get(
        "/api/v1/system/db-check",
        status_code=status.HTTP_200_OK,
        tags=["System"],
        summary="Database schema and migration diagnostics",
    )
    async def db_check():
        results = {}
        try:
            # Check users columns
            is_sqlite = str(engine.url).startswith("sqlite")
            async with engine.connect() as conn:
                if is_sqlite:
                    cols_res = await conn.execute(text("PRAGMA table_info(users)"))
                    results["users_columns"] = [row[1] for row in cols_res.fetchall()]
                else:
                    cols_res = await conn.execute(text(
                        "SELECT column_name FROM information_schema.columns WHERE table_name = 'users'"
                    ))
                    results["users_columns"] = [row[0] for row in cols_res.fetchall()]

                # Count users
                u_count = await conn.execute(text("SELECT count(*) FROM users"))
                results["user_count"] = u_count.scalar()

            results["status"] = "connected"
        except Exception as e:
            results["error"] = str(e)
            results["status"] = "failed"
        return results

    @app.on_event("startup")
    async def on_startup():
        logger.info("[STARTUP] Running automatic schema migration...")

        # 1. Isolated ALTER TABLE statements to guarantee users columns exist
        is_sqlite = str(engine.url).startswith("sqlite")
        alter_statements = [
            "ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT 1" if is_sqlite else "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT TRUE",
            "ALTER TABLE users ADD COLUMN age INTEGER" if is_sqlite else "ALTER TABLE users ADD COLUMN IF NOT EXISTS age INTEGER",
            "ALTER TABLE users ADD COLUMN gender VARCHAR(50)" if is_sqlite else "ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(50)",
            "ALTER TABLE users ADD COLUMN is_profile_completed BOOLEAN DEFAULT 1" if is_sqlite else "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_profile_completed BOOLEAN DEFAULT TRUE",
            "UPDATE users SET is_verified = 1 WHERE is_verified IS NULL" if is_sqlite else "UPDATE users SET is_verified = TRUE WHERE is_verified IS NULL",
            "UPDATE users SET is_profile_completed = 1 WHERE is_profile_completed IS NULL" if is_sqlite else "UPDATE users SET is_profile_completed = TRUE WHERE is_profile_completed IS NULL",
        ]

        for stmt in alter_statements:
            try:
                async with engine.begin() as conn:
                    await conn.execute(text(stmt))
                logger.info(f"[MIGRATION OK] {stmt}")
            except Exception as ex:
                logger.info(f"[MIGRATION NOTICE] {stmt}: {ex}")

        # 2. Create any other missing tables in Base.metadata
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            logger.info("[STARTUP] Base.metadata.create_all completed.")
        except Exception as ex:
            logger.warning(f"[STARTUP NOTICE] create_all notice: {ex}")

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
