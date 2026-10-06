# Zapfen

A social app for sharing a drink with friends: post a photo of what you're
having, see where your friends are drinking on a map, collect achievements, and
compete on leaderboards.

## Repository layout

| Path | What it is |
| --- | --- |
| `beerreal/` | The Flutter app (iOS, Android), including a home-screen widget extension |
| `backend/` | Express + MongoDB API server |
| `backend/admin-panel/` | React admin dashboard, served by the backend at `/admin` |
| `websiteserver/` | Static marketing site and legal pages |
| `docker-compose.yml` | Backend + MongoDB for local development |
| `prometheus.yml`, `grafana/` | Metrics and dashboards |

## Getting started

### Backend

```bash
cd backend
cp .env.example .env     # then fill in the values
npm install
npm start                # also builds the admin panel
```

Two files are required but intentionally not in the repo, since both hold
credentials:

- `backend/.env` — see `backend/.env.example` for the full list of variables.
- `backend/serviceAccountKey.json` — a Firebase service account key, used for
  push notifications. Generate one in the Firebase console under
  *Project settings → Service accounts*.

For a local database, `docker compose up mongodb` starts MongoDB with the
credentials already referenced in `.env.example`.

### App

```bash
cd beerreal
flutter pub get
flutter run
```

The app talks to `api.zapfenapp.de` by default. To point it at a local backend:

```bash
flutter run --dart-define=API_HOST=192.168.1.10 --dart-define=API_SCHEME=http --dart-define=API_PORT=3000
```

Map tiles come from [CARTO](https://carto.com/basemaps/apikey), which requires a
free API key. Without one the map renders with an "API KEY REQUIRED" watermark.
Set the key in `_cartoApiKey` at the top of `lib/screens/map_screen.dart`.

## Tech stack

**App:** Flutter, Provider, flutter_map, Firebase Messaging
**Backend:** Node.js, Express 5, Mongoose, JWT auth, Firebase Admin
**Storage:** Cloudflare R2 for images, Resend for transactional email
**Ops:** Docker Compose, Prometheus, Grafana
