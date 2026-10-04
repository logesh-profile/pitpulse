# PitPulse — Development Rules & Quality Invariants

This document outlines the 20 non-negotiable development rules governing all code, architecture, testing, and operational workflows for the PitPulse project. Every contributor, pull request, and development stage must strictly adhere to these invariants.

---

## 1. No Hardcoded Application Data
Static labels, localization strings, and layout constants are permitted in code. However, all domain data—such as patient names, clinical encounters, triage scores, prescription histories, doctor rosters, and facility lists—must originate from the active database or legitimate backend API responses.

## 2. No Fake API Responses
Backend endpoints must never return static dummy JSON or mock business responses in production code pathways. Every endpoint must execute real business logic, query the datastore, perform access control checks, and return genuine query results.

## 3. No Fake Authentication
Authentication must be authentic and cryptographically verified. No bypass credentials, hardcoded test tokens, or client-side fake logins ("admin/admin" auto-login shortcuts) are allowed. Passwords must be verified against Argon2id hashes in PostgreSQL.

## 4. No Fake Users
All users (Patients, ASHAs, Doctors, Admins) must be provisioned through formal registration or seed management procedures into the PostgreSQL `users` table with legitimate role bindings and credentials.

## 5. No Fake Healthcare Records
Patient medical histories, prenatal checkups, immunization logs, laboratory values, and clinical notes must be real entities created by authorized users through verified API/offline workflows.

## 6. No Hardcoded Dashboard Statistics
Dashboard metrics (e.g., total registered mothers, high-risk triage count, pending referrals, vaccination completion rate) must be calculated dynamically via database queries or aggregation services reflecting actual stored records.

## 7. No Bypassing Backend Authorization
Client-side role rendering (hiding buttons or tabs) is solely for UI/UX. The backend must independently enforce RBAC and ABAC on every API endpoint. An unauthorized request must return `401 Unauthorized` or `403 Forbidden` regardless of the caller.

## 8. No Plaintext Passwords
Passwords must never be stored, logged, or transmitted in plaintext. Passwords must be hashed using modern algorithms (Argon2id) with unique salts before persisting to the database.

## 9. No Secrets Committed to Git
API keys, JWT secret keys, database passwords, encryption keys, and S3 credentials must never be committed to version control. All configuration must be injected via environment variables (`.env`) with schemas defined in `.env.example`.

## 10. No Medical Diagnosis Claims from AI
The AI subsystem must never claim to provide definitive medical diagnoses. All AI outputs must be framed as risk stratification, educational insights, or screening flags.

## 11. AI Must Be Treated as Decision Support / Education
All AI-generated recommendations and risk levels must explicitly indicate that they require clinical evaluation and sign-off by a qualified healthcare professional.

## 12. Every Stage Must Be Tested
Every architectural milestone and functional stage must include automated tests (unit, integration, or end-to-end) verifying that the newly implemented features satisfy functional and security specifications.

## 13. A Failed Test Must Remain a Failure Until Fixed
Under no circumstances should assertions be commented out, deleted, or altered to force a passing test run. If a test fails, the underlying application code or test setup must be corrected.

## 14. Never Hide Errors with Fallback Mock Data
When an API request fails, network connection drops, or database errors occur, the application must display a descriptive error state to the user or retry through formal offline queues. It must never silently fallback to fake mock data.

## 15. Do Not Mark a Stage Complete Without Verification
A development stage is complete only after all verification criteria, tests, and security checks have been executed and passed. Premature completion claims are prohibited.

## 16. Database Migrations Must Be Version-Controlled
All database schema changes must be managed using version-controlled migration scripts (e.g., Alembic for SQLAlchemy). Manual out-of-band schema alterations are strictly forbidden.

## 17. API Contracts Must Be Explicit
All API endpoints must define explicit Pydantic request and response schemas. Undocumented, generic dictionary endpoints (`dict` / `Any`) are disallowed for core business operations.

## 18. Sensitive Operations Must Be Auditable
Actions involving Protected Health Information (PHI)—including record creation, modifications, access to sensitive clinical notes, and prescription issuance—must generate tamper-evident audit log entries recording the Actor ID, Target ID, Timestamp, Action Type, and IP Address.

## 19. Offline Records Must Have Synchronization State
Every entity stored locally in the mobile SQLite database must maintain explicit sync lifecycle metadata (`sync_status`: `SYNCED`, `PENDING_INSERT`, `PENDING_UPDATE`, `PENDING_DELETE`, along with `client_updated_at` and `server_version`).

## 20. Clinical Records Must Not Be Silently Overwritten
When synchronizing offline edits with the server, concurrent conflict resolution protocols must prevent data loss. Out-of-date writes must be rejected or merged according to clinical integrity policies, and conflicts must be logged for clinical audit.
