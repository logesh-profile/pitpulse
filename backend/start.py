import os
import sys
import time
import subprocess
from sqlalchemy import create_engine


def get_sync_url() -> str:
    url = os.getenv("SYNC_DATABASE_URL") or os.getenv("DATABASE_URL") or ""
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+psycopg2://", 1)
    elif url.startswith("postgresql://") and not url.startswith("postgresql+psycopg2://"):
        url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
    elif url.startswith("postgresql+asyncpg://"):
        url = url.replace("postgresql+asyncpg://", "postgresql+psycopg2://", 1)
    return url


def wait_for_db(url: str) -> None:
    if not url or "127.0.0.1" in url or "localhost" in url:
        print("[Startup] Local or development database URL detected; proceeding.")
        return

    print(f"[Startup] Connecting to database: {url.split('@')[-1] if '@' in url else 'configured'}")
    for i in range(1, 16):
        try:
            engine = create_engine(url, connect_args={"connect_timeout": 5})
            with engine.connect() as conn:
                print("[Startup] Database connection verified!")
                return
        except Exception as e:
            print(f"[Startup] Waiting for database (attempt {i}/15): {e}")
            time.sleep(2)
    print("[Startup] Warning: Database connection check timed out. Attempting migrations anyway...")


def run_migrations() -> None:
    print("[Startup] Running Alembic migrations...")
    try:
        res = subprocess.run(["alembic", "upgrade", "head"], capture_output=True, text=True)
        if res.returncode == 0:
            print("[Startup] Alembic migrations completed successfully.")
            if res.stdout:
                print(res.stdout)
        else:
            print(f"[Startup] Alembic note (code {res.returncode}):\n{res.stderr}\n{res.stdout}")
    except Exception as e:
        print(f"[Startup] Alembic invocation note: {e}")


def start_server() -> None:
    port = int(os.getenv("PORT", "8000"))
    print(f"[Startup] Starting Uvicorn server on 0.0.0.0:{port}...")
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, log_level="info")


if __name__ == "__main__":
    sync_url = get_sync_url()
    wait_for_db(sync_url)
    run_migrations()
    start_server()
