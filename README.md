# SpendWise

SpendWise is a full-stack personal finance mobile app for recording expenses, setting a monthly budget, and understanding spending by category.

The project was built as a portfolio application to demonstrate mobile development, REST API design, authentication, relational data modeling, and cloud deployment.

This app is currently online however it takes a while to load when it hasn't been used for some time.

## Features

- Account registration and JWT-based login
- Password hashing with bcrypt
- Monthly income and budget setup
- Add, edit, and delete expenses
- Delete confirmation to prevent accidental removal
- Dashboard with total spent, remaining income, and budget remaining
- Category-based spending chart
- Red warning state when spending exceeds income or budget
- Pull-to-refresh dashboard
- Android APK build for physical devices

## Technology

### Mobile

- Flutter
- Dart
- Material 3 UI
- `http` REST client

### Backend

- Python 3.12
- FastAPI
- SQLAlchemy
- Pydantic validation
- JWT authentication
- Passlib and bcrypt password hashing

### Data and deployment

- SQLite for local development
- Supabase PostgreSQL for the deployed environment
- Render Web Service for the deployed FastAPI backend
- HTTPS communication between the mobile app and API

## Project structure

```text
SpendWise/
├── backend/
│   ├── app/
│   │   ├── auth.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── main.py
│   │   ├── models.py
│   │   └── schemas.py
│   ├── .env.example
│   ├── requirements.txt
│   └── runtime.txt
├── mobile/
│   ├── lib/main.dart
│   ├── test/
│   └── pubspec.yaml
└── README.md
```

## Run the backend locally

Python 3.12 is recommended for the pinned dependency versions.

```powershell
cd backend
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
copy .env.example .env
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

The local API is available at:

```text
http://127.0.0.1:8000
```

Interactive API documentation is available at:

```text
http://127.0.0.1:8000/docs
```

For local development, the default `.env.example` uses SQLite. To use Supabase locally, replace `DATABASE_URL` with the connection string from Supabase.

## Run the Flutter app

```powershell
cd mobile
flutter pub get
flutter run
```

The app's `apiBaseUrl` in `mobile/lib/main.dart` should point to the local API during local-only development or the deployed Render URL when testing the online app.

For a connected Android phone:

```powershell
flutter devices
flutter run -d YOUR_DEVICE_ID
```

## Test and build

Run the Flutter checks from the `mobile` directory:

```powershell
flutter analyze
flutter test
```

Build a release Android APK:

```powershell
flutter build apk --release
```

The APK is created at:

```text
mobile/build/app/outputs/flutter-apk/app-release.apk
```

## Deployment

The production setup uses Supabase for PostgreSQL and Render for the FastAPI service.

### Render settings

Set the Render service root directory to `backend` and use:

```text
Build command: pip install -r requirements.txt
Start command: uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

Configure these environment variables in Render:

```text
SECRET_KEY=<long-random-secret>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
DATABASE_URL=<Supabase-pooler-connection-string>
PYTHON_VERSION=3.12.10
```

The `.env` file must never be committed to GitHub. Use `.env.example` as a template and keep production secrets in Render's environment settings.

## API overview

| Method | Endpoint | Purpose |
| --- | --- | --- |
| GET | `/` | Health check |
| POST | `/auth/register` | Create an account |
| POST | `/auth/login` | Get a JWT access token |
| GET | `/me` | Get the current user |
| GET | `/dashboard` | Get dashboard totals and expenses |
| PUT | `/budget` | Update the monthly budget |
| GET | `/expenses` | List the user's expenses |
| POST | `/expenses` | Create an expense |
| PUT | `/expenses/{expense_id}` | Update an expense |
| DELETE | `/expenses/{expense_id}` | Delete an expense |

## Portfolio highlights

SpendWise demonstrates:

- Designing and consuming a REST API
- Implementing authentication and protected endpoints
- Connecting a Flutter client to a Python backend
- Modeling users, expenses, and budget data with SQLAlchemy
- Migrating from local SQLite development to hosted PostgreSQL
- Deploying a live backend and testing it from a physical Android device
- Handling validation, loading states, confirmation dialogs, and responsive layout issues
