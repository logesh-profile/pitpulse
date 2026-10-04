# PitPulse

PitPulse is a production-oriented Android healthcare application designed to streamline healthcare delivery, patient monitoring, risk screening, and clinical field workflows with offline-first support.

## Product Overview

PitPulse provides four dedicated, role-based experiences within a single unified Flutter Android application:
1. **Patient**: Health record tracking, symptom check, appointments, emergency alerts, and educational guidance.
2. **ASHA (Accredited Social Health Activist)**: Offline-first field data collection, maternal & child tracking, immunization logging, and village-level triage.
3. **Doctor**: Clinical consultation, digital prescriptions, patient risk screening review, and referral management.
4. **Admin**: Role and user provisioning, facility management, audit log inspection, and aggregate operational oversight.

## Core Architecture Stack

- **Mobile Frontend**: Flutter (Dart) — Android-first architecture with clean layer separation, Dio HTTP client, SQLite offline store, background synchronization queue, and secure local token vault.
- **Backend API**: FastAPI (Python) — Asynchronous RESTful API with strict JWT authentication, role-based access control (RBAC), and transactional integrity.
- **Primary Database**: PostgreSQL — Relational database enforcing ACID guarantees, audit logs, and clinical schemas.
- **Local Mobile Database**: SQLite — Client-side encrypted store for offline caching and bidirectional mutation queue.
- **Storage**: S3-compatible Object Storage for clinical attachments and imaging.
- **AI Engine**: Explainable clinical risk screening, decision support, and on-device assistance.

## Project Structure

```text
pitpulse/
├── mobile/       # Flutter Android client application
│   ├── lib/
│   │   ├── app/
│   │   ├── core/
│   │   │   ├── config/
│   │   │   ├── errors/
│   │   │   └── network/
│   │   └── features/
│   │       └── health_check/
│   └── test/
├── backend/      # FastAPI Python backend application
│   ├── app/
│   │   ├── core/
│   │   └── main.py
│   ├── tests/
│   ├── requirements.txt
│   └── .env.example
├── docs/         # Architectural blueprints, specifications & development rules
│   ├── ARCHITECTURE.md
│   └── DEVELOPMENT_RULES.md
├── .env.example  # Global environment variable template
├── .gitignore    # Comprehensive ignore rules
└── README.md     # Project documentation
```

## Running the Application Locally

### 1. Start FastAPI Backend Server
```powershell
# Navigate to backend directory
cd backend

# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Install requirements (first time)
pip install -r requirements.txt

# Run server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
- API Health Check: `http://localhost:8000/health`
- Interactive API Docs: `http://localhost:8000/docs`

### 2. Run Flutter Android Client
```powershell
# Navigate to mobile directory
cd mobile

# Fetch dependencies
flutter pub get

# Run on Android Emulator (Host maps automatically to 10.0.2.2)
flutter run

# Or run on Desktop (Windows)
flutter run -d windows

# Or run pointing to a physical device on local network
flutter run --dart-define=BACKEND_URL=http://<YOUR_PC_LAN_IP>:8000
```

### 3. Run Automated Tests
```powershell
# Backend Pytest suite
cd backend
pytest -v

# Flutter Unit & Widget tests
cd mobile
flutter test
```

## Documentation

- [System Architecture Specification](docs/ARCHITECTURE.md)
- [Development Rules & Quality Invariants](docs/DEVELOPMENT_RULES.md)
