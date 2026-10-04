# PitPulse — Backend Service

FastAPI-powered asynchronous backend API service for the PitPulse healthcare platform.

## Setup & Running Locally

### 1. Activate Python Virtual Environment
```powershell
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
```

### 2. Install Dependencies
```powershell
pip install -r requirements.txt
```

### 3. Environment Configuration
Copy the template configuration:
```powershell
cp .env.example .env
```

### 4. Run the Development Server
```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Once running, the API is available at:
- Root: `http://localhost:8000/`
- Health Endpoint: `http://localhost:8000/health`
- Interactive Swagger Docs: `http://localhost:8000/docs`

### 5. Run Automated Tests
```powershell
pytest -v
```
