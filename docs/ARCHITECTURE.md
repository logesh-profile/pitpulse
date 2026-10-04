# PitPulse — System Architecture Specification

## 1. Product Overview

PitPulse is a production-grade Android healthcare system engineered to bridge primary, community, and tertiary healthcare delivery. It caters to resource-constrained environments by supporting offline-first workflows for community health workers (ASHAs) while providing unified, secure access for patients, physicians, and system administrators.

The platform combines an Android client (built with Flutter) with a high-performance backend (FastAPI), a persistent relational datastore (PostgreSQL), an embedded local database (SQLite), and S3-compatible object storage.

---

## 2. Role & Authorization Model

PitPulse provides four distinct role-based experiences within a single client binary, secured by server-side Role-Based Access Control (RBAC) and Attribute-Based Access Control (ABAC):

```
+-------------------------------------------------------------------------+
|                                ROLES                                    |
+-------------------+-------------------+-----------------+---------------+
|      PATIENT      |       ASHA        |     DOCTOR      |     ADMIN     |
+-------------------+-------------------+-----------------+---------------+
| - Personal Health | - Household census| - Clinical OPD  | - User & Role |
|   Record (PHR)    | - Maternal/Child  |   queue         |   management  |
| - Appointment     |   tracking        | - Prescriptions | - Facility    |
|   booking         | - Immunization    | - Risk review   |   registry    |
| - Symptom check   | - Field risk triage - Teleconsult   | - Audit logs  |
| - Emergency alert | - Offline sync    | - Referrals     | - Aggregates  |
+-------------------+-------------------+-----------------+---------------+
```

### Role Security Principles:
- **Server-Authoritative**: Frontend route guards and visibility controls are strictly for user experience. All business operations and data access are verified on the backend.
- **Data Isolation**: A patient can only access their own records. An ASHA can access records for households in their assigned catchment area. A doctor can access assigned/referred patients. Admins do not have direct unlogged clinical record access.
- **No ID Insecurity**: Indirect reference or explicit server-side ownership verification prevents Insecure Direct Object Reference (IDOR) vulnerabilities.

---

## 3. Flutter Client Architecture

The mobile application follows Clean Architecture principles with separation into Presentation, Domain, Data, and Device layers.

```
+-------------------------------------------------------------------------+
|                         FLUTTER CLIENT LAYERS                           |
+-------------------------------------------------------------------------+
|  Presentation Layer: UI Widgets, Bloc/Notifier State, Local ViewModels  |
+-------------------------------------------------------------------------+
|  Domain Layer: Entities, Use Cases, Business Invariants, Repositories   |
+-------------------------------------------------------------------------+
|  Data Layer: Repository Impls, SQLite DAO, Sync Queue, Remote API Client|
+-------------------------------------------------------------------------+
|  Device Layer: Camera, GPS, Microphone, Biometric Auth, Secure Storage  |
+-------------------------------------------------------------------------+
```

### Client Responsibilities:
- Presentation and user interaction handling.
- Input validation prior to submission.
- Secure storage of JWT credentials via Android Keystore / Flutter Secure Storage.
- Local data caching and offline queue management using SQLite.
- Hardware abstraction (Camera for OCR/vitals, GPS for field visit tagging, Microphone for voice notes).
- Network state monitoring and background synchronization triggering.

---

## 4. FastAPI Backend Architecture

The backend is built with FastAPI (Python) using asynchronous request processing (`async`/`await`), Pydantic for request/response serialization and validation, and SQLAlchemy (Async) for database interactions.

```
+-------------------------------------------------------------------------+
|                         FASTAPI BACKEND ARCHITECTURE                    |
+-------------------------------------------------------------------------+
|  API Layer: FastAPI Routers, Route Guards, Request/Response Schemas     |
+-------------------------------------------------------------------------+
|  Middleware: CORS, Request Tracing, Rate Limiting, Audit Logging        |
+-------------------------------------------------------------------------+
|  Auth Layer: JWT Validation, Role Extraction, Token Rotation Handlers   |
+-------------------------------------------------------------------------+
|  Service Layer: Core Healthcare Workflows, Risk Scoring, Sync Engine    |
+-------------------------------------------------------------------------+
|  Data Access Layer: SQLAlchemy 2.0 Async Repositories, Migrations       |
+-------------------------------------------------------------------------+
```

### Backend Responsibilities:
- Authenticating every incoming request via cryptographic token validation.
- Enforcing domain rules, RBAC/ABAC access permissions, and data constraints.
- Managing database transactions and ACID guarantees.
- Processing synchronization batches and resolving data conflicts.
- Serving pre-signed URLs for secure direct-to-S3 media uploads/downloads.
- Maintaining append-only security and audit logs.

---

## 5. PostgreSQL Architecture

PostgreSQL serves as the primary relational database of record.

### Key Schema Areas:
- **Identity & Access**: `users`, `roles`, `permissions`, `refresh_tokens`, `audit_logs`.
- **Demographics & Geography**: `facilities`, `catchment_areas`, `households`, `citizens`.
- **Maternal & Child Health**: `pregnancies`, `anc_visits`, `deliveries`, `immunizations`, `growth_records`.
- **Clinical & Telehealth**: `encounters`, `prescriptions`, `diagnoses`, `referrals`, `lab_reports`.
- **AI & Screening**: `risk_assessments`, `ai_inferences`, `screening_feedback`.
- **Sync & Audit**: `sync_revisions`, `tombstones`, `audit_events`.

### Database Responsibilities:
- Guaranteeing relational integrity through foreign keys and check constraints.
- Managing concurrent writes using optimistic locking (`version` columns) and row-level locks where necessary.
- Indexing query pathways (B-Trees on foreign keys, GIN on JSONB clinical payloads, GiST on geographic coordinates).
- Ensuring point-in-time recovery and transactional persistence.

---

## 6. SQLite & Offline Architecture

The local mobile database mirrors a subset of PostgreSQL schemas necessary for offline workflows (especially for ASHA field duties).

```
+-------------------------------------------------------------------+
|                        MOBILE OFFLINE STORE                       |
+-------------------------------------------------------------------+
|  Local Tables: cached_patients, cached_visits, pending_sync_queue |
|  Sync State Flags: 'SYNCED', 'PENDING_INSERT', 'PENDING_UPDATE'   |
|  Local ID Mapping: Temporary UUID (Client) <-> Permanent UUID (Server)|
+-------------------------------------------------------------------+
```

### Offline Data Lifecycle:
1. **Local Mutation**: When an ASHA registers a patient or logs a visit offline, the record is saved to SQLite with a generated client UUID and status `PENDING_INSERT`.
2. **Queue Insertion**: An entry is created in `pending_sync_queue` containing the entity type, client UUID, operation, payload, and client timestamp.
3. **Optimistic Display**: The UI immediately reflects the changes to the field worker.
4. **Flush on Connectivity**: Once online, the Sync Engine flushes the queue sequentially.

---

## 7. Authentication Architecture

PitPulse employs stateless JWT access tokens combined with database-backed refresh token rotation.

```
Client                             FastAPI Backend                  PostgreSQL
  |                                      |                              |
  |--- POST /api/v1/auth/login --------->|                              |
  |    (username, password)              |--- Verify Argon2id hash ---->|
  |                                      |<-- User & Role verified -----|
  |                                      |--- Issue Access Token (30m)  |
  |                                      |--- Store Refresh Token ----->|
  |<-- {accessToken, refreshToken} ------|                              |
  |                                      |                              |
  |--- (Later) POST /api/v1/auth/refresh>|                              |
  |    (refreshToken)                    |--- Validate & Rotate Token ->|
  |<-- {newAccessToken, newRefreshToken}-|                              |
```

- **Access Token**: Short-lived (30 minutes), carries User ID, Role, and Session ID in signed JWT payload.
- **Refresh Token**: Long-lived (7 days), stored securely in mobile Keystore and tracked in the backend database for instantaneous revocation.
- **Rotation**: Every refresh request invalidates the previous refresh token and issues a new pair to mitigate replay attacks.

---

## 8. Authorization Architecture

Authorization enforces strict least-privilege principles at the service and route handler level:

```python
# Conceptual Authorization Guard
@router.get("/patients/{patient_id}/records")
async def get_patient_records(
    patient_id: UUID,
    current_user: User = Depends(get_current_active_user),
    auth_service: AuthService = Depends()
):
    # Verifies user role + ownership/assigned catchment
    await auth_service.authorize_patient_access(current_user, patient_id)
    ...
```

- **Patient**: `patient_id == current_user.patient_id`
- **ASHA**: `patient.catchment_area_id IN current_user.assigned_catchments`
- **Doctor**: `patient.assigned_doctor_id == current_user.id OR patient.active_referral_to == current_user.facility_id`
- **Admin**: System-level administrative actions only.

---

## 9. Synchronization Architecture

Bidirectional sync protocol ensuring consistency across distributed mobile clients:

```
[Mobile SQLite Queue] 
        | (Upload Batch: POST /api/v1/sync/push)
        v
[FastAPI Sync Engine] ---> [PostgreSQL (Server Version & Conflict Check)]
        | (Acknowledge & ID Resolution)
        v
[Mobile Local Database]
        | (Download Updates: GET /api/v1/sync/pull?since_version=X)
        v
[FastAPI Sync Engine] ---> [PostgreSQL (Fetch delta changes)]
```

### Conflict Resolution Strategy:
- **Field Insertions**: Client-generated UUIDs prevent primary key collisions.
- **Field Updates**: Server-side version vector comparison. If server version > client baseline version:
  - Non-overlapping fields are merged.
  - Critical clinical conflict (e.g. incompatible status) triggers server-priority with notification logged for manual review.
- **Idempotency**: All push operations provide an `idempotency_key` to avoid duplicate processing on network retries.

---

## 10. AI Architecture & Decision Support

The AI engine provides explainable, risk-stratified decision support rather than definitive clinical diagnoses.

```
+---------------------------------------------------------------------+
|                          AI SYSTEM SCOPE                            |
+---------------------------------------------------------------------+
| 1. Explainable Maternal High-Risk Stratification (Gestational triage)|
| 2. Pediatric Growth & Malnutrition Alert Screening                  |
| 3. Symptom-based Triage Prioritization for Teleconsultation        |
| 4. Future Edge Inference: Local OCR for immunization cards & vitals |
+---------------------------------------------------------------------+
```

### Safety & Clinical Principles:
- **Decision Support Only**: All outputs are explicitly flagged as decision support / educational guidance, requiring clinician verification.
- **Explainability**: Every risk score returns associated contributing factors (e.g. "Elevated risk due to BP > 140/90 and gestational age 34 weeks").
- **Auditability**: Inferences and inputs are logged with timestamps for retrospective validation.

---

## 11. File Storage Architecture

Storage for medical imaging, ultrasound scans, lab reports, and voice memos uses S3-compatible Object Storage (MinIO in development, AWS S3 / Cloud Object Storage in production).

- **Direct Upload via Pre-signed URLs**: Clients request an upload grant from FastAPI, which validates authorization and issues a short-lived pre-signed PUT URL.
- **Metadata Persistence**: The file path, MIME type, cryptographic checksum (SHA-256), and ownership metadata are stored in PostgreSQL.
- **Encrypted Transfer**: All media transfer occurs over HTTPS with restrictive bucket ACLs (no public read).

---

## 12. Security & Compliance Architecture

- **Data in Transit**: Enforced TLS 1.3 encryption across all client-to-backend and backend-to-storage traffic.
- **Data at Rest**: Database volume encryption, S3 server-side encryption (SSE-S3/SSE-KMS), and encrypted SQLite on mobile.
- **Credential Storage**: Passwords hashed with Argon2id; mobile tokens stored in Android Keystore / EncryptedSharedPreferences.
- **Audit Trails**: Every sensitive read/write (e.g. viewing patient PHI, issuing prescriptions) generates an immutable entry in the `audit_logs` table.
- **Input Sanitization**: Pydantic models validate data shapes, ranges, and types to protect against injection attacks.

---

## 13. Notification & Alerting Architecture (Future)

- **Push Notifications**: Firebase Cloud Messaging (FCM) for real-time appointment reminders, triage alerts, and teleconsultation calls.
- **Local Alarms**: On-device alarms scheduled for ASHA daily home visit rosters and patient medication compliance.
- **Emergency Escalation**: Backend triggers automated SMS/voice alerts for high-risk maternal distress or critical triage flags.

---

## 14. Architecture Responsibility Matrix

| Domain / Function | Mobile Client | FastAPI Backend | PostgreSQL Database | Device Hardware |
| :--- | :--- | :--- | :--- | :--- |
| **User Authentication** | Stores JWT in secure vault | Issues & validates JWTs | Stores user credentials & hashes | Biometric prompt (Fingerprint/Face) |
| **Authorization Checks** | UI adaptation only | Enforces RBAC/ABAC rules | Foreign key constraints | N/A |
| **Data Validation** | Form/UI constraints | Schema & domain validation | Type & constraint checks | N/A |
| **Offline Storage** | SQLite persistence | N/A | N/A | Local flash storage |
| **Sync Engine** | Queue dispatch & tracking | Conflict resolution & merge | Authoritative version store | Network status listener |
| **Media Capture** | Image/Voice capture | Issues Pre-signed URLs | Metadata indexing | Camera & Microphone hardware |
| **Location Tagging** | Coordinates acquisition | Validates catchment bounds | PostGIS spatial queries | GPS sensor hardware |
| **Clinical Decision AI** | Visualizes explainable risk| Runs risk screening models | Logs inference results | Local lightweight ONNX (future) |
| **Audit Logging** | Client event telemetry | Generates audit log records | Persists immutable audit logs| N/A |
