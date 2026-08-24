# 002 — Network Topology

## Overview

The homelab uses OPNsense to separate the existing home network from an isolated lab network. This creates a realistic boundary for DNS, routing, firewall policy, and cross-network troubleshooting without requiring enterprise hardware.

## Current topology

```text
Internet
   |
ISP router
   |
Home network: 10.0.0.0/24
   ├── Proxmox management
   ├── docker01: 10.0.0.30
   ├── QNAP01:   10.0.0.200
   └── OPNsense WAN
             |
             | routing, NAT, DNS, firewall policy
             |
       OPNsense LAN: 10.10.0.1
             |
Lab network: 10.10.0.0/24
   ├── k801:    10.10.0.130
   └── admin01: 10.10.0.160
```

No public WAN address, credential, or exported firewall configuration is stored in this repository.

## Proxmox bridges

### `vmbr0`

The bridge connected to the existing physical home network. It supports Proxmox management, home-network systems, storage access, and the OPNsense WAN side.

### `vmbr1`

The virtual lab bridge behind OPNsense. It carries the `10.10.0.0/24` network used by Admin01 and K801.

This layout gives OPNsense a routed position between the home and lab networks rather than placing all virtual machines on one unrestricted bridge.

## DNS

- Admin01 and K801 use `10.10.0.1` as their DNS server.
- OPNsense supplies the `home.arpa` search domain.
- `docker01.home.arpa` resolves to `10.0.0.30` from the lab network.
- K801 did not have a DNS record at the time of inventory; this is tracked as a DNS-hygiene item rather than hidden through local `/etc/hosts` changes.
- LLMNR, multicast DNS, and DNS over TLS are not enabled on the inventoried Ubuntu lab interfaces.

## Firewall policy model

OPNsense policies use aliases for hosts, networks, and services. Examples include:

- Managed hosts such as Admin01, K801, Docker01, PVE01, and QNAP01
- Network groups such as the trusted home network and selected internet clients
- Service groups for SSH, Proxmox, Grafana, Prometheus, Node Exporter, and Portainer

Rules are evaluated on the source interface. The policy permits required administrative and internet flows and relies on the interface's implicit deny for unmatched traffic.

The raw firewall export is retained outside this public repository because operational firewall policy can contain sensitive infrastructure details.

## Verified traffic paths

### Administration to K801

```text
admin01 -> SSH -> k801
```

The active administration session proves IP reachability, TCP port 22 access, and SSH authentication.

### Lab to Docker01

```text
k801 -> OPNsense -> docker01
```

From K801, TCP connections were verified to Docker01 on:

| Port | Service |
|---:|---|
| 3000 | Grafana |
| 8000 | Portainer edge/tunnel service |
| 8080 | cAdvisor |
| 9000 | Portainer HTTP interface |
| 9090 | Prometheus |
| 9100 | Node Exporter |
| 9443 | Portainer HTTPS interface |

This proves DNS resolution, inter-network routing, firewall passage, and TCP listening. It does not by itself prove authentication, application health, internet exposure, or reverse-direction access.

### Lab to QNAP

K801 mounts the QNAP Git share across the routed boundary. This verifies cross-network storage access for the configured SMB path.

## Security boundaries and tradeoffs

- Admin interfaces should be reachable only from approved management sources.
- Portainer's Docker socket access is effectively host-administrative and requires strong protection.
- Metrics endpoints disclose operational details and should not be internet-facing.
- Docker01 has no active UFW policy; network protection currently depends on upstream policy and Docker's published-port behavior.
- Docker01 has global IPv6 addressing, so IPv6 exposure must be validated independently of IPv4 NAT assumptions.
- Broad lab rules may be acceptable for learning, but production policy would restrict source, destination, protocol, and port to documented needs.

## Planned Kubernetes flows

After Kubernetes is deployed:

- Admin01 will initiate Kubernetes API and Argo CD administration traffic toward K801.
- Prometheus on Docker01 will initiate metric scrapes toward approved K801 endpoints.
- User application traffic will enter through a documented Kubernetes Service or Ingress path.
- New firewall rules will be added only after the required direction, source, destination, and port are documented.

## Troubleshooting method

For a failed connection, validate in this order:

1. Source and destination identity
2. DNS result
3. Local route and gateway
4. Firewall rule on the source interface
5. Destination listening socket
6. TCP or UDP connectivity
7. TLS and authentication
8. Application response and logs

This avoids treating a DNS, routing, firewall, or application-layer failure as the same problem.
