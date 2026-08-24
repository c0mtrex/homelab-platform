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


SERVICE_NAME = os.getenv("SERVICE_NAME", "service-health-api")
DEPENDENCY_URL = os.getenv("DEPENDENCY_URL", "http://prometheus:9090/-/healthy")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("REQUEST_TIMEOUT_SECONDS", "3"))
ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv("ALLOWED_ORIGINS", "").split(",")
    if origin.strip()
]


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        message = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%SZ"),
            "level": record.levelname.lower(),
            "service": SERVICE_NAME,
            "message": record.getMessage(),
        }
        for field in ("event", "request_id", "method", "path", "status_code", "duration_ms"):
            if hasattr(record, field):
                message[field] = getattr(record, field)
        return json.dumps(message, separators=(",", ":"))


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logger = logging.getLogger(SERVICE_NAME)
logger.handlers.clear()
logger.addHandler(handler)
logger.setLevel(logging.INFO)
logger.propagate = False

REQUESTS = Counter(
    "service_health_http_requests_total",
    "Total HTTP requests handled by the service-health API.",
    ("method", "path", "status_code"),
)
REQUEST_DURATION = Histogram(
    "service_health_http_request_duration_seconds",
    "Time spent handling service-health API requests.",
    ("method", "path"),
)
DEPENDENCY_CHECKS = Counter(
    "service_health_dependency_checks_total",
    "Total dependency checks by result.",
    ("result",),
)

app = FastAPI(
    title="Service Health API",
    description="A small operational API for container and dependency health checks.",
    version="1.0.0",
)

if ALLOWED_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=ALLOWED_ORIGINS,
        allow_credentials=False,
        allow_methods=["GET"],
        allow_headers=["*"],
    )


@app.middleware("http")
async def observe_request(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    started = time.perf_counter()

    try:
        response = await call_next(request)
    except Exception:
        duration = time.perf_counter() - started
        logger.exception(
            "Unhandled request failure",
            extra={
                "event": "request_failed",
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status_code": 500,
                "duration_ms": round(duration * 1000, 2),
            },
        )
        REQUESTS.labels(request.method, request.url.path, "500").inc()
        REQUEST_DURATION.labels(request.method, request.url.path).observe(duration)
        raise

    duration = time.perf_counter() - started
    response.headers["X-Request-ID"] = request_id
    REQUESTS.labels(request.method, request.url.path, str(response.status_code)).inc()
    REQUEST_DURATION.labels(request.method, request.url.path).observe(duration)
    logger.info(
        "Request completed",
        extra={
            "event": "request_completed",
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "duration_ms": round(duration * 1000, 2),
        },
    )
    return response


async def check_dependency() -> tuple[bool, dict]:
    started = time.perf_counter()
    try:
        async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT_SECONDS) as client:
            response = await client.get(DEPENDENCY_URL)
        healthy = 200 <= response.status_code < 300
        result = "healthy" if healthy else "unhealthy"
        DEPENDENCY_CHECKS.labels(result).inc()
        return healthy, {
            "status": result,
            "target": DEPENDENCY_URL,
            "statusCode": response.status_code,
            "durationMs": round((time.perf_counter() - started) * 1000, 2),
        }
    except httpx.HTTPError as error:
        DEPENDENCY_CHECKS.labels("error").inc()
        return False, {
            "status": "error",
            "target": DEPENDENCY_URL,
            "error": type(error).__name__,
            "durationMs": round((time.perf_counter() - started) * 1000, 2),
        }


@app.get("/")
async def root():
    return {
        "service": SERVICE_NAME,
        "message": "Service Health API",
        "documentation": "/docs",
    }


@app.get("/health")
async def health():
    return {"status": "healthy", "service": SERVICE_NAME}


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


@app.get("/check")
async def dependency_check():
    healthy, dependency = await check_dependency()
    response_status = status.HTTP_200_OK if healthy else status.HTTP_503_SERVICE_UNAVAILABLE
    return JSONResponse(status_code=response_status, content=dependency)


@app.get("/metrics", include_in_schema=False)
async def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
