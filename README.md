# decenter-sre-task

Solution for the technical task for the SRE interview process at Decenter.

## App

The application source is in the `app/` directory (NestJS).

### Run locally

Prerequisites:

- Node.js `>=20.18.0`
- npm `>=10`

Steps:

```bash
cd app
npm install
npm run start:dev
```

The app starts on `http://localhost:3000` by default.

Useful endpoints:

- `GET /health` - Returns service health status (`ok`) and current timestamp.
- `GET /metrics` - Exposes Prometheus metrics (currently total HTTP request count).

### Run with Docker

Build image from repository root:

```bash
docker build -t decenter-sre-app ./app
```

Run container:

```bash
docker run -d -p 80:3000 --name decenter-sre decenter-sre-app
```

App URL: `http://localhost:80`

Container healthcheck:

- The image has a built-in Docker `HEALTHCHECK` that calls `GET /health` every 30 seconds.
- Check status with `docker ps` (or `docker inspect decenter-sre --format "{{.State.Health.Status}}"`).

Optional custom port:

```bash
docker run --rm -p 8080:8080 -e PORT=8080 --name decenter-sre-app decenter-sre-app
```
