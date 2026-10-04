from fastapi import APIRouter

from app.api.v1.admin import router as admin_router
from app.api.v1.asha import router as asha_router
from app.api.v1.auth import router as auth_router
from app.api.v1.doctor import router as doctor_router
from app.api.v1.patients import router as patients_router
from app.api.v1.patient_ai import router as patient_ai_router
from app.api.v1.pregnancies import router as pregnancies_router

api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(auth_router)
api_v1_router.include_router(admin_router)
api_v1_router.include_router(doctor_router)
api_v1_router.include_router(patients_router)
api_v1_router.include_router(pregnancies_router)
api_v1_router.include_router(asha_router)
api_v1_router.include_router(patient_ai_router)

__all__ = ["api_v1_router"]
