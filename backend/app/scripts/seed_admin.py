import asyncio
import sys
from pathlib import Path

# Add backend directory to sys.path
backend_path = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(backend_path))

from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.core.security import hash_password
from app.models.user import RoleEnum, User


async def seed_initial_admin(
    email: str = "admin@pitpulse.org",
    password: str = "logesh@360",
    full_name: str = "System Administrator",
):
    """Seeds initial ADMIN user into PostgreSQL if not present."""
    async with AsyncSessionLocal() as session:
        stmt = select(User).where(User.email == email)
        result = await session.execute(stmt)
        admin = result.scalar_one_or_none()

        if admin:
            print(f"[SEED] Admin account '{email}' already exists in PostgreSQL.")
            return

        admin = User(
            email=email.lower().strip(),
            full_name=full_name.strip(),
            password_hash=hash_password(password),
            role=RoleEnum.ADMIN,
            is_active=True,
            must_change_password=False,
        )
        session.add(admin)
        await session.commit()
        print(f"[SEED] Successfully created initial ADMIN account in PostgreSQL: {email}")


if __name__ == "__main__":
    asyncio.run(seed_initial_admin())
