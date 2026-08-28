# Service Health API: From Python Code to a Website

## What we built

We built a Python REST API, packaged it as a container image, ran two copies in K3s, and made it reachable through a normal DNS name:

```text
http://service-health-api.staging.home.arpa/docs
```

The `/docs` page is Swagger UI. FastAPI generated it automatically from the API routes declared in Python. We did not manually write that HTML page.

## Complete request flow

```text
Browser or curl
    |
    | 1. Resolve service-health-api.staging.home.arpa
    v
OPNsense / Unbound DNS
    |
    | 2. Return 10.10.0.130
    v
k801 and Traefik Ingress
    |
    | 3. Match the requested hostname
    v
Kubernetes ClusterIP Service
    |
    | 4. Select a ready API Pod
    v
Uvicorn web server on port 8000
    |
    | 5. Send the request to FastAPI
    v
Python route such as /health, /ready, /metrics, or /docs
```

## Step-by-step explanation

### 1. Python defines the API

`docker/service-health-api/src/app.py` creates the FastAPI application:

```python
app = FastAPI(
    title="Service Health API",
    description="A small operational API for container and dependency health checks.",
    version="1.0.0",
)
```

A route tells FastAPI what to do when a request arrives:

```python
@app.get("/health")
async def health():
    return {"status": "healthy", "service": SERVICE_NAME}
```

In simple terms:

- `@app.get("/health")` listens for an HTTP `GET /health` request.
- `health()` is the function that runs.
- The Python dictionary is converted into JSON automatically.
- FastAPI inspects these routes and automatically creates `/docs`.

### 2. Uvicorn makes the Python code listen for HTTP requests

The Dockerfile starts Uvicorn with:

```dockerfile
CMD ["uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

- `uvicorn` is the web server.
- `src.app` means load `src/app.py`.
- The second `app` means use the `app = FastAPI(...)` object.
- `0.0.0.0` accepts connections arriving through the container network.
- `8000` is the port inside the container.

### 3. Docker packages the application

The Dockerfile combines:

- Python 3.13
- Locked Python package versions
- The application source code
- A non-root runtime user
- The Uvicorn startup command

That produces one portable container image.

### 4. GitHub Actions publishes the image

The publishing workflow:

1. Checks out the repository.
2. Logs in to GitHub Container Registry using `GITHUB_TOKEN`.
3. Builds the Dockerfile.
4. Tags the image with the Git commit SHA.
5. Pushes the image to GHCR.
6. Records the immutable image digest.

The image repository is:

```text
ghcr.io/c0mtrex/service-health-api
```

The staging deployment currently uses this exact digest:

```text
sha256:9fb3a2270cd2fce1b7ef8be82ec3e4ec60f1092382ebe11877887352e53a482f
```

A tag identifies the source version. A digest identifies the exact image bytes and cannot be moved to another image.

### 5. The K3s Deployment runs two replicas

The Kubernetes Deployment says:

```yaml
kind: Deployment
spec:
  replicas: 2
```

K3s therefore maintains two running copies of the API. If a Pod disappears, the Deployment creates a replacement.

K3s uses its own `containerd` runtime to run these Pods. It does not ask the normal Docker daemon to run them.

### 6. Kubernetes probes test the application

- `startupProbe` asks whether the program has finished starting.
- `readinessProbe` asks whether the program and its dependency are ready for traffic.
- `livenessProbe` asks whether the program is still alive.

The Service only sends normal traffic to ready Pods.

### 7. The Service provides one stable internal destination

Pod names and IP addresses can change. The ClusterIP Service finds Pods carrying this label:

```yaml
selector:
  app: service-health-api
```

It provides one stable destination in front of both replicas:

```text
Kubernetes Service
    +--> ready Pod 1
    +--> ready Pod 2
```

### 8. Traefik Ingress exposes the Service

The Ingress rule says:

```yaml
ingressClassName: traefik
rules:
  - host: service-health-api.staging.home.arpa
```

When Traefik sees that hostname, it forwards the request to the `service-health-api` Service on port 8000.

### 9. OPNsense DNS provides the name

The Unbound host override maps:

```text
service-health-api.staging.home.arpa -> 10.10.0.130
```

The address `10.10.0.130` belongs to k801, where Traefik receives the HTTP request.

### 10. FastAPI supplies the visible page

When the browser requests `/docs`, FastAPI returns Swagger UI. Swagger reads the generated OpenAPI description and displays the available API endpoints as an interactive website.

## Available endpoints

| Path | Purpose | Normal result |
|---|---|---|
| `/` | Basic API information | HTTP 200 and JSON |
| `/health` | Is this API process alive? | HTTP 200 |
| `/ready` | Is the API ready, including its dependency? | HTTP 200 or HTTP 503 |
| `/check` | Run an explicit dependency check | HTTP 200 or HTTP 503 |
| `/metrics` | Prometheus measurements | Prometheus text format |
| `/docs` | Interactive Swagger website | HTML page |
| `/openapi.json` | Machine-readable API definition | JSON document |

## Kubernetes and API cheat sheet

Run these commands on **k801**.

### See what is running

```bash
sudo k3s kubectl get deployment,replicaset,pods,service,ingress \
  --namespace staging \
  --output wide
```

### Watch a rollout

```bash
sudo k3s kubectl rollout status \
  deployment/service-health-api \
  --namespace staging
```

### See the Pods selected by the application label

```bash
sudo k3s kubectl get pods \
  --namespace staging \
  --selector app=service-health-api \
  --output wide
```

### Read application logs

```bash
sudo k3s kubectl logs \
  --namespace staging \
  --selector app=service-health-api \
  --tail 50 \
  --prefix
```

### Describe a Pod when it is not healthy

```bash
sudo k3s kubectl describe pod \
  --namespace staging \
  POD_NAME
```

Look at the `Events` section near the bottom.

### Test the API through DNS and Ingress

```bash
curl --include \
  http://service-health-api.staging.home.arpa/health

curl --include \
  http://service-health-api.staging.home.arpa/ready
```

### Verify DNS directly

```bash
dig @10.10.0.1 \
  service-health-api.staging.home.arpa \
  A \
  +noall \
  +answer
```

Expected address:

```text
10.10.0.130
```

### Bypass normal DNS for troubleshooting

```bash
curl --include \
  --resolve service-health-api.staging.home.arpa:80:10.10.0.130 \
  http://service-health-api.staging.home.arpa/health
```

If this works while the normal URL fails, investigate DNS rather than the application.

### Temporarily bypass Ingress

```bash
sudo k3s kubectl port-forward \
  --namespace staging \
  service/service-health-api \
  8084:8000
```

In a second terminal:

```bash
curl --include http://127.0.0.1:8084/health
```

If port-forwarding works but Ingress does not, investigate the Ingress rule or Traefik.

### Validate before applying

```bash
sudo k3s kubectl apply \
  --dry-run=client \
  --filename kubernetes/staging/service-health-api.yaml

sudo k3s kubectl apply \
  --dry-run=server \
  --filename kubernetes/staging/service-health-api.yaml
```

### Apply the declared configuration

```bash
sudo k3s kubectl apply \
  --filename kubernetes/staging/service-health-api.yaml
```

## Quick troubleshooting order

Work from the outside toward the application:

1. **DNS:** Does the hostname resolve to `10.10.0.130`?
2. **Ingress:** Does Traefik have the correct hostname rule?
3. **Service:** Does the Service have endpoints?
4. **Readiness:** Are both Pods marked `Ready`?
5. **Logs:** What did the Python application report?
6. **Dependency:** Can the API reach Prometheus at `10.0.0.30:9090`?

Useful command for Service endpoints:

```bash
sudo k3s kubectl get endpointslice \
  --namespace staging \
  --selector kubernetes.io/service-name=service-health-api \
  --output wide
```

## Common HTTP status codes

| Code | Simple meaning | Likely interpretation here |
|---|---|---|
| `200` | Request succeeded | API or dependency is healthy |
| `404` | Path was not found | Wrong endpoint or Ingress path |
| `503` | Service unavailable | Readiness or dependency check failed |
| `500` | Application error | Inspect Python logs and request ID |
| `502` | Bad gateway | Ingress reached an unhealthy/missing backend |
| `504` | Gateway timeout | Backend or dependency took too long |

## Vocabulary cheat sheet

| Term | Plain-language meaning |
|---|---|
| API | A defined way for programs to request data or actions |
| REST | A common HTTP style using paths and methods such as GET and POST |
| Endpoint | One API address, such as `/health` |
| FastAPI | The Python framework defining our routes |
| Uvicorn | The web server running the FastAPI application |
| OpenAPI | A machine-readable description of the API |
| Swagger UI | The website FastAPI generates from OpenAPI |
| Container image | Packaged application, libraries, and startup instructions |
| GHCR | GitHub Container Registry, where the image is stored |
| Tag | A movable image name, often tied to a Git SHA |
| Digest | An immutable identifier for the exact image contents |
| Pod | Kubernetes' running unit containing one or more containers |
| Deployment | Controller that maintains the requested number of Pods |
| Replica | One copy of the application Pod |
| Probe | Kubernetes health test sent to the container |
| Service | Stable internal address and traffic distributor for Pods |
| ClusterIP | A Service reachable inside the Kubernetes cluster |
| Ingress | HTTP routing rules that expose Services by hostname or path |
| Traefik | The Ingress controller enforcing our HTTP routing rule |
| DNS | Translates a hostname into an IP address |
| CORS | Browser rule controlling which websites may call an API |
| JSON | Text format used by the API for structured responses |
| Metric | Numeric measurement that Prometheus can collect |

## Monitoring-site possibilities

The API is a data source, not a complete monitoring dashboard by itself.

- Prometheus collects `/metrics`.
- Grafana displays those metrics as panels and dashboards.
- A custom frontend could call `/health`, `/ready`, and `/check`.
- Swagger `/docs` is primarily for developers and troubleshooting.
- Kubernetes keeps the API replicas available while DNS and Ingress make them reachable.
