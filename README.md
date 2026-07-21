# Homelab Platform

### Enterprise DevOps & Site Reliability Engineering Portfolio

> Enterprise DevOps & Site Reliability Engineering (SRE) homelab built from the ground up to develop production-level infrastructure, automation, observability, and cloud engineering skills.

---

# Project Goal

This repository documents the complete design, implementation, and evolution of my DevOps/SRE homelab.

---

# Current Infrastructure

## Hypervisor

- Proxmox VE
- HP Z840 Workstation
- Ubuntu Server virtual machines
- QNAP NAS for storage and backups

## Container Platform

- Docker
- Docker Compose
- Portainer

## Monitoring Stack

- Prometheus
- Grafana
- Node Exporter
- cAdvisor

---

# Learning Roadmap

## ✅ Phase 1 — Infrastructure

- [x] Install Proxmox
- [x] Configure networking
- [x] Configure shared storage
- [x] Create Ubuntu template
- [x] Deploy Docker VM

---

## ✅ Phase 2 — Monitoring

- [x] Docker installation
- [x] Portainer deployment
- [x] Prometheus deployment
- [x] Grafana deployment
- [x] Node Exporter deployment
- [x] cAdvisor deployment

---

## 🚧 Phase 3 — Version Control & Engineering Workflow

- [x] Git installation
- [x] GitHub repository
- [x] VS Code integration
- [x] First commit
- [x] First push
- [ ] Repository organization
- [ ] GitHub Projects
- [ ] GitHub Issues
- [ ] Branching strategy

---

## Planned Phases

- [ ] CI/CD with GitHub Actions
- [ ] Infrastructure as Code (Ansible)
- [ ] Terraform
- [ ] Kubernetes
- [ ] Helm
- [ ] Logging (Loki)
- [ ] Alertmanager
- [ ] OpenTelemetry
- [ ] Cloud Infrastructure (AWS)

---

# Repository Structure

```text
homelab-platform/
│
├── docker/
│   └── monitoring/
│
├── docs/
│   ├── architecture/
│   ├── decisions/
│   ├── phases/
│   └── runbooks/
│
├── infrastructure/
│   ├── docker01/
│   ├── network/
│   ├── proxmox/
│   └── storage/
│
├── scripts/
│   ├── backup/
│   ├── maintenance/
│   └── monitoring/
│
└── diagrams/
```

---

# Engineering Principles

This project follows several guiding principles:

- Infrastructure as Code
- Automation over manual configuration
- Version control for all configuration
- Documentation for every major implementation
- Reproducible deployments
- Monitoring before optimization
- Security by default

---

# Technologies

| Category | Technologies |
|----------|--------------|
| Virtualization | Proxmox VE |
| Operating System | Ubuntu Server |
| Containers | Docker, Docker Compose |
| Monitoring | Prometheus, Grafana, Node Exporter, cAdvisor |
| Version Control | Git, GitHub |
| IDE | Visual Studio Code |
| Automation | Ansible *(planned)* |
| Infrastructure as Code | Terraform *(planned)* |
| Container Orchestration | Kubernetes *(planned)* |

---

# Repository Status

**Current Version:** v0.1

Current focus:

- Establishing a professional Git workflow
- Organizing project documentation
- Preparing the repository for CI/CD

---

# Author

**Shaun Browne**

Enterprise Infrastructure • DevOps • Site Reliability Engineering

This repository documents my continuous learning journey toward becoming a production-level DevOps / SRE engineer.