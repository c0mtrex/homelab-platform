# 004 - Monitoring Stack

## Purpose

The monitoring platform provides visibility into the health and performance of the homelab.

Observability is considered a core design principle rather than an afterthought.

---

# Components

## Prometheus

Purpose:

Metrics collection

Responsibilities:

- Scrape exporters
- Store time-series data

---

## Grafana

Purpose:

Visualization

Responsibilities:

- Dashboards
- Metrics Analysis
- Alert Visualization

---

## Node Exporter

Purpose:

Linux Host Monitoring

Metrics:

- CPU
- Memory
- Disk
- Filesystem
- Network
- Load Average

---

## cAdvisor

Purpose:

Docker Container Monitoring

Metrics:

- CPU Usage
- Memory Usage
- Network Utilization
- Disk I/O
- Container Lifecycle

---

## Portainer

Purpose:

Docker Management

Responsibilities:

- Container Management
- Stack Deployment
- Image Management
- Logs

---

# Current Monitoring

Host

↓

Node Exporter

↓

Prometheus

↓

Grafana

---

Containers

↓

cAdvisor

↓

Prometheus

↓

Grafana

---

# Future Monitoring

Future additions include:

- Alertmanager
- Loki
- OpenTelemetry
- Tempo
- Blackbox Exporter
- SNMP Exporter
- Kubernetes Monitoring

---

# Long-Term Goal

Provide complete observability across:

- Proxmox
- Docker
- Kubernetes
- Networking
- Storage
- Virtual Machines
- Applications

using a unified monitoring platform.