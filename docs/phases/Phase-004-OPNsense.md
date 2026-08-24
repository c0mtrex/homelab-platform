# Phase 004 — OPNsense Deployment

## Objective

Introduce a controlled boundary between the existing home network and the isolated lab network. OPNsense provides DNS, routing, firewall policy, and a platform for practicing network troubleshooting and least-privilege design.

## Architecture

```text
Home network: 10.0.0.0/24
          |
      OPNsense WAN
          |
      OPNsense LAN: 10.10.0.1
          |
Lab network: 10.10.0.0/24
```

The firewall runs as a Proxmox virtual machine and is behind the ISP router. No internet-facing management access is intentionally configured.

## Implemented capabilities

- Routed lab network
- Outbound internet access for selected clients
- DNS resolution and `home.arpa` search domain
- Host, network, and service aliases
- Source-interface firewall rules
- HTTPS management interface
- HTTP-to-HTTPS management redirect
- Implicit deny for traffic not matched by a pass rule

## Management policy

Administrative flows use named aliases rather than repeated addresses and port numbers. Current rules include purpose-specific access from Admin01 to:

- Proxmox
- Managed hosts over SSH
- Grafana
- Prometheus
- Node Exporter
- Portainer
- OPNsense DNS

Some broader rules are intentionally retained for the home lab. In a production environment, those flows would be reduced to documented source, destination, protocol, and port requirements.

## Verification performed

- Admin01 established SSH access to K801.
- K801 resolved Docker01 through OPNsense DNS.
- K801 reached published monitoring and management ports on Docker01 across the routed boundary.
- K801 mounted the QNAP SMB share on the home network.
- The exported rule set was reviewed without placing the raw export in this public repository.

## Security decisions

- The GUI is restricted through firewall source policy even though it listens on multiple interfaces.
- Public WAN addresses, credentials, configuration backups, and raw rule exports are excluded from GitHub.
- Firewall aliases improve readability but must be reviewed because alias membership changes the effective policy.
- IPv6 is evaluated separately rather than assumed safe because IPv4 uses NAT.
- A configuration backup is required before future DNS or firewall changes.

## Lessons learned

- Test from the intended source host; a loopback test does not prove firewall traversal.
- Confirm the resolved destination address before interpreting a connection test.
- TCP success proves reachability and a listening socket, not application health or authorization.
- Firewall rules are normally evaluated on the interface where traffic enters.
- Rule descriptions must match actual intent so incident response and audits remain reliable.

## Next phase

Document the platform as it currently operates, reconcile configuration with Git, and introduce Kubernetes and GitOps on K801 without weakening the existing network boundary.
