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

### Current limitations

- Kubernetes and Argo CD are not installed yet.
- The running Docker Compose definitions have not yet been reconciled into this repository.
- GitHub Actions validation is not yet configured for this repository.
- Several container images currently use mutable `latest` tags.
- Most monitoring containers do not yet define health checks.
- Kubernetes metrics, centralized logging, tracing, and alert routing remain planned work.

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
- [ ] Reconcile current architecture documentation
- [ ] Import sanitized Docker Compose definitions
- [ ] Add GitHub Actions validation
- [ ] Add operational runbooks

### Next phase: Kubernetes and GitOps

- [ ] Create a recovery snapshot before cluster installation
- [ ] Install `kubectl` and `kind` on `k801`
- [ ] Deploy and troubleshoot a containerized application
- [ ] Add health probes and resource controls
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
| Orchestration | Not installed | Kubernetes with `kind` |
| GitOps | Git documentation workflow | Argo CD reconciliation |
| Observability | Prometheus, Grafana, Node Exporter, cAdvisor | Kubernetes metrics, logs, traces, alerts |
| Storage | QNAP and Proxmox storage | Tested rotation and recovery procedures |
| CI/CD | Feature branches and pull requests | GitHub Actions validation |

## Documentation

- [Lab overview](docs/architecture/001-lab-overview.md)
- [Network topology](docs/architecture/002-network-topology.md)
- [Storage design](docs/architecture/003-storage-design.md)
- [Monitoring stack](docs/architecture/004-monitoring-stack.md)
- [Kubernetes and GitOps phase](docs/phases/005-kubernetes-gitops.md)

## Author

**Shaun Browne**

Enterprise Infrastructure · Automation · DevOps · Site Reliability Engineering
