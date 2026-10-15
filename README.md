# SpendWise

A personal spending tracker app built with a Python FastAPI backend and a Flutter mobile frontend.

## Tech stack

- Python + FastAPI
- SQLite for local development
- Flutter + Dart
- JWT auth
- REST API for mobile integration

## Project structure

- `backend/` — Python API server
- `mobile/` — Flutter app

## Backend setup

Use Python 3.12 for the backend to avoid compatibility issues with the current dependency set.

```bash
cd backend
py -3.12 -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
copy .env.example .env
.venv\Scripts\python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Mobile setup

```bash
cd mobile
flutter pub get
flutter run
```

The Flutter app is configured to talk to the API at `http://10.0.2.2:8000` for Android emulators.

## Features included in the MVP

- User registration and login
- User profile information
- Monthly income setup
- Add expenses
- Delete expenses
- Dashboard summary
- Database-backed API

## Next upgrades

- Edit expense flow
- Chart analytics
- Budget limits
- Online PostgreSQL
- Deployment to Render, Railway, or similar
