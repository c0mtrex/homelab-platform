# 003 — Storage and Recovery Design

## Overview

Storage is separated by responsibility so source code, virtual machines, application data, backups, and disposable container layers are not treated as equivalent.

## Storage layers

### Proxmox storage

- Stores virtual-machine disks and platform data.
- Proxmox snapshots provide short-term recovery points before controlled lab changes.
- A snapshot is not a replacement for an independent backup because it shares the platform's failure domain.

### QNAP NAS

The QNAP provides network storage for:

- Git working copies and repository replicas
- Architecture and interview documentation
- Proxmox backup targets
- Configuration archives
- Operating-system installation media

K801 mounts the Git share at `/mnt/qnap-git` using SMB/CIFS. Credentials and mount secrets are not stored in this public repository.

### Local Git working copies

Active development occurs on local VM storage for predictable filesystem behavior and performance. GitHub is the remote collaboration copy, while QNAP provides an additional local-network copy.

The homelab therefore uses three locations for important Git history:

1. Local working clone
2. GitHub remote repository
3. QNAP copy or replica

Successful synchronization must be verified; the presence of three directories alone does not prove three valid recoverable copies.

### Docker01 persistent data

| Service | Storage | Purpose |
|---|---|---|
| Grafana | `/opt/docker/monitoring/grafana/data` | Dashboards, users, and Grafana state |
| Prometheus | `monitoring_prometheus-data` volume | Time-series metrics |
| Prometheus | `/opt/docker/monitoring/prometheus/prometheus.yml` | Read-only scrape configuration inside the container |
| Portainer | `/opt/docker/data` | Portainer configuration and state |

The Docker Compose files recreate containers but do not, by themselves, restore these data locations.

### K801 demonstration storage

The `web02` Nginx demonstration container bind-mounts `/opt/docker-demo/data` to `/usr/share/nginx/html`. This showed how a bind mount replaces the image's original directory contents and why a missing `index.html` produced an HTTP 403 while Nginx remained reachable.

## Recovery concepts

- **Backup:** An independent copy used to restore data or systems.
- **Snapshot:** A point-in-time state useful for rapid rollback, usually within the same platform.
- **Replication:** A maintained copy in another location or system.
- **High availability:** A design intended to keep service available during component failure.
- **RTO:** Recovery Time Objective, or how quickly service must return.
- **RPO:** Recovery Point Objective, or how much data loss is acceptable.

Backups protect recoverability; redundancy and failover protect availability.

## Recovery workflow

Before a material platform change:

1. Confirm the authoritative configuration is committed.
2. Identify persistent state and dependencies.
3. Take an appropriate Proxmox snapshot when rapid rollback is valuable.
4. Confirm an independent backup exists for irreplaceable data.
5. Document the expected recovery command or procedure.
6. Perform the change and validation.
7. Retain or remove temporary recovery points according to policy.

## Planned improvements

- Define retention and rotation for Proxmox backups.
- Back up Docker bind-mounted data and named volumes.
- Test restoration of Grafana, Prometheus, and Portainer state.
- Verify QNAP repository replicas automatically.
- Define component-level RTO and RPO targets.
- Record recovery tests in runbooks rather than assuming backups work.
