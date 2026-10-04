# PitPulse

PitPulse is a production-oriented Android healthcare application designed to streamline healthcare delivery, patient monitoring, risk screening, and clinical field workflows with offline-first support.

## Product Overview

PitPulse provides four dedicated, role-based experiences within a single unified Flutter Android application:
1. **Patient**: Health record tracking, symptom check, appointments, emergency alerts, and educational guidance.
2. **ASHA (Accredited Social Health Activist)**: Offline-first field data collection, maternal & child tracking, immunization logging, and village-level triage.
3. **Doctor**: Clinical consultation, digital prescriptions, patient risk screening review, and referral management.
4. **Admin**: Role and user provisioning, facility management, audit log inspection, and aggregate operational oversight.

## Core Architecture Stack

- **Mobile Frontend**: Flutter (Dart) — Android-first architecture with SQLite offline store, background synchronization queue, and secure local token vault.
- **Backend API**: FastAPI (Python) — Asynchronous RESTful API with strict JWT authentication, role-based access control (RBAC), and transactional integrity.
- **Primary Database**: PostgreSQL — Relational database enforcing ACID guarantees, audit logs, and clinical schemas.
- **Local Mobile Database**: SQLite — Client-side encrypted store for offline caching and bidirectional mutation queue.
- **Storage**: S3-compatible Object Storage for clinical attachments and imaging.
- **AI Engine**: Explainable clinical risk screening, decision support, and on-device assistance.

## Project Structure

```text
pitpulse/
├── mobile/       # Flutter Android client application
├── backend/      # FastAPI Python backend application
├── docs/         # Architectural blueprints, specifications & development rules
│   ├── ARCHITECTURE.md
│   └── DEVELOPMENT_RULES.md
├── .env.example  # Environment variable template
├── .gitignore    # Comprehensive ignore rules
└── README.md     # Project documentation
```

## Documentation

- [System Architecture Specification](docs/ARCHITECTURE.md)
- [Development Rules & Quality Invariants](docs/DEVELOPMENT_RULES.md)
