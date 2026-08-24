# Service Health API

This learning service demonstrates a production-style Python API packaged as a container.

## Endpoints

- `GET /` describes the service.
- `GET /health` proves that the API process is alive.
- `GET /ready` proves that the API and its configured dependency are ready.
- `GET /check` returns details about the configured dependency.
- `GET /metrics` exposes Prometheus metrics.
- `GET /docs` opens FastAPI's interactive OpenAPI documentation.

The dependency is configured through `DEPENDENCY_URL`. The Compose configuration checks the
Prometheus instance on `docker01` by default.
