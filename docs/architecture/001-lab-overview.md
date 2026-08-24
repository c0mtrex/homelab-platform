# 001 — Homelab Overview

## Purpose

The Homelab Platform is a production-inspired environment for practicing DevOps, site reliability engineering, Linux administration, networking, automation, observability, and cloud-native operations.

The lab is operated as a platform rather than a collection of unrelated virtual machines. Components have defined responsibilities, configuration is moved toward version control, operational changes are tested, and recovery procedures are documented.

## Design objectives

- Separate management, workload, observability, network, and storage responsibilities.
- Replace manual configuration with repeatable definitions and automation.
- Use Git as the desired source of truth.
- Detect failures through metrics, logs, health checks, and actionable alerts.
- Practice incident investigation, rollback, and recovery.
- Build supported deployment patterns another engineer could follow.
- Explain technical decisions and tradeoffs in plain language.

## Physical and virtualization layer

| Component | Responsibility |
|---|---|
| HP Z840 workstation | Physical compute platform |
| Proxmox VE | Hypervisor and virtual-machine lifecycle |
| QNAP NAS | Network storage, Git storage, documentation, and backup targets |
| OPNsense VM | DNS, routing, firewall policy, and network boundary |

## Verified virtual machines

| VM | Operating system | Resources | Network | Responsibility |
|---|---|---:|---|---|
| `admin01` | Ubuntu 26.04 LTS | 4 vCPU, 7.2 GiB RAM, 39 GiB filesystem | `10.10.0.160/24` | GUI management workstation, Git, SSH, and future Kubernetes administration |
| `k801` | Ubuntu 24.04 LTS | 4 vCPU, 7.7 GiB RAM, 39 GiB filesystem | `10.10.0.130/24` | Docker host and future local Kubernetes cluster |
| `docker01` | Ubuntu 24.04 LTS | 4 vCPU, 7.7 GiB RAM, 39 GiB filesystem | `10.0.0.30/24` | Independent observability and Docker-management platform |
| `opnsense01` | OPNsense | Managed by Proxmox | Connects home and lab networks | DNS, routing, aliases, and firewall enforcement |

Resource values were collected from the guest operating systems. They may differ slightly from nominal Proxmox allocations because of operating-system reporting and reserved memory.

## Platform responsibilities

### Admin01

- Provides the graphical administration environment.
- Initiates SSH management connections.
- Reaches Proxmox, Grafana, Prometheus, Portainer, and managed systems through documented firewall aliases.
- Will receive `kubectl`, Helm, and the Argo CD CLI for remote cluster administration.
- Hosts an intentional `iperf3` server for controlled network-performance testing.

### K801

- Runs Docker and containerd.
- Currently hosts two Nginx demonstration containers on ports 8080 and 8081.
- Will host a local Kubernetes cluster using `kind`.
- Will run Argo CD and the training application.
- Mounts the QNAP Git share at `/mnt/qnap-git`.

### Docker01

- Runs the monitoring Compose project: Prometheus, Grafana, Node Exporter, and cAdvisor.
- Runs Portainer in a separate Compose project.
- Preserves observability independently from the Kubernetes workload host.
- Will scrape Kubernetes and application metrics after the cluster is deployed.

### OPNsense01

- Provides DNS to the lab network.
- Routes controlled traffic between the home and lab subnets.
- Uses host, network, and service aliases to make policy readable and reusable.
- Applies rules on the interface where traffic enters the firewall.
- Relies on implicit deny when no pass rule matches.

## Current maturity

### Implemented and verified

- Virtualization and guest operating systems
- Network storage and QNAP Git working copy
- Routed network separation
- DNS resolution for registered hosts
- Alias-based firewall policy
- Docker and Compose workloads
- Infrastructure and container metrics
- Grafana visualization
- Git repository and local/remote history

### In progress

- Reconcile running configuration with Git.
- Add automated repository validation.
- Correct stale architecture documentation.
- Establish feature-branch and pull-request delivery as the normal path.

### Planned

- Kubernetes workload orchestration
- Argo CD GitOps reconciliation
- Health probes and resource controls
- Kubernetes and application telemetry
- Centralized logging and tracing
- Alert routing and incident runbooks
- Host and infrastructure automation

## Accuracy boundary

This repository distinguishes professional production experience from hands-on lab work. A component is marked complete only after its configuration or runtime behavior has been inspected and its intended path has been tested.
