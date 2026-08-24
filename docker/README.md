# Docker Platform Configuration

This directory contains declarative configuration reconciled from the running Docker01 platform.

## Projects

- `monitoring/compose.yaml` defines Prometheus, Grafana, Node Exporter, and cAdvisor.
- `portainer/compose.yaml` defines Portainer.

The repository stores configuration only. Runtime state, credentials, Grafana data, Prometheus metrics, and Portainer data are excluded.

## Current-state warning

The imported definitions intentionally match the running platform at the time of inventory. They are not yet the final hardened design:

- Images use mutable `latest` tags.
- Only cAdvisor currently reports a Docker health status.
- Services publish on all host addresses.
- cAdvisor runs privileged and reads broad host paths.
- Portainer has read/write access to the Docker socket.

These findings will be addressed through separate, reviewable changes so current state and desired improvements remain distinguishable.

## Validation

From the repository root, run:

```bash
scripts/validate.sh
```

Validation renders both Compose models and checks the Prometheus configuration without starting the platform services.

## Deployment boundary

These files are not automatically deployed yet. Updating Git does not change Docker01 until an approved deployment or GitOps mechanism is introduced.
