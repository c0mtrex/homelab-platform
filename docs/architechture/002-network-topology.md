# 002 - Network Topology

## Overview

The homelab network is designed to evolve from a simple flat network into an enterprise-style segmented environment.

The initial deployment uses a single management bridge in Proxmox. Future phases introduce VLAN segmentation and virtual routing.

---

## Virtual Switches

### vmbr0

Primary bridge connected to the physical network.

Responsibilities:

- Proxmox Management
- Internet Connectivity
- Existing VMs

---

### vmbr1

Virtual-only bridge.

Purpose:

- Lab Network
- Future OPNsense LAN
- Future VLAN Segmentation
- Isolated Testing Environment

# Current Topology

Internet

↓

Home Router

↓

Proxmox Host

↓

vmbr0

↓

docker01

↓

Docker Containers

- Grafana
- Prometheus
- Portainer
- Node Exporter
- cAdvisor

---

# Planned Network Architecture

Internet

↓

Firewall (OPNsense)

↓

Managed Switch (Virtual)

↓

VLAN 10 Management

VLAN 20 Servers

VLAN 30 Storage

VLAN 40 Kubernetes

VLAN 50 Lab

VLAN 60 Guest

---

# Future Physical Network

Internet

↓

Router

↓

Managed Switch

├── QNAP

├── Proxmox

├── Workstation

├── Wireless AP

└── Future Servers

---

# Networking Goals

- VLAN Segmentation
- Inter-VLAN Routing
- Network Security
- Monitoring
- SNMP
- Port Monitoring
- Firewall Rules
- DHCP
- DNS

---

# Future Monitoring

The network infrastructure will eventually be monitored using Prometheus and Grafana to collect:

- Interface Utilization
- CPU
- Memory
- Temperature
- Port Errors
- Packet Loss
- Link Speed
- Uptime