# MAATRA

MAATRA is an enterprise-grade healthcare intelligence and clinical continuum platform engineered for Android and cloud deployment. It unifies maternal health monitoring, clinical triage, community health worker field operations, and an intelligent clinical conversational agent into a resilient, offline-capable architecture.

---

## Table of Contents

1. Executive Overview
2. Core Capabilities and Architectural Invariants
3. What Has Been Included vs. Excluded
4. System Architecture
5. Design System and Visual Standards (Swiss Medical Precision)
6. Role-Based Access Control and Workflows
7. Complete Changelog and System Update History
8. Directory Structure
9. API Endpoints and Data Contracts
10. Environment Setup and Deployment
11. Testing and Verification Standards

---

## 1. Executive Overview

MAATRA bridges community-level healthcare workers (ASHA), certified medical practitioners (Doctors), patients, and system administrators into a synchronized clinical loop. Built on Flutter for the mobile client and FastAPI with PostgreSQL on cloud infrastructure, MAATRA is engineered to operate in remote, low-connectivity rural environments while maintaining full data integrity and zero hardcoded records.

---

## 2. Core Capabilities and Architectural Invariants

### Zero Hardcoded Data Policy
Every record displayed in the application is dynamically fetched and synchronized with real database models. No dummy patient identifiers, static provider contact lists, or synthetic mock vitals are hardcoded into client screens or services.

### Resilient Clinical AI Engine (Anu Health Companion)
MAATRA integrates high-capability large language models (Google Gemini 1.5 Flash / Flash-Lite / 2.0 with fallback to xAI Grok) connected directly to dynamic patient health records. The assistant handles:
- Natural human conversation across multiple languages (English, Tamil, Tanglish).
- Home remedies, general wellness, triage advice, and preventative health guidance.
- Dynamic grounding using the authenticated user's actual vitals, prescriptions, and visit logs.
- Strict safety guardrails that detect red-flag clinical conditions (e.g., preeclampsia, high fever, severe hemorrhaging) and trigger immediate medical escalation alerts.
- Bilingual Speech-to-Text (STT) voice input and Text-to-Speech (TTS) auditory readback.

### Genuine Multi-Factor Authentication & Google OAuth
- **Out-of-Band Email OTP**: Patient registration requires verification via a 6-digit one-time password (OTP) dispatched strictly out-of-band to a verified email address via SMTP. Verification codes are never exposed on client screens or API response payloads.
- **Native Google Sign-In**: Fully integrated Google OAuth 2.0 flow verifying ID tokens on the FastAPI backend with automated role onboarding.
- **Persistent Sessions**: Encrypted local session storage using Android Keystore ensures returning users seamlessly bypass authentication screens.

### First-Login Professional Onboarding
Medical practitioners and ASHA workers are provisioned by the Administrator using their email and initial temporary credentials. Upon initial sign-in, the system intercepts uncompleted profiles and mandates the submission of personal details (full name, age, gender, contact number, medical license or assigned field sector) before granting operational dashboard access.

### Distinct Role Boundaries
- **Administrator**: Dedicated strictly to provider account provisioning, lifecycle status management (activation and deactivation), and account decommissioning. Clinical operations and patient-to-worker assignments are intentionally decoupled from the administrative console.
- **Doctor**: Oversees clinical registries, reviews triage flags, and directly maps patients to designated community ASHA workers.
- **ASHA Worker**: Conducts field home visits, logs offline maternal and child health vitals, and tracks clinical alerts.
- **Patient**: Views verified personal health records, consults the Anu AI health companion, and tracks assigned healthcare team members.

---

## 3. What Has Been Included vs. Excluded

| Feature Area | Included in Current Release | Excluded / Deprecated |
| :--- | :--- | :--- |
| Application Name | MAATRA | PitPulse (legacy name permanently deprecated) |
| Visual Design System | Swiss Medical Precision (Warm Ivory, Porcelain, Emerald) | Neon gradients, dark cyberpunk glows, generic material defaults |
| Typography | Plus Jakarta Sans (Google Fonts) with strict weight hierarchy | Default system serif/sans |
| Clinical AI Engine | Grounded LLM integration (Gemini / Grok) with patient records | Hardcoded pregnancy-only static decision trees |
| AI Identity | Anu 3D clinical character avatar across dashboard & chat | Generic robot or sparkle AI icons |
| Verification Model | Out-of-band SMTP delivery to inbox with zero code leakage | On-screen verification code auto-displays |
| Google Auth | Native Google OAuth 2.0 with backend token verification | Web-view scraping or unverified mock Google buttons |
| Launch Experience | Geometric 3-ring logo convergence with wordmark reveal | Static blank screen or unpolished raw asset jump |
| Data Layer | Relational PostgreSQL on cloud and client SQLite store | Hardcoded mock JSON fixtures |
| Patient-ASHA Mapping | Managed exclusively by Doctors through Doctor Dashboard | Centralized administrative manual mapping |
| Admin Scope | Strictly user lifecycle: provision, activate, deactivate, delete | Clinical patient data management |

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
                  |           (Python 3.11+ on Render)           |
                  +-------+--------------------+-----------+-----+
                          |                    |           |
                          v                    v           v
           +----------------------+  +-------------+  +-------------------+
           |      PostgreSQL      |  | SMTP Service|  | Google Gemini API |
           |  Relational Database |  |  (Email OTP)|  |    / xAI Grok     |
           +----------------------+  +-------------+  +-------------------+
```

### Mobile Client Stack
- **Framework**: Flutter 3.24+ (Dart)
- **State Management**: Reactive Controller Pattern with ChangeNotifier
- **Networking**: Dio with custom auth interceptors, retry handlers, and token vaults
- **Offline Storage**: SQLite (sqflite) with bidirectional transaction queue
- **Secure Storage**: flutter_secure_storage utilizing Android Keystore
- **Typography & Theme**: Google Fonts (Plus Jakarta Sans) with centralized design tokens
- **Audio Services**: flutter_tts for voice synthesis, speech_to_text for vocal input

### Backend API Stack
- **Framework**: FastAPI (Asynchronous Python)
- **Database Engine**: SQLAlchemy 2.0 Async with asyncpg / PostgreSQL
- **Authentication**: OAuth2 Password Flow with RFC 7519 JWT, Passlib (bcrypt), and Google Auth
- **AI Integration**: Google GenAI SDK and HTTP-based xAI Grok endpoints
- **Validation**: Pydantic v2 schemas for bidirectional type safety
- **Email Service**: Asynchronous SMTP client with HTML templates

---

## 5. Design System and Visual Standards (Swiss Medical Precision)

MAATRA adheres to the **Swiss Medical Precision** aesthetic, inspired by modern clinical leaders (One Medical, Apple Health). It replaces AI cliches (dark violet glows, neon rings) with warm, organic, authoritative healthcare design tokens.

### Color Tokens

```text
Token Name                Hex Code     Semantic Purpose
-----------------------   ----------   -------------------------------------------
Warm Ivory Canvas         #FAF8F5      Primary scaffold background, calm organic feel
Porcelain Card Surface    #FFFFFF      Elevated clinical cards, modals, sheets
Subtle Inset Wash         #F3EFEA      Input fields, inset backgrounds, secondary pills
Hairline Divider Border   #E8E2D8      1px clean hairline border, restrained separation
Brand Medical Emerald     #0D483A      Primary brand color, authoritative clinical trust
Brand Sage                #2E6555      Secondary clinical action and category badges
Brand Sage Wash           #EBF3F0      Soft badge fill and indicator pill background
Charcoal Ink Typography   #1B2421      Primary headline and body text, deep readability
Muted Slate Sage          #56635F      Secondary copy, subtitles, metadata
Quiet Gray                #8A9793      Timestamps, captions, subtle form labels
Healthy Vitals Green      #1B7A58      Normal clinical observation readings
Warning Amber             #B46A10      Attention required, trimester badge, borderline
Medical Terracotta Alert  #C53030      Critical clinical alerts, emergency escalation
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
    +---> First Login -> Mandatory Profile Onboarding Screen
    |        (Submits: Name, Age, Gender, Phone, License / Locality)
    |
    +---> Subsequent Logins -> Dedicated Clinical Workspace
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
    +---> Native Google Sign-In OR Email Register + Out-of-Band OTP
    +---> Verified Login -> MAATRA Patient Dashboard
             - Views live maternal records (gestational age, trimester, EDD)
             - Views clinical vital observation history
             - Views assigned ASHA field health worker contact card
             - Interacts with Anu Clinical AI Companion
```

---

## 7. Complete Changelog and System Update History

All functional, security, and visual updates implemented across the platform to date:

### Version 1.0.0 — Foundation, Cloud Architecture, and Rebranding
- **Cloud Infrastructure**: Deployed FastAPI backend and PostgreSQL database to Render production environment (`https://pitpulse-backend.onrender.com`).
- **Brand Transition**: Replaced legacy name PitPulse with **MAATRA** across application manifests, package identifiers, and UI headers.
- **Relational Schemas**: Created SQLAlchemy models for users, patient profiles, maternal health records, vitals observations, and field visit logs.
- **Admin Seeding**: Implemented automated startup seeder creating master administrator credentials (`admin123@gmail.com`).

### Version 1.0.1 — Clinical Continuum and Care Mapping
- **Doctor Care Mapping**: Built Doctor Dashboard enabling medical officers to review unregistered patients and assign them directly to field ASHA workers.
- **ASHA Field Workflows**: Implemented home visit logging with offline mutation queues and local SQLite synchronization.
- **Role Onboarding**: Added mandatory first-login profile onboarding intercepts for provisioned Doctors and ASHA workers.

### Version 1.0.2 — Intelligent Clinical Assistant & RAG Engine
- **Deprecation of Static Decision Trees**: Permanently deleted legacy hardcoded pregnancy trees (`pregnancy_assistant_service.dart`).
- **Multi-Model AI Service**: Integrated Google Gemini 1.5 Flash / Flash-Lite / 2.0 with fallback failover to xAI Grok.
- **Context-Aware Grounding**: Configured multi-tool agentic RAG that binds user prompts to actual database health records (gestational age, maternal blood pressure, hemoglobin, fetal heart rate).
- **Trilingual Support**: Added natural language processing for English, Tamil, and Tanglish health conversations.
- **Clinical Safety Guardrails**: Built automated clinical escalation triggers identifying dangerous symptoms (preeclampsia, severe bleeding, persistent high fever).

### Version 1.0.3 — Authentication Hardening and Google OAuth
- **Real SMTP OTP Verification**: Wired genuine 6-digit verification code generation delivered directly to the user's inbox via SMTP.
- **Security Elimination of Dev Code Leakage**: Completely removed `dev_verification_code` from backend API responses and purged all on-screen OTP banners/autofills from mobile screens.
- **Native Google Sign-In**: Integrated Google OAuth 2.0 (`google_sign_in`) with Web client ID backend validation via `/api/v1/auth/google-login`.
- **Persistent Sessions**: Implemented auto-login via encrypted token storage, seamlessly bypassing splash/login on subsequent app launches.
- **Account Management**: Built Profile Settings screen featuring account details, live server connectivity indicators, and secure sign-out.

### Version 1.0.4 — System Versioning and Logo Reveal Animation
- **In-App Version Checker**: Created `/api/v1/system/app-version` endpoint and mobile version checking service for over-the-air update notifications.
- **Cinematic Logo Reveal**: Designed and implemented `MaatraLogoReveal`, a 3.2-second geometric motion sequence featuring 3-ring circular convergence, center symbol lock, and smooth wordmark emergence.
- **Anu 3D Character Avatar**: Integrated the uploaded high-fidelity 3D character portrait (`anu_avatar.png`) across dashboard hero cards, chat headers, and conversation responses.

### Version 1.0.5 — Swiss Medical Precision Frontend Overhaul
- **Complete Visual Overhaul**: Fully eliminated dark cyberpunk palettes and neon AI glows.
- **Organic Warm Canvas**: Migrated backgrounds to Warm Ivory (`#FAF8F5`) and cards to Pure Porcelain (`#FFFFFF`) with 1px hairline dividers (`#E8E2D8`).
- **Authoritative Palette**: Established Medical Forest Emerald (`#0D483A`), Clinical Sage (`#2E6555`), and Charcoal Ink typography (`#1B2421`).
- **Dashboard & Chat Refinement**: Redesigned Patient Dashboard cards, Maternal Health sections, and Anu AI Chat bubbles into clean, high-end clinical interfaces.
- **Quality Assurance**: Maintained 0 errors in `flutter analyze`, 100% test suite pass rate, and successful release APK compilation (`app-release.apk`, 53.7 MB).

### Version 1.0.6 — Offline Rural Care & Healthcare Radar Suite
- **1-Tap Emergency Cellular SOS**: Direct telephony action on patient dashboard for **108 Ambulance** and assigned **ASHA Worker** requiring zero mobile data or internet, coupled with offline step-by-step first-aid protocols (hemorrhage, eclampsia/fits, premature water rupture).
- **Offline Healthcare & Medical Radar**: Embedded dataset and satellite GPS engine locating nearby Primary Health Centres (PHCs), Government Taluk & District Hospitals (GHs), Private Maternity Clinics, 24x7 Delivery Units, and Medical Shops/Pharmacies. Computes Haversine straight-line distance, compass bearings, 1-tap direct calling, and navigation directions completely offline.
- **Daily Fetal Kick Counter (DFMC)**: 100% offline 3rd-trimester fetal movement monitor with large tactile tap counter, 2-hour clinical session timer, timeline logger, and low-movement warning protocol.
- **Automated Test Coverage**: Created `test/offline_rural_suite_test.dart` validating Haversine distance calculations, category filters, and search capabilities. Release APK built cleanly (`app-release.apk`, 54.1 MB).

---

## 8. Directory Structure

```text
pitpulse/
├── mobile/
│   ├── android/                        # Native Android Gradle configuration
│   ├── assets/
│   │   └── images/                     # Brand emblem, wordmark, and Anu character avatar
│   ├── lib/
│   │   ├── app/
│   │   │   └── app.dart                # MaterialApp configuration, routes, theme
│   │   ├── core/
│   │   │   ├── errors/                 # Domain failures and exception handling
│   │   │   ├── network/                # ApiClient, interceptors, connectivity
│   │   │   ├── storage/                # SecureStorageService and SQLite database
│   │   │   └── theme/
│   │   │       └── maatra_theme.dart   # Swiss Medical Precision design tokens
│   │   └── features/
│   │       ├── admin/                  # Provider provisioning and lifecycle screens
│   │       ├── asha/                   # Field visit logs, patient triage, offline queue
│   │       ├── auth/                   # Login, register, Google auth, OTP verification
│   │       ├── common/                 # Cinematic logo reveal, profile settings, widgets
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
└── README.md                           # Master documentation
```

---

## 9. API Endpoints and Data Contracts

### Authentication and Identity
- `POST /api/v1/auth/register` : Patient registration with automatic OTP generation.
- `POST /api/v1/auth/verify-code` : Validates 6-digit email OTP and issues JWT tokens.
- `POST /api/v1/auth/resend-code` : Dispatches a fresh 6-digit OTP code with cooldown check.
- `POST /api/v1/auth/google-login` : Verifies native Google ID token and returns session tokens.
- `POST /api/v1/auth/login` : Authenticates user credentials across all roles.
- `POST /api/v1/auth/refresh` : Exchanges valid refresh token for a new access token.
- `POST /api/v1/auth/complete-profile` : Saves practitioner personal onboarding details.
- `GET /api/v1/auth/me` : Returns authenticated user profile including verification status.

### System and Versioning
- `GET /api/v1/system/app-version` : Returns current minimum and recommended app versions with download URLs.

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

## 10. Environment Setup and Deployment

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

## 11. Testing and Verification Standards

MAATRA maintains rigorous continuous integration standards across both tiers:

- **Static Analysis**: The Flutter codebase strictly enforces zero errors and zero warnings (`flutter analyze` returns code 0).
- **Unit and Widget Testing**: Automated suites validate the authentication state machine, OTP input behaviors, login validation states, and grounded AI responses.
- **Integration Validation**: Automated tests confirm end-to-end flows from administrative account provisioning through role onboarding and clinical assignments.
- **Offline Integrity**: Local mutation queues guarantee that updates performed in low-connectivity conditions synchronize safely without duplicate records once connectivity is restored.
