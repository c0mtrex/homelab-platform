# Service Health API Code Walkthrough

This guide connects the important code to the behavior we observed. Read it beside these source files:

- `docker/service-health-api/src/app.py`
- `docker/service-health-api/Dockerfile`
- `docker/service-health-api/requirements.in`
- `docker/service-health-api/requirements-lock.txt`
- `.github/workflows/publish-service-health-api.yml`
- `kubernetes/staging/service-health-api.yaml`

## 1. Python imports

```python
import json
import logging
import os
import time
import uuid

import httpx
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
```

What these provide:

- `json`: converts Python data into JSON text for structured logs.
- `logging`: writes operational messages.
- `os`: reads environment variables.
- `time`: measures request duration.
- `uuid`: generates unique request IDs.
- `httpx`: calls the dependency over HTTP.
- `FastAPI`: creates the REST API.
- `CORSMiddleware`: controls browser access from other origins.
- `JSONResponse`: lets us choose both JSON content and an HTTP status.
- `prometheus_client`: creates counters, histograms, and `/metrics` output.

## 2. Configuration comes from environment variables

```python
SERVICE_NAME = os.getenv("SERVICE_NAME", "service-health-api")
DEPENDENCY_URL = os.getenv("DEPENDENCY_URL", "http://prometheus:9090/-/healthy")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("REQUEST_TIMEOUT_SECONDS", "3"))
```

The first value is the environment-variable name. The second value is the default.

For example:

```python
os.getenv("REQUEST_TIMEOUT_SECONDS", "3")
```

means:

> Use `REQUEST_TIMEOUT_SECONDS` if it was supplied. Otherwise, use three seconds.

This avoids hard-coding environment-specific values into the image.

## 3. Allowed browser origins

```python
ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv("ALLOWED_ORIGINS", "").split(",")
    if origin.strip()
]
```

This:

1. Reads a comma-separated environment variable.
2. Splits it into separate origins.
3. Removes extra spaces.
4. Ignores empty values.

The Kubernetes manifest currently supplies:

```yaml
- name: ALLOWED_ORIGINS
  value: http://10.10.0.160:3000
```

That allows browser JavaScript served from that exact origin to call this API. CORS is a browser control; it is not a replacement for authentication or firewall rules.

## 4. Structured JSON logging

```python
class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        message = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%SZ"),
            "level": record.levelname.lower(),
            "service": SERVICE_NAME,
            "message": record.getMessage(),
        }
        return json.dumps(message, separators=(",", ":"))
```

The formatter converts each log entry into structured JSON. Machines can search JSON fields more reliably than unstructured sentences.

Example:

```json
{"level":"info","service":"service-health-api","event":"request_completed","status_code":200}
```

## 5. Prometheus metrics

### Request counter

```python
REQUESTS = Counter(
    "service_health_http_requests_total",
    "Total HTTP requests handled by the service-health API.",
    ("method", "path", "status_code"),
)
```

This counts requests and separates them by:

- HTTP method
- API path
- HTTP status code

### Request-duration histogram

```python
REQUEST_DURATION = Histogram(
    "service_health_http_request_duration_seconds",
    "Time spent handling service-health API requests.",
    ("method", "path"),
)
```

The histogram stores requests in duration buckets. Prometheus and Grafana use those buckets to calculate values such as the p95 response time.

### Dependency counter

```python
DEPENDENCY_CHECKS = Counter(
    "service_health_dependency_checks_total",
    "Total dependency checks by result.",
    ("result",),
)
```

This counts dependency results such as `healthy`, `unhealthy`, and `error`.

## 6. Create the FastAPI application

```python
app = FastAPI(
    title="Service Health API",
    description="A small operational API for container and dependency health checks.",
    version="1.0.0",
)
```

FastAPI uses this metadata on the Swagger `/docs` page and in `/openapi.json`.

## 7. Request-observation middleware

```python
@app.middleware("http")
async def observe_request(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    started = time.perf_counter()
    response = await call_next(request)
    duration = time.perf_counter() - started
    response.headers["X-Request-ID"] = request_id
    return response
```

Middleware wraps every HTTP request.

The complete function also:

- Records a start time.
- Runs the requested route with `call_next(request)`.
- Measures the duration.
- Adds an `X-Request-ID` response header.
- Increments Prometheus metrics.
- Writes a structured completion or failure log.

The request ID lets an operator connect the browser response to the matching log entry.

## 8. Dependency check

```python
async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT_SECONDS) as client:
    response = await client.get(DEPENDENCY_URL)

healthy = 200 <= response.status_code < 300
```

This code:

1. Creates an asynchronous HTTP client.
2. Applies a timeout.
3. sends `GET` to the configured dependency.
4. Treats HTTP 200 through 299 as healthy.
5. Records the result as a Prometheus metric.

If the request cannot connect or times out, the `except httpx.HTTPError` block returns an error result instead of crashing the API.

## 9. API routes

### Root route

```python
@app.get("/")
async def root():
    return {
        "service": SERVICE_NAME,
        "message": "Service Health API",
        "documentation": "/docs",
    }
```

### Liveness route

```python
@app.get("/health")
async def health():
    return {"status": "healthy", "service": SERVICE_NAME}
```

This checks the API process itself. It intentionally does not test the external dependency.

### Readiness route

```python
@app.get("/ready")
async def ready():
    healthy, dependency = await check_dependency()
    response_status = status.HTTP_200_OK if healthy else status.HTTP_503_SERVICE_UNAVAILABLE
    return JSONResponse(
        status_code=response_status,
        content={
            "status": "ready" if healthy else "not_ready",
            "service": SERVICE_NAME,
            "dependency": dependency,
        },
    )
```

This tests whether the API is ready to do useful work. Kubernetes removes a Pod from Service traffic if this route repeatedly returns 503.

### Metrics route

```python
@app.get("/metrics", include_in_schema=False)
async def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
```

Prometheus reads this endpoint. It is hidden from Swagger because it is operational output rather than a normal business API operation.

## 10. Dockerfile walkthrough

```dockerfile
FROM python:3.13-slim
```

Start with a smaller Python runtime image.

```dockerfile
WORKDIR /app
COPY requirements-lock.txt .
RUN pip install --no-cache-dir --requirement requirements-lock.txt
```

Set `/app` as the working directory, copy the locked dependency list, and install those exact versions.

```dockerfile
RUN groupadd --system app \
    && useradd --system --gid app --home-dir /app app

COPY --chown=app:app src/ ./src/
USER app
```

Create a non-root account, copy the source code, and run as that restricted user.

```dockerfile
EXPOSE 8000
CMD ["uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

Document port 8000 and start the web server.

## 11. GitHub publishing workflow walkthrough

```yaml
on:
  push:
    branches:
      - main
    paths:
      - docker/service-health-api/**
```

Publish only after relevant application files reach `main`.

```yaml
permissions:
  contents: read
  packages: write
```

The job may read repository contents and publish a GHCR package. It is not given broad repository-administration access.

```yaml
- name: Check out repository
  uses: actions/checkout@v6
```

Place the Git commit that triggered the workflow into the temporary GitHub runner workspace.

```yaml
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v4
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

Authenticate to GHCR with the temporary workflow token.

```yaml
- name: Build and publish image
  uses: docker/build-push-action@v7
  with:
    context: ./docker/service-health-api
    file: ./docker/service-health-api/Dockerfile
    push: true
    tags: ghcr.io/c0mtrex/service-health-api:${{ github.sha }}
```

Build the Dockerfile, tag the image with the exact Git SHA, and push it.

## 12. Kubernetes Deployment walkthrough

```yaml
spec:
  replicas: 2
  revisionHistoryLimit: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
```

- Maintain two replicas.
- Retain three rollout revisions.
- During an update, keep all existing replicas available.
- Temporarily allow one additional Pod while replacing the old version.

```yaml
image: ghcr.io/c0mtrex/service-health-api@sha256:9fb3a2270cd2fce1b7ef8be82ec3e4ec60f1092382ebe11877887352e53a482f
```

Run the exact image identified by its immutable digest.

```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

The container cannot elevate privileges, receives no extra Linux capabilities, and cannot modify its root filesystem.

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 250m
    memory: 256Mi
```

- Requests help Kubernetes schedule the Pod.
- Limits prevent this small API from consuming unlimited node resources.
- `50m` means five percent of one CPU core.
- `64Mi` means 64 mebibytes of memory.

## 13. Probe walkthrough

```yaml
startupProbe:
  httpGet:
    path: /health
    port: http
```

Give the application time to start before normal liveness decisions begin.

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: http
```

Only send Service traffic to a Pod whose dependency check succeeds.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
```

Restart the container if the API process stops responding repeatedly.

Readiness controls **traffic**. Liveness controls **restart**.

## 14. Service walkthrough

```yaml
kind: Service
spec:
  type: ClusterIP
  selector:
    app: service-health-api
  ports:
    - name: http
      port: 8000
      targetPort: http
```

- `ClusterIP` makes an internal stable address.
- The selector finds matching Pods.
- Service port 8000 forwards to the container port named `http`.

Labels and selectors are the connection between the Service and Pods.

## 15. Ingress walkthrough

```yaml
kind: Ingress
spec:
  ingressClassName: traefik
  rules:
    - host: service-health-api.staging.home.arpa
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-health-api
                port:
                  name: http
```

This tells Traefik:

> For any path beginning with `/` on this hostname, forward the request to the Service port named `http`.

The Ingress does not run the Python code. It only routes HTTP traffic to the Service.

## 16. What happens for one `/ready` request

1. The browser asks DNS for `service-health-api.staging.home.arpa`.
2. OPNsense returns `10.10.0.130`.
3. The browser sends `GET /ready` with that hostname.
4. Traefik matches the Ingress host rule.
5. The Ingress forwards to the ClusterIP Service.
6. The Service selects one ready API Pod.
7. Uvicorn receives the HTTP request on port 8000.
8. FastAPI runs the `ready()` function.
9. `httpx` checks Prometheus.
10. The API records metrics and a structured log.
11. The API returns HTTP 200 or 503 with JSON.
12. The response includes `X-Request-ID` for log correlation.

## 17. Interview-sized explanation

> I built a small Python FastAPI service with liveness, readiness, dependency checking, structured logging, request IDs, and Prometheus metrics. I packaged it in a non-root Docker image with locked dependencies and published immutable versions to GHCR through GitHub Actions. I deployed two replicas to K3s using resource limits, security controls, health probes, a ClusterIP Service, and Traefik Ingress. OPNsense DNS maps the staging hostname to the cluster node, allowing normal browser and API access. FastAPI automatically generates Swagger documentation from the declared routes.
