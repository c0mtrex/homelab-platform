# Phase 3 - OPNsense Deployment

## Objectives

## Hardware

## Installation

## WAN Configuration

## LAN Configuration

## Firewall Rules


## Management Access

The OPNsense firewall is managed from the trusted home LAN.

### Current Policy

- HTTPS enabled
- HTTP automatically redirects to HTTPS
- GUI listening on all interfaces
- WAN firewall rules permit access only from the `NET_HOME` alias
- No Internet-facing management access
- Firewall is behind the ISP router (double NAT)

### Design Decision

This homelab has a single administrator and resides on a trusted home network. Restricting management to the home subnet provides an appropriate balance between security and operational simplicity.

Future versions of the lab may migrate management access to a dedicated Admin VLAN or VPN-only access.

## DNS

## NAT

## Lessons Learned

## Next Phase