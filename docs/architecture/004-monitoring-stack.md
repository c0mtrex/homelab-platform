# 004 — Monitoring and Observability Stack

## Purpose

The observability platform runs independently on Docker01 so it can retain visibility when a workload on K801 fails. The current implementation collects infrastructure and container metrics; logs, traces, and alert routing remain planned work.

## Deployment layout

```text
Docker01
├── monitoring Compose project
│   ├── Prometheus
│   ├── Grafana
│   ├── Node Exporter
│   └── cAdvisor
└── docker Compose project
    └── Portainer
```

Configuration locations:

- `/opt/docker/monitoring/compose.yaml`
- `/opt/docker/compose.yaml`

The sanitized configuration will be reconciled into this repository in a separate change.

## Verified services

| Component | Responsibility | Port | Network | Restart policy | Health check |
|---|---|---:|---|---|---|
| Grafana | Dashboards and metric visualization | 3000 | `monitoring_default` | `unless-stopped` | Not defined |
| Prometheus | Metric scraping, storage, and queries | 9090 | `monitoring_default` | `unless-stopped` | Not defined |
| cAdvisor | Docker container resource metrics | 8080 | `monitoring_default` | `unless-stopped` | Defined and healthy |
| Node Exporter | Linux host metrics | 9100 | Host network | `unless-stopped` | Not defined |
| Portainer | Docker administration | 8000, 9000, 9443 | `docker_default` | `unless-stopped` | Not defined |

All five containers had been continuously running for ten days at the time of inventory.

## Data flow

```text
Docker01 host -> Node Exporter --+
                                |
Docker containers -> cAdvisor --+-> Prometheus -> Grafana

Future Kubernetes metrics ------+
```

Prometheus pulls metrics from configured targets. Grafana queries Prometheus and displays the results; Grafana does not collect host metrics directly.

## Persistence

- Grafana stores state in `/opt/docker/monitoring/grafana/data`.
- Prometheus stores metrics in the `monitoring_prometheus-data` named volume.
- Prometheus reads its configuration from a read-only bind mount.
- Portainer stores state in `/opt/docker/data`.
- cAdvisor and Node Exporter use read-only host mounts to observe system and container behavior.

## Operational findings

### Strengths

- Monitoring is separated from the future Kubernetes workload host.
- All containers use an automatic `unless-stopped` restart policy.
- Prometheus metrics and management state survive container replacement.
- cAdvisor reports a healthy Docker health status.
- Compose labels trace each running container to its project and working directory.

### Gaps

- Images currently use mutable `latest` tags.
- Four services lack container health checks.
- UFW is inactive on Docker01.
- Published services listen on all IPv4 and IPv6 interfaces.
- Alertmanager, centralized logging, and traces are not installed.
- Backup and restore of monitoring state have not yet been demonstrated.

These gaps are recorded as future engineering work rather than silently described as completed capabilities.

## Security considerations

- Portainer has read/write access to `/var/run/docker.sock`, which is effectively host-administrative access.
- cAdvisor and Node Exporter can observe broad host information even though their host filesystem mounts are read-only.
- Prometheus and exporter endpoints reveal operational data and should be restricted to intended sources.
- Network reachability does not prove authentication or application health.
- IPv6 rules must be validated independently rather than relying on IPv4 NAT assumptions.

## Kubernetes integration plan

After the cluster is available:

1. Expose only the metric endpoints Prometheus requires.
2. Document the Docker01-to-K801 scrape direction and ports.
3. Add Kubernetes cluster-state and node metrics.
4. Add application metrics and labels that identify service and environment.
5. Create Grafana dashboards for availability, latency, errors, and resource saturation.
6. Define one meaningful service-level indicator and objective.
7. Trigger a controlled failure and verify the metric and dashboard response.

## Terminology

- **Metric:** A numeric measurement over time.
- **Log:** A record of a discrete event.
- **Trace:** The path of a request across components.
- **Health check:** A test used to determine whether an application is behaving as expected.
- **Alert:** A notification for a condition requiring human or automated action.
- **SLI:** A measured indicator of service behavior.
- **SLO:** The reliability target applied to an SLI.
