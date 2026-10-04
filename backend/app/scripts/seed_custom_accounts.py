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
from app.models.doctor_profile import DoctorProfile
from app.models.asha_profile import AshaProfile


async def seed_custom_accounts():
    default_password = "logesh@360"
    pwd_hash = hash_password(default_password)

    accounts_to_seed = [
        # Admin
        {
            "email": "logesh_123@gmail.com",
            "full_name": "Logesh Admin",
            "role": RoleEnum.ADMIN,
            "profile_type": None,
        },
        # Doctors
        {
            "email": "doctor_1@gmail.com",
            "full_name": "Dr. Ramesh Kumar",
            "role": RoleEnum.DOCTOR,
            "profile_type": "doctor",
            "medical_license_number": "DOC-TN-2026-001",
            "specialization": "Obstetrics & Gynecology",
            "facility_name": "Primary Health Centre, Sector A",
        },
        {
            "email": "doctor_2@gmail.com",
            "full_name": "Dr. Priya Sharma",
            "role": RoleEnum.DOCTOR,
            "profile_type": "doctor",
            "medical_license_number": "DOC-TN-2026-002",
            "specialization": "Pediatrics & Neonatology",
            "facility_name": "Community Health Centre, Sector B",
        },
        # ASHA Workers (1 to 5)
        {
            "email": "asha_worker1@gmail.com",
            "full_name": "Kavitha ASHA",
            "role": RoleEnum.ASHA,
            "profile_type": "asha",
            "worker_id_code": "ASHA-TN-001",
            "assigned_area": "Solanur Village - Sector 1",
            "primary_health_center": "Vellore PHC",
        },
        {
            "email": "asha_worker2@gmail.com",
            "full_name": "Meena ASHA",
            "role": RoleEnum.ASHA,
            "profile_type": "asha",
            "worker_id_code": "ASHA-TN-002",
            "assigned_area": "Kadambur Village - Sector 2",
            "primary_health_center": "Vellore PHC",
        },
        {
            "email": "asha_worker3@gmail.com",
            "full_name": "Lakshmi ASHA",
            "role": RoleEnum.ASHA,
            "profile_type": "asha",
            "worker_id_code": "ASHA-TN-003",
            "assigned_area": "Melur Village - Sector 3",
            "primary_health_center": "Vellore PHC",
        },
        {
            "email": "asha_worker4@gmail.com",
            "full_name": "Sundari ASHA",
            "role": RoleEnum.ASHA,
            "profile_type": "asha",
            "worker_id_code": "ASHA-TN-004",
            "assigned_area": "Keelur Village - Sector 4",
            "primary_health_center": "Vellore PHC",
        },
        {
            "email": "asha_worker5@gmail.com",
            "full_name": "Radha ASHA",
            "role": RoleEnum.ASHA,
            "profile_type": "asha",
            "worker_id_code": "ASHA-TN-005",
            "assigned_area": "Pudur Village - Sector 5",
            "primary_health_center": "Vellore PHC",
        },
    ]

    async with AsyncSessionLocal() as session:
        for acc in accounts_to_seed:
            email = acc["email"].lower().strip()
            stmt = select(User).where(User.email == email)
            result = await session.execute(stmt)
            existing_user = result.scalar_one_or_none()

            if existing_user:
                existing_user.role = acc["role"]
                existing_user.password_hash = pwd_hash
                existing_user.is_active = True
                existing_user.must_change_password = False
                existing_user.full_name = acc["full_name"]
                print(f"[SEED] Updated account: {email} -> Role: {acc['role'].value}")
                user = existing_user
            else:
                user = User(
                    email=email,
                    full_name=acc["full_name"],
                    password_hash=pwd_hash,
                    role=acc["role"],
                    is_active=True,
                    must_change_password=False,
                )
                session.add(user)
                await session.flush()
                print(f"[SEED] Created account: {email} -> Role: {acc['role'].value}")

            # Handle Profiles
            if acc["profile_type"] == "doctor":
                stmt_doc = select(DoctorProfile).where(DoctorProfile.user_id == user.id)
                res_doc = await session.execute(stmt_doc)
                doc_prof = res_doc.scalar_one_or_none()
                if not doc_prof:
                    doc_prof = DoctorProfile(
                        user_id=user.id,
                        medical_license_number=acc["medical_license_number"],
                        specialization=acc["specialization"],
                        facility_name=acc["facility_name"],
                    )
                    session.add(doc_prof)
                else:
                    doc_prof.medical_license_number = acc["medical_license_number"]
                    doc_prof.specialization = acc["specialization"]
                    doc_prof.facility_name = acc["facility_name"]

            elif acc["profile_type"] == "asha":
                stmt_asha = select(AshaProfile).where(AshaProfile.user_id == user.id)
                res_asha = await session.execute(stmt_asha)
                asha_prof = res_asha.scalar_one_or_none()
                if not asha_prof:
                    asha_prof = AshaProfile(
                        user_id=user.id,
                        worker_id_code=acc["worker_id_code"],
                        assigned_area=acc["assigned_area"],
                        primary_health_center=acc["primary_health_center"],
                    )
                    session.add(asha_prof)
                else:
                    asha_prof.worker_id_code = acc["worker_id_code"]
                    asha_prof.assigned_area = acc["assigned_area"]
                    asha_prof.primary_health_center = acc["primary_health_center"]

        await session.commit()
        print("[SEED] All requested accounts created/updated successfully in PostgreSQL!")


if __name__ == "__main__":
    asyncio.run(seed_custom_accounts())
