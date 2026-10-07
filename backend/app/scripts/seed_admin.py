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
    email: str = "admin123@gmail.com",
    password: str = "admin123",
    full_name: str = "System Administrator",
):
    """Seeds or updates initial ADMIN user in PostgreSQL."""
    async with AsyncSessionLocal() as session:
        stmt = select(User).where(User.email == email.lower().strip())
        result = await session.execute(stmt)
        admin = result.scalar_one_or_none()

        if admin:
            admin.password_hash = hash_password(password)
            admin.is_active = True
            admin.is_verified = True
            admin.is_profile_completed = True
            admin.role = RoleEnum.ADMIN
            await session.commit()
            print(f"[SEED] Admin account '{email}' confirmed and active in PostgreSQL.")
        else:
            admin = User(
                email=email.lower().strip(),
                full_name=full_name.strip(),
                password_hash=hash_password(password),
                role=RoleEnum.ADMIN,
                is_active=True,
                is_verified=True,
                is_profile_completed=True,
                must_change_password=False,
            )
            session.add(admin)
            await session.commit()
            print(f"[SEED] Successfully created initial ADMIN account in PostgreSQL: {email}")

        # Also update any legacy admin accounts so they have valid flags
        stmt_legacy = select(User).where(User.email == "admin@pitpulse.org")
        res_legacy = await session.execute(stmt_legacy)
        legacy = res_legacy.scalar_one_or_none()
        if legacy:
            legacy.is_verified = True
            legacy.is_profile_completed = True
            await session.commit()


if __name__ == "__main__":
    asyncio.run(seed_initial_admin())
