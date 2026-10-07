# MAATRA

MAATRA is an enterprise-grade healthcare intelligence and continuum platform engineered for Android and cloud deployment. It unifies maternal health monitoring, clinical triage, field community health workflows, and an intelligent clinical conversational agent into a resilient, offline-capable architecture.

---

## Table of Contents

1. Executive Overview
2. Core Capabilities and Architectural Invariants
3. What Has Been Included vs. Excluded
4. System Architecture
5. Design System and Visual Standards
6. Role-Based Access Control and Workflows
7. Directory Structure
8. API Endpoints and Data Contracts
9. Environment Setup and Deployment
10. Testing and Verification Standards

---

## 1. Executive Overview

MAATRA bridges community-level healthcare workers (ASHA), certified medical practitioners (Doctors), patients, and system administrators into a synchronized clinical loop. Built on Flutter for the mobile client and FastAPI with PostgreSQL for the backend service, MAATRA is engineered to operate in remote, low-connectivity rural environments while maintaining full data integrity and zero hardcoded records.

---

## 2. Core Capabilities and Architectural Invariants

### Zero Hardcoded Data Policy
Every record displayed in the application is dynamically fetched and synchronized with real database models. No dummy patient identifiers, static provider contact lists, or synthetic mock vitals are hardcoded into client screens or services.

### Resilient Clinical AI Engine
MAATRA integrates high-capability large language models (Google Gemini 1.5 Flash and xAI Grok) connected directly to dynamic patient health records. The assistant handles:
- Natural human conversation across multiple languages (English, Tamil, Tanglish).
- Home remedies, general wellness, triage advice, and preventative health guidance.
- Dynamic grounding using the authenticated user's actual vitals, prescriptions, and visit logs.
- Strict safety guardrails that detect red-flag clinical conditions (e.g., preeclampsia, high fever, severe hemorrhaging) and trigger immediate medical escalation alerts.

### Genuine Multi-Factor Authentication
Patient registration requires verification via a 6-digit one-time password (OTP) dispatched to a valid email address. Unverified accounts cannot authenticate or access clinical APIs.

### First-Login Professional Onboarding
Medical practitioners and ASHA workers are provisioned by the Administrator using their email and initial temporary credentials. Upon initial sign-in, the system intercepts uncompleted profiles and mandates the submission of personal details (full name, age, gender, contact number, medical license or assigned field sector) before granting operational dashboard access.

### Distinct Role Boundaries
- **Administrator**: Dedicated strictly to provider account provisioning, lifecycle status management (activation and deactivation), and account decommissioning. Clinical operations and patient-to-worker assignments are intentionally decoupled from the administrative console.
- **Doctor**: Oversees clinical registries, reviews triage flags, and directly maps patients to designated community ASHA workers.
- **ASHA Worker**: Conducts field home visits, logs offline maternal and child health vitals, and tracks clinical alerts.
- **Patient**: Views verified personal health records, consults the clinical AI assistant, and tracks healthcare team details.

---

## 3. What Has Been Included vs. Excluded

| Feature Area | Included in Current Release | Excluded / Deprecated |
| :--- | :--- | :--- |
| Application Name | MAATRA | PitPulse (legacy name deprecated) |
| Visual Design System | Midnight Slate and Royal Amethyst (Dark Theme) | Generic Material defaults and harsh neon palettes |
| Typography | Plus Jakarta Sans (Google Fonts) | Default system serif/sans |
| Clinical AI Engine | Live LLM integration (Gemini / Grok) with patient record context | Hardcoded pregnancy-only response trees |
| Data Layer | Relational PostgreSQL and client SQLite store | Hardcoded mock JSON fixtures |
| Patient Auth | Email registration with mandatory 6-digit OTP code | Instant unverified registration |
| Provider Management | Provisioning via email followed by mandatory first-login profile onboarding | Unauthenticated or pre-filled provider accounts |
| Patient-ASHA Mapping | Managed exclusively by Doctors through the Doctor Dashboard | Centralized administrative manual mapping |
| Admin Scope | Strictly user lifecycle: provision, activate, deactivate, delete | Clinical patient data management |
| Launch Experience | Smooth signature ribbon reveal transition | Static blank splash screen |

---

## 4. System Architecture

```text
                  +----------------------------------------------+
                  |               MAATRA Android Client          |
                  |                (Flutter / Dart)              |
                  +----------------------+-----------------------+
                                         |
                   Secure HTTPS / WSS    |   Local Encrypted Store
                   Bearer JWT Tokens     |   (SQLite / SecureStorage)
                                         v
                  +----------------------------------------------+
                  |               FastAPI REST Backend           |
                  |                 (Python 3.13)                |
                  +-------+--------------------+-----------+-----+
                          |                    |           |
                          v                    v           v
           +----------------------+  +-------------+  +-------------------+
           |      PostgreSQL      |  | SMTP Service|  | Google Gemini API |
           |  Relational Database |  |  (Email OTP)|  |    / xAI Grok     |
           +----------------------+  +-------------+  +-------------------+
```

### Mobile Client Stack
- **Framework**: Flutter 3.x
- **State Management**: Reactive Controller Pattern with ChangeNotifier
- **Networking**: Dio with custom auth interceptors, retry handlers, and token vaults
- **Offline Storage**: SQLite (sqflite) with bidirectional transaction queue
- **Secure Storage**: flutter_secure_storage utilizing Android Keystore
- **Typography & Theme**: Google Fonts (Plus Jakarta Sans) with centralized design tokens

### Backend API Stack
- **Framework**: FastAPI (Asynchronous Python)
- **Database Engine**: SQLAlchemy 2.0 Async with asyncpg / PostgreSQL
- **Authentication**: OAuth2 Password Flow with RFC 7519 JWT and Passlib (bcrypt)
- **AI Integration**: Google GenAI SDK and HTTP-based xAI endpoints
- **Validation**: Pydantic v2 schemas for bidirectional type safety

---

## 5. Design System and Visual Standards

MAATRA utilizes the **Midnight Slate and Royal Amethyst** visual language, tailored for high-contrast visibility and reduced eye strain during clinical and night-shift environments.

### Color Tokens

```text
Token Name                Hex Code     Semantic Purpose
-----------------------   ----------   -------------------------------------------
Void Midnight Slate       #0B0F19      Scaffold and primary background
Obsidian Card Surface     #111827      Elevated card and bottom sheet background
Deep Amethyst             #6D28D9      Primary gradient start and container accent
Royal Amethyst            #8B5CF6      Primary brand accent, focus states, CTAs
Electric Lilac            #A78BFA      Secondary iconography, highlights, labels
Pastel Amethyst           #C4B5FD      Subtle badge fills and secondary text
Emerald Confirmation      #10B981      Active states, verified badges, safe vitals
Amber Warning             #F59E0B      Pending verification, moderate triage flags
Crimson Escalation        #EF4444      Critical vitals alerts, delete confirmations
Crisp Ivory               #F9FAFB      Primary typography and header text
Slate Lavender            #9CA3AF      Secondary typography, hints, subtitles
```

### Typography Hierarchy
- **Font Family**: Plus Jakarta Sans
- **Display / Headers**: 24px - 32px, Bold / ExtraBold (800-900), tracking -0.5px
- **Section Titles**: 16px - 18px, SemiBold / Bold (600-700)
- **Body Text**: 14px - 15px, Regular / Medium (400-500), line height 1.5
- **Captions and Badges**: 11px - 12px, Medium / SemiBold (500-600)

---

## 6. Role-Based Access Control and Workflows

```text
[ ADMIN ]
    |
    +---> Provisions Doctor Account (Email + Initial Password)
    +---> Provisions ASHA Account (Email + Initial Password)
    +---> Toggles Account Status (Active / Deactivated)
    +---> Deletes Accounts Permanently

[ DOCTOR / ASHA WORKER ]
    |
    +---> First Login -> Profile Onboarding Screen
    |        (Submits: Name, Age, Gender, Phone, License / Locality)
    |
    +---> Subsequent Logins -> Clinical Workspace
             Doctor:
               - Inspects dynamic Patient Registry
               - Inspects ASHA Worker Directory
               - Maps Patients to designated ASHA Workers
             ASHA Worker:
               - Conducts field home visits
               - Logs maternal health metrics and vitals
               - Synchronizes offline records

[ PATIENT ]
    |
    +---> Register -> 6-Digit Email Verification (OTP)
    +---> Verified Login -> MAATRA Dashboard
             - Views live health metrics and records
             - Accesses MAATRA Clinical AI Assistant
```

---

## 7. Directory Structure

```text
pitpulse/
├── mobile/
│   ├── android/                        # Native Android Gradle configuration
│   ├── assets/
│   │   └── images/                     # Production brand iconography
│   ├── lib/
│   │   ├── app/
│   │   │   └── app.dart                # MaterialApp configuration, routes, theme
│   │   ├── core/
│   │   │   ├── errors/                 # Domain failures and exception handling
│   │   │   ├── network/                # ApiClient, interceptors, connectivity
│   │   │   ├── storage/                # SecureStorageService and SQLite database
│   │   │   └── theme/
│   │   │       └── maatra_theme.dart   # Royal Amethyst theme tokens & styles
│   │   └── features/
│   │       ├── admin/                  # Provider provisioning and lifecycle screens
│   │       ├── asha/                   # Field visit logs, patient triage, offline queue
│   │       ├── auth/                   # Login, register, OTP verification, onboarding
│   │       ├── common/                 # Signature ribbon animation and shared widgets
│   │       ├── doctor/                 # Patient registry, ASHA directory, care mapping
│   │       ├── patient/                # Health record views and patient profile
│   │       └── patient_ai/             # Gemini/Grok AI chat, safety triage, audio service
│   ├── test/                           # Unit, widget, and state machine test suites
│   └── pubspec.yaml                    # Dart package dependencies and assets
│
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── v1/                     # Modular API routers (auth, admin, doctor, asha)
│   │   ├── core/
│   │   │   ├── config.py               # Environment configuration settings
│   │   │   ├── database.py             # SQLAlchemy engine and async session makers
│   │   │   └── security.py             # Password hashing and JWT token handlers
│   │   ├── models/                     # SQLAlchemy relational schema entities
│   │   ├── schemas/                    # Pydantic request and response contracts
│   │   ├── scripts/
│   │   │   └── seed_admin.py           # Master administrator seeder
│   │   └── services/                   # Business logic (auth, email, AI orchestration)
│   ├── requirements.txt                # Python package dependencies
│   └── .env.example                    # Environment variable template
│
├── docs/                               # Architecture blueprints and system contracts
│   ├── ARCHITECTURE.md
│   └── DEVELOPMENT_RULES.md
└── README.md                           # Master documentation
```

---

## 8. API Endpoints and Data Contracts

### Authentication and Onboarding
- `POST /api/v1/auth/register` : Patient registration with automatic OTP generation.
- `POST /api/v1/auth/verify-code` : Validates 6-digit email OTP and issues JWT tokens.
- `POST /api/v1/auth/resend-code` : Dispatches a fresh 6-digit OTP code with cooldown check.
- `POST /api/v1/auth/login` : Authenticates user credentials across all roles.
- `POST /api/v1/auth/refresh` : Exchanges valid refresh token for a new access token.
- `POST /api/v1/auth/complete-profile` : Saves practitioner personal onboarding details.
- `GET /api/v1/auth/me` : Returns authenticated user profile including verification status.

### Provider Administration
- `POST /api/v1/admin/users/doctors` : Provisions a doctor account with temporary credentials.
- `POST /api/v1/admin/users/asha-workers` : Provisions an ASHA worker account.
- `GET /api/v1/admin/users/professionals` : Retrieves all registered doctor and ASHA accounts.
- `PATCH /api/v1/admin/users/{user_id}/status` : Toggles user account active/deactivated state.
- `DELETE /api/v1/admin/users/{user_id}` : Permanently removes a provider account.

### Clinical Management
- `GET /api/v1/doctor/patients` : Lists all registered patients and assignment statuses.
- `GET /api/v1/doctor/asha-workers` : Lists available community ASHA workers.
- `POST /api/v1/doctor/assignments` : Assigns a patient to a designated ASHA worker.
- `POST /api/v1/patient-ai/chat` : Dispatches conversational prompts to the grounded AI engine.

---

## 9. Environment Setup and Deployment

### Prerequisites
- Python 3.11+
- Flutter 3.24+
- PostgreSQL 15+ (or SQLite for localized development)
- Android SDK with API Level 34+

### Backend Initialization
```powershell
# Navigate to backend directory
cd backend

# Create and activate virtual environment
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install required dependencies
pip install -r requirements.txt

# Configure environment variables
Copy-Item .env.example .env

# Seed initial system administrator
py -3 app/scripts/seed_admin.py

# Launch FastAPI development server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Default System Administrator Credentials:
- Email: `admin123@gmail.com`
- Password: `admin123`

### Mobile Client Execution
```powershell
# Navigate to mobile directory
cd mobile

# Retrieve Dart packages
flutter pub get

# Verify code quality and static analysis
flutter analyze

# Execute automated test suite
flutter test

# Run application on connected device or emulator
flutter run

# Compile production release APK
flutter build apk --release
```

---

## 10. Testing and Verification Standards

MAATRA maintains rigorous continuous integration standards across both tiers:

- **Static Analysis**: The Flutter codebase must maintain zero errors and zero warnings (`flutter analyze` returns code 0).
- **Unit and Widget Testing**: Automated suites validate the authentication state machine, OTP input behaviors, login validation states, and grounded AI responses.
- **Integration Validation**: Automated tests confirm end-to-end flows from administrative account provisioning through role onboarding and clinical assignments.
- **Offline Integrity**: Local mutation queues guarantee that updates performed in low-connectivity conditions synchronize safely without duplicate records once connectivity is restored.
