# Homelab Platform

## Enterprise DevOps and Site Reliability Engineering Portfolio

This repository is the source of truth for a production-inspired homelab used to practice infrastructure engineering, automation, observability, networking, CI/CD, Kubernetes, and GitOps.

The platform runs on Proxmox and deliberately separates administration, workloads, observability, routing, and storage so failures and security boundaries can be studied rather than hidden inside one server.

## Current Platform

```text
                           Proxmox VE
                               |
             +-----------------+-----------------+
             |                 |                 |
         admin01              k801           docker01
       Administration     Kubernetes lab     Observability
        10.10.0.160        10.10.0.130        10.0.0.30
             \                 |                 /
              +------------ OPNsense -----------+
                      DNS, routing, firewall
                               |
                         QNAP storage
                          10.0.0.200
```

### Verified capabilities

- Proxmox VE virtualization on an HP Z840 workstation
- Ubuntu virtual machines with separated operational responsibilities
- OPNsense routing, DNS, aliases, and source-interface firewall policies
- Docker and Docker Compose workloads
- Prometheus, Grafana, Node Exporter, and cAdvisor monitoring
- Portainer container administration
- QNAP storage for Git, documentation, and backups
- Git and GitHub version-control workflow
- GitHub Actions pull-request validation and immutable GHCR image publishing
- A single-node K3s cluster on k801 using containerd and Traefik
- A two-replica Python FastAPI staging deployment with startup, readiness, and liveness probes
- ClusterIP Service discovery, Traefik Ingress, and OPNsense staging DNS
- A version-controlled Grafana Service Health API dashboard

### Current limitations

- K3s is installed, but the single-node cluster has no node-level high availability and Argo CD is not installed yet.
- Kubernetes manifests are still applied manually rather than reconciled automatically by GitOps.
- The staging Ingress currently uses HTTP without TLS or application authentication.
- Several container images currently use mutable `latest` tags.
- Most monitoring containers do not yet define health checks.
- Kubernetes metrics, centralized logging, tracing, and alert routing remain planned work.

## Current Kubernetes Staging Milestone

- Published the Service Health API to GHCR using an immutable Git-SHA tag and image digest.
- Deployed two replicas into the Kubernetes staging namespace.
- Added non-root execution, a read-only root filesystem, dropped capabilities, and resource controls.
- Added startup, readiness, and liveness probes.
- Exposed the ClusterIP Service through Traefik Ingress.
- Added OPNsense DNS for service-health-api.staging.home.arpa.
- Verified the health, readiness, Swagger documentation, and Prometheus metrics endpoints.
- Documented the complete delivery path, source code, troubleshooting commands, and firewall-hardening procedure.

## Engineering Principles

- Git is the desired source of truth.
- Changes are reviewed through feature branches and pull requests.
- Infrastructure and application configuration should be reproducible.
- Monitoring and recovery are designed with the workload, not added afterward.
- Secrets and generated state are excluded from source control.
- Access is granted for a documented purpose and verified from the intended source.
- Current state, desired state, and planned state are documented separately.
- Failures are introduced deliberately in the lab and followed by documented recovery.

## Repository Structure

```text
homelab-platform/
├── .github/workflows/       # Automated validation and deployment workflows
├── argocd/                  # Argo CD application definitions
├── docker/                  # Docker Compose platform configuration
├── docs/
│   ├── architecture/        # Current architecture and design
│   ├── decisions/           # Architecture decision records
│   ├── phases/              # Implementation phases and learning outcomes
│   └── runbooks/            # Repeatable operational procedures
├── infrastructure/          # Host, network, and storage automation
├── kubernetes/              # Kubernetes base and environment configuration
├── monitoring/              # Metrics, dashboards, alerts, and telemetry
└── scripts/                 # Auditable operational automation
```

Directories are added when their first managed artifact is introduced; Git does not track empty directories.

## Delivery Roadmap

### Completed foundation

- [x] Proxmox installation and VM deployment
- [x] QNAP storage integration
- [x] OPNsense routing, DNS, and firewall policy
- [x] Docker and Docker Compose
- [x] Portainer
- [x] Prometheus, Grafana, Node Exporter, and cAdvisor
- [x] Git and GitHub repository
- [x] Feature-branch workflow introduced

### Current phase: platform reconciliation

- [x] Inventory running virtual machines and Docker workloads
- [x] Verify inter-network DNS, routing, and service connectivity
- [x] Reconcile current architecture documentation
- [x] Import sanitized Docker Compose definitions
- [x] Add GitHub Actions validation
- [x] Add operational runbooks and learning guides

### Current phase: Kubernetes and GitOps

- [x] Create a recovery snapshot before cluster installation
- [x] Install single-node K3s on k801
- [x] Deploy and troubleshoot a containerized application
- [x] Add health probes and resource controls
- [ ] Install Helm and Argo CD
- [ ] Reconcile Kubernetes desired state from Git
- [ ] Connect Kubernetes metrics to Prometheus and Grafana on `docker01`
- [ ] Exercise drift, failed rollout, rollback, and recovery

### Future phases

- [ ] Alertmanager and actionable alert routing
- [ ] Loki centralized logging
- [ ] OpenTelemetry and distributed tracing
- [ ] Ansible host configuration
- [ ] Terraform infrastructure provisioning
- [ ] Backup automation and recovery testing
- [ ] Container-image scanning and policy validation

## Technology Map

| Area | Current | Planned |
|---|---|---|
| Virtualization | Proxmox VE, QEMU/KVM | Automated VM provisioning |
| Operating systems | Ubuntu Server and Desktop | Standardized host configuration |
| Networking | OPNsense, DNS, routing, firewall aliases | Tighter service-to-service policy |
| Containers | Docker, Docker Compose, Portainer | Version-pinned images and health checks |
| Orchestration | Single-node K3s, containerd, Traefik | Additional nodes and controlled failure testing |
| GitOps | Reviewed Kubernetes manifests in Git | Argo CD reconciliation |
| Observability | Prometheus, Grafana, Node Exporter, cAdvisor, application metrics | Kubernetes discovery, logs, traces, alerts |
| Storage | QNAP and Proxmox storage | Tested rotation and recovery procedures |
| CI/CD | Pull-request validation and GHCR publishing with GitHub Actions | Automated staging promotion and rollback |

## Documentation

- [Lab overview](docs/architecture/001-lab-overview.md)
- [Network topology](docs/architecture/002-network-topology.md)
- [Storage design](docs/architecture/003-storage-design.md)
- [Monitoring stack](docs/architecture/004-monitoring-stack.md)
- [Kubernetes and GitOps phase](docs/phases/005-kubernetes-gitops.md)
- [Service Health API: from Python to a website](docs/guides/service-health-api-to-website.md)
- [Service Health API code walkthrough](docs/guides/service-health-api-code-walkthrough.md)
- [OPNsense lab firewall lockdown](docs/guides/opnsense-lab-firewall-lockdown.md)

## Author

**Shaun Browne**

Enterprise Infrastructure · Automation · DevOps · Site Reliability Engineering
