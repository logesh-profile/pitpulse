# PitPulse Stage 5.5 Remediation Report
## Authentication, Authorization, Clinical Workflows & Data Integrity Verification

---

## 1. Problems Found
During the forensic audit and validation phase of Stages 1–5, the following critical architecture and domain workflow defects were identified:
1. **P0 Authentication Root Cause**: Secondary Flutter controllers (`PregnancyController`, `AshaController`, and individual data sources) instantiated isolated `new ApiClient()` objects. When `AuthController` logged in and set the JWT authorization header on its own `apiClient`, secondary data sources never inherited the `Authorization: Bearer <access_token>` header. FastAPI's `HTTPBearer(auto_error=True)` rejected requests with `HTTP 403 Forbidden` and `detail: "Not authenticated"`.
2. **P1 Doctor Workflow & Assignment Gap**: Doctors could log in but were missing clinical coordination endpoints (`/doctor/me/patients`, `/doctor/me/patients/unassigned`, `/doctor/me/available-asha`, and `/doctor/me/patients/{id}/asha-assignment`). ASHA assignments were strictly restricted to the `ADMIN` role.
3. **P1 Generic Patient IDOR Gap**: Generic routes such as `/api/v1/patients/{patient_id}/pregnancies` and `/api/v1/patients/{patient_id}` allowed any authenticated ASHA to view medical records of patients not assigned to them.
4. **Account Activation & Password Hygiene**: Admin provisioning returned plaintext temporary passwords, and public registration immediately marked accounts as verified without email verification tokens.
5. **Development Database Pollution**: Automated integration tests created permanent records without fixture teardown/cleanup, leaving 377 total users (198 Patients, 65 Doctors, 62 ASHAs, 52 Admins) in the local database.

---

## 2. Root Causes
- **Isolated HTTP Client Lifecycles**: Lack of a centralized singleton / token propagation mechanism across Flutter feature remote data sources.
- **Incomplete Role-Specific Router for Doctors**: Doctor clinical operations were not exposed in the API router.
- **Missing Assignment Ownership Check on Generic Routes**: `PregnancyService` and `PatientService` checked role existence but did not query `AshaPatientAssignment` status for ASHA users.
- **Missing Email Verification Table & Token Model**: No database-backed cryptographic verification token storage existed.
- **Direct Database Commits in Test Suites**: Tests committed users directly to `pitpulse_db` without session-scoped rollback or cleanup fixtures.

---

## 3. Changes Made
- **Centralized Shared `ApiClient.instance`**: Unified Flutter HTTP networking around a shared singleton pattern that automatically attaches and synchronizes the session JWT Bearer token across all feature modules (`Auth`, `Patients`, `Pregnancy`, `Asha`, `Doctor`, `Admin`).
- **Alembic Database Migration `a5edf7f99923`**: Created `email_verification_tokens` table and added `is_verified` boolean column to `users`.
- **Cryptographic Verification & Activation Service**: Built `EmailService` utilizing SHA-256 token hashing, single-use invalidation, and expiration checks for email verification and professional account activation.
- **Doctor Clinical Coordination Layer**: Created `DoctorService` and `/api/v1/doctor` router enabling doctors to query their patient roster, identify unassigned prenatal patients, inspect available ASHA workloads, and assign ASHAs.
- **Strict Server-Side IDOR Enforcement**: Restricted generic `/patients/{id}` and `/patients/{id}/pregnancies` endpoints to verify active clinical assignments (`AshaPatientAssignment.status == 'ACTIVE'`) before returning data to ASHA workers.
- **Safe Database Cleanup & Test Isolation**: Pruned 293 disposable integration test accounts from the development database (retaining all legitimate test administrators, doctors, ASHAs, and patients), and implemented an automated user tracking fixture in `conftest.py` that deletes test users upon completion.

---

## 4. Authentication Architecture
- **Bearer Token Continuity**: Every authenticated request via `ApiClient.instance` automatically injects `Authorization: Bearer <valid_access_token>`.
- **Session Verification Enforcement**: `AuthService.authenticate_user` checks `user.is_verified` and rejects unverified logins with `HTTP 403 Forbidden` (`detail: "Email address not verified"`).
- **Safe Development Bypass**: In development environments (`DEV_MODE=True`), registration and provisioning endpoints safely return a `dev_verification_token` or `activation_token` to facilitate automated and end-to-end device testing without exposing secrets in logs.

---

## 5. Patient Email Verification
- **Endpoint**: `POST /api/v1/auth/verify-email` with `{ "email": "...", "token": "..." }`.
- **Mechanism**: Raw tokens are generated via `secrets.token_urlsafe(32)`, and only their SHA-256 hashes (`token_hash`) are persisted.
- **Security**: Tokens expire after 24 hours and are marked `is_used = True` upon consumption.

---

## 6. Doctor/ASHA Professional Account Activation
- **Provisioning**: Admin provisions professional accounts via `POST /api/v1/admin/users/doctors` and `POST /api/v1/admin/users/asha-workers`.
- **No Plaintext Passwords**: Responses do not contain temporary passwords; instead, a secure single-use `activation_token` is generated.
- **Activation Endpoint**: `POST /api/v1/auth/activate-professional` with `{ "token": "...", "new_password": "..." }` activates the account (`is_active=True`, `is_verified=True`, `must_change_password=False`) and issues initial JWT session credentials.

---

## 7. Provider Data Cleanup
- **Forensic Audit Finding**: 377 users in PostgreSQL due to non-isolated integration test runs.
- **Cleanup Actions**: Identified and safely deleted 293 test accounts created with UUID patterns (`pat_*`, `doc_*`, `asha_*`, `test_*`, `alpha_*`).
- **Post-Cleanup Status**: Local development database reduced to 84 legitimate, cleanly classified healthcare records (including designated test providers `doctor_1@gmail.com`, `asha_worker1@gmail.com`–`asha_worker5@gmail.com`, and `logesh_123@gmail.com`).

---

## 8. Doctor Patient Workflow
- **Endpoint `GET /api/v1/doctor/me/patients`**: Returns the doctor's comprehensive patient roster including active pregnancy gestational age, EDD, and assigned ASHA field worker details.
- **Endpoint `GET /api/v1/doctor/me/patients/unassigned`**: Filters patients currently needing an ASHA field worker assignment.

---

## 9. Doctor → ASHA Assignment
- **Endpoint `GET /api/v1/doctor/me/available-asha`**: Lists active ASHA workers with real-time active patient workload counts.
- **Endpoint `POST /api/v1/doctor/me/patients/{patient_id}/asha-assignment`**: Allows Doctors to assign or reassign an active ASHA to a patient. Existing active assignments for the patient are marked `INACTIVE` with `unassigned_at` timestamps to ensure one active ASHA per patient.

---

## 10. Authorization Model
- **PATIENT**: Can access only their own medical records, pregnancy records (`/patients/me/pregnancies`), assigned ASHA information, home visits, and vital records.
- **ASHA**: Can access only actively assigned patients (`/asha/me/patients`, `/asha/me/patients/{id}/home-visits`, etc.). Attempting to access an unassigned or transferred patient returns `HTTP 403 Forbidden`.
- **DOCTOR**: Authorized to view clinical rosters, examine patients, inspect ASHA workloads, and execute clinical ASHA assignments. Restricted from administrative system configuration.
- **ADMIN**: Manages account provisioning, status deactivation, system logs, and administrative oversight.

---

## 11. IDOR Fixes
- Replaced direct UUID queries with relationship validation:
  - `PregnancyService.get_patient_pregnancies`: Resolves patient ownership for patients, and active `AshaPatientAssignment` for ASHAs.
  - `PatientService.get_patient_profile_by_id`: Validates that requesting ASHAs have an active assignment for the target patient.
  - `AssignmentService.create_assignment`: Reassigns previous active assignments and revokes past ASHA access immediately upon transfer.

---

## 12. Session Security
- `user.is_active` is enforced on every authenticated API request.
- Deactivated accounts immediately fail authentication with `HTTP 403 Forbidden` (`detail: "Account is deactivated"`).
- Refresh tokens are revoked in PostgreSQL on logout or password changes.

---

## 13. Flutter Changes
- `ApiClient`: Implemented `ApiClient.instance` singleton pattern with dynamic token injection, base URL updates, and semantic failure mapping (`401`, `403`, `404`, `409`, `422`, `NetworkFailure`, `TimeoutFailure`).
- `Doctor Module`: Created `DoctorModels`, `DoctorRemoteDataSource`, `DoctorController`, and `DoctorDashboardScreen` featuring tabbed views for "All Patients" and "Needs ASHA Assignment" alongside an interactive modal for ASHA field worker allocation.
- `Admin Dashboard`: Updated provider directory cards to display "Pending Activation" badges with activation tokens and status indicators without exposing passwords.
- `Patient & ASHA Dashboards`: Wired to the shared `ApiClient.instance` to guarantee persistent session authentication.

---

## 14. Backend Changes
- `app/models/verification_token.py`: Verification and activation token schema.
- `app/models/user.py`: Added `is_verified` mapped column.
- `app/schemas/doctor.py`: Doctor clinical coordination request and response schemas.
- `app/services/email_service.py`: Token generation, hashing, and email verification engine.
- `app/services/doctor_service.py`: Doctor patient roster and assignment logic.
- `app/api/v1/doctor.py`: Doctor API routes registered in `api_v1_router`.
- `app/api/v1/auth.py`: Added `/verify-email`, `/resend-verification`, and `/activate-professional`.

---

## 15. Database Changes
- **Alembic Revision**: `a5edf7f99923_add_verification_tokens.py` applied cleanly to `pitpulse_db`.
- **New Tables**: `email_verification_tokens` (with indices on `id`, `user_id`, `token_hash`).
- **Updated Tables**: `users` table altered to include `is_verified BOOLEAN NOT NULL DEFAULT FALSE`.

---

## 16. Tests Added
- `backend/tests/test_stage5_5.py`:
  - `test_email_verification_lifecycle`: Verifies registration, blocked login before verification, token verification, and successful login.
  - `test_professional_activation_workflow`: Verifies Admin provisioning, activation token redemption, password setup, and subsequent login.
  - `test_doctor_clinical_coordination_and_asha_assignment`: Verifies Doctor patient rosters, unassigned patient filtering, ASHA workload listing, and ASHA assignment.
  - `test_idor_protection_generic_pregnancy_and_profile_routes`: Proves unassigned ASHAs receive 403 Forbidden on unassigned patient routes.
- `mobile/test/stage5_5_remediation_test.dart`:
  - Shared `ApiClient.instance` token propagation.
  - `UserModel` verification parsing.
  - `DoctorPatientModel` and `DoctorAshaModel` serialization.
  - Semantic status code failure mappings.

---

## 17. Tests Passed
- **Backend Tests**: 36/36 passed (`pytest -v`).
- **Flutter Unit & Integration Tests**: 33/33 passed (`flutter test`).
- **Flutter Analyzer**: 0 issues (`flutter analyze` -> "No issues found!").

---

## 18. Physical Device Verification
- **Release APK**: Successfully built `build\app\outputs\flutter-apk\app-release.apk` (51.3 MB).
- **Target Backend**: Tested with `--dart-define=BACKEND_URL=http://10.63.229.152:8000`.
- **Verified Flows**:
  - Patient login, profile loading, and pregnancy record creation without "Not authenticated" error.
  - Doctor login, review of unassigned patients, and field worker ASHA assignment.
  - ASHA login, immediate reflection of assigned patients, and vitals recording.

---

## 19. Summary Comparison Table

| Area | Before | After | Status |
|------|--------|-------|--------|
| Pregnancy authentication | Broken ("Not authenticated" due to isolated `ApiClient`) | Fixed via shared `ApiClient.instance` session token architecture | **PASS** |
| Shared API client | Feature data sources created isolated instances | Single shared client across all remote data sources | **PASS** |
| Patient verification | Missing (accounts instantly active without verification) | Cryptographic SHA-256 token verification required before login | **PASS** |
| Doctor workflow | Missing patient roster and clinical coordination APIs | Full Doctor clinical coordination roster & available ASHA views | **PASS** |
| ASHA assignment | Restricted to ADMIN role only | Clinical assignment delegated to authorized DOCTOR role | **PASS** |
| IDOR | Unassigned ASHA could view generic `/patients/{id}` routes | Server-side active assignment check enforces 403 Forbidden | **PASS** |
| Provider data | 377 polluted test accounts in local PostgreSQL | Safely cleaned to 84 valid records with automated test teardown | **PASS** |
| Session security | Deactivated users could use old tokens | Active and verified flags enforced on all protected requests | **PASS** |

---

## 20. Verification Metrics

- **Backend tests**: 36/36 PASSED
- **Flutter tests**: 33/33 PASSED
- **Flutter analyze**: 0 issues
- **Alembic Migration**: PASS (`a5edf7f99923`)
- **Release APK**: PASS (`app-release.apk` 51.3MB)
- **Physical device readiness**: PASS
- **Git commit hash**: `fa616f2`
- **Git commit message**: `feat(stage5.5): remediate authentication architecture, doctor clinical workflow, email verification, and IDOR protections`
