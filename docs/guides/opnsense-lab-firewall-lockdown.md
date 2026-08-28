# OPNsense Lab Firewall Lockdown Runbook

## Purpose

This runbook reduces broad access between the home network and the lab while preserving the traffic that is actually required.

The main goals are:

- Allow Shaun's personal PC to browse K3s websites.
- Allow admin01 to administer approved lab services.
- Allow the Service Health API to check Prometheus.
- Allow Prometheus to scrape specifically approved targets.
- Prevent an entire network from reaching every port on a server.
- Make every firewall rule easy to understand during troubleshooting.

Do not delete an existing rule until its replacement has been tested. Disable old rules first so rollback remains easy.

## Current network paths

```text
Home network:       10.0.0.0/24
Docker01:           10.0.0.30
OPNsense WAN:       10.0.0.132

Lab network:        10.10.0.0/24
OPNsense LAN:       10.10.0.1
K801:               10.10.0.130
Admin01:            10.10.0.160
```

Traffic from `10.0.0.0/24` enters OPNsense on **WAN**.

Traffic from `10.10.0.0/24` enters OPNsense on **LAN**.

Firewall rules normally belong on the interface where the connection begins.

## Important rule behavior

OPNsense is stateful. When an allowed connection begins, its response traffic is automatically allowed as part of the same state.

For example, a rule allowing:

```text
PERSONAL_PC -> K801 TCP 80
```

does not require a separate rule for:

```text
K801 -> PERSONAL_PC
```

Rules are evaluated in order. A broad rule placed above a narrow rule can match first and hide whether the narrow rule works.

## Phase 1: Back up before changing anything

In OPNsense:

1. Open **System > Configuration > Backups**.
2. Download the current configuration XML.
3. Name it with the date and purpose, for example:

```text
opnsense-before-lab-firewall-lockdown-2026-08-28.xml
```

4. Copy the backup to the QNAP.
5. Export the current firewall-rule CSV as an additional reference.

Do not continue until the backup has been saved outside the firewall.

## Phase 2: Reserve the personal PC address

The personal PC needs a stable IP address so an alias will not unexpectedly point to the wrong device.

Use one of these methods:

- Create a DHCP reservation on the Comcast router.
- Configure a static address outside the DHCP allocation range.

Record the address here before continuing:

```text
PERSONAL_PC_IP = ______________________________
```

Confirm the current address from Windows PowerShell:

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object InterfaceAlias -NotLike '*Loopback*'
```

## Phase 3: Create descriptive aliases

Open **Firewall > Aliases**.

### Host aliases

Create or confirm these aliases:

| Alias | Type | Value | Purpose |
|---|---|---|---|
| `PERSONAL_PC` | Host | Personal PC reserved IP | Authorized browser workstation |
| `K801` | Host | `10.10.0.130` | K3s node and API host |
| `ADMIN01` | Host | `10.10.0.160` | Administrative workstation |
| `DOCKER01` | Host | `10.0.0.30` | Prometheus, Grafana, and Portainer host |

### Port aliases

Create or confirm these aliases:

| Alias | Type | Values | Purpose |
|---|---|---|---|
| `SVC_K3S_WEB` | Port | `80`, `443` | Traefik HTTP and future HTTPS |
| `SVC_DOCKER_API` | Port | `8082` | Original Service Health API on k801 |
| `SVC_PROMETHEUS` | Port | `9090` | Prometheus web/API endpoint |
| `SVC_GRAFANA` | Port | `3000` | Grafana web interface |
| `SVC_NODE_EXPORTER` | Port | `9100` | Node Exporter metrics |
| `SVC_PORTAINER` | Port | `9443` | Portainer HTTPS interface |
| `SVC_SSH` | Port | `22` | SSH administration |
| `SVC_DNS` | Port | `53` | DNS over TCP and UDP |

Use aliases in rules instead of raw addresses whenever practical. This makes the policy readable and allows an address to be updated in one place.

## Phase 4: Add the personal-PC web rule

Open **Firewall > Rules > WAN** because the personal PC connection begins on the home-network side of OPNsense.

Create this rule:

| Field | Value |
|---|---|
| Action | Pass |
| Quick | Enabled |
| Interface | WAN |
| Direction | In |
| TCP/IP version | IPv4 |
| Protocol | TCP |
| Source | `PERSONAL_PC` |
| Source port | Any |
| Destination | `K801` |
| Destination port | `SVC_K3S_WEB` |
| Gateway | Default |
| Log | Enabled during testing |
| Description | `Personal PC -> K3s web applications` |

Place it above the broad rule currently identified by:

```text
UUID: 28ce5e98-720b-498d-ba8b-45a3000bb9f6
Current behavior: NET_HOME -> ADMIN01,k801 using any protocol and any port
```

Apply the changes, but do not disable the old rule yet.

## Phase 5: Confirm the new rule is matching

From the personal PC, open:

```text
http://service-health-api.staging.home.arpa/docs
```

From Windows PowerShell, test DNS and HTTP:

```powershell
Resolve-DnsName service-health-api.staging.home.arpa -Server 10.10.0.1

Test-NetConnection `
  service-health-api.staging.home.arpa `
  -Port 80
```

In OPNsense:

1. Open **Firewall > Log Files > Live View**.
2. Filter for the personal PC address.
3. Filter for destination `10.10.0.130`.
4. Filter for destination port `80`.
5. Confirm the new rule description or rule ID handled the request.

## Phase 6: Disable the broad home-to-lab rule

After confirming the new rule matches:

1. Disable rule `28ce5e98-720b-498d-ba8b-45a3000bb9f6`.
2. Apply the firewall changes.
3. Repeat the website test.
4. Confirm the website still works.
5. Confirm SSH or other unintended ports are no longer reachable from the personal PC.

PowerShell examples:

```powershell
Test-NetConnection 10.10.0.130 -Port 80
Test-NetConnection 10.10.0.130 -Port 22
Test-NetConnection 10.10.0.130 -Port 8082
```

Expected outcome unless separately authorized:

| Port | Expected result |
|---|---|
| `80` | Success |
| `443` | Allowed by firewall; application may not listen yet |
| `22` | Failure |
| `8082` | Failure |

Keep the old rule disabled for a testing period before considering deletion.

## Phase 7: Separate k801 and Docker01 flows

The existing rule described as `k801 talking to docker all ports` has:

```text
Source: DOCKER01
Destination: k801
Interface: LAN
Protocol and ports: any
```

The direction and interface do not match the description. Replace it with individual rules based on the actual connection initiator.

### Service Health API checks Prometheus

The API on k801 initiates a connection to Prometheus on Docker01.

Create on **LAN**:

| Field | Value |
|---|---|
| Action | Pass |
| Interface | LAN |
| Direction | In |
| Protocol | TCP |
| Source | `K801` |
| Destination | `DOCKER01` |
| Destination port | `SVC_PROMETHEUS` |
| Log | Enabled during testing |
| Description | `K801 Service Health API -> Docker01 Prometheus` |

Test from k801:

```bash
curl --include \
  http://10.0.0.30:9090/-/healthy
```

Expected result:

```text
HTTP/1.1 200 OK
Prometheus Server is Healthy.
```

### Prometheus scrapes the Docker-based API

Docker01 initiates a connection to the original API on k801 port 8082.

If this scrape is still required, create on **WAN**:

| Field | Value |
|---|---|
| Action | Pass |
| Interface | WAN |
| Direction | In |
| Protocol | TCP |
| Source | `DOCKER01` |
| Destination | `K801` |
| Destination port | `SVC_DOCKER_API` |
| Log | Enabled during testing |
| Description | `Docker01 Prometheus -> K801 Service Health API metrics` |

Test from Docker01:

```bash
curl --include \
  http://10.10.0.130:8082/metrics
```

Once both narrow rules are verified, disable the existing all-port rule:

```text
UUID: 0d8f0929-eb2a-4397-a56a-c3f976f1eb79
```

Do not remove the port-8082 rule until Prometheus has been changed to scrape the K3s deployment or that older Docker API has been retired.

## Phase 8: Review access to OPNsense itself

Review this rule carefully:

```text
UUID: afd8bb39-0daa-45fa-af55-b61486c24b9b
Description: Default allow LAN to any rule
Interface: WAN
Source: NET_HOME
Destination: self
Protocol and port: any
```

Its description does not match its behavior. It appears to permit the home network to reach services listening on OPNsense itself.

Before changing it, identify which services are genuinely required from the home side, such as:

- OPNsense web administration
- DNS
- ICMP for troubleshooting

Replace broad access with separate narrow rules. Example management rule:

| Field | Value |
|---|---|
| Interface | WAN |
| Protocol | TCP |
| Source | `PERSONAL_PC` |
| Destination | WAN address or This Firewall |
| Destination port | Exact OPNsense GUI port |
| Description | `Personal PC -> OPNsense management` |

Do not change firewall-management access unless you have console access or a tested rollback path. Accidentally locking yourself out is worse than temporarily retaining a broad lab rule.

## Phase 9: Review the Internet-client rules

These current rules are broad:

```text
INTERNET_CLIENT -> self using any protocol and port
INTERNET_CLIENT -> any using any protocol and port
```

`Destination: any` includes both Internet and internally routed destinations.

Before changing them:

1. Inspect which hosts are members of `INTERNET_CLIENT`.
2. List their required outbound services.
3. Confirm whether they need access to other internal networks.
4. Create narrow internal rules above the Internet rule.
5. Consider an explicit block between security zones.

Common outbound services may include:

| Service | Protocol and port |
|---|---|
| DNS to OPNsense | TCP/UDP 53 |
| HTTP | TCP 80 |
| HTTPS | TCP 443 |
| NTP | UDP 123 |

Do not tighten outbound rules without accounting for operating-system updates, container registries, GitHub, package repositories, and time synchronization.

## Phase 10: Correct rule descriptions

Several current rules are described as `admin01 -> PVE01` even though their destinations and services differ.

Rename them to describe the real flow:

```text
Admin01 -> PVE01 web administration
Admin01 -> Lab servers SSH
Admin01 -> Docker01 Grafana
Admin01 -> Docker01 Node Exporter
Admin01 -> Docker01 Portainer
Admin01 -> Docker01 Prometheus
Admin01 -> OPNsense DNS
```

A useful description answers:

```text
Who starts the connection?
What is the destination?
What service is required?
```

## Final desired rule pattern

```text
Source             Destination       Required service only
-----------------  ----------------  -------------------------
PERSONAL_PC        K801              TCP 80 and 443
ADMIN01            PVE01             Proxmox management port
ADMIN01            lab servers       TCP 22
ADMIN01            DOCKER01          Approved management ports
K801               DOCKER01          TCP 9090
DOCKER01            K801              TCP 8082, only while needed
Approved clients   OPNsense          DNS or management ports only
```

Avoid this pattern:

```text
Entire network -> multiple servers -> any protocol -> any port
```

## Verification checklist

- [ ] OPNsense configuration backup is stored on the QNAP.
- [ ] The personal PC has a reserved IP address.
- [ ] Host and port aliases have descriptive names.
- [ ] Personal PC can open the K3s website on port 80.
- [ ] Personal PC cannot access unauthorized SSH or API ports.
- [ ] K801 can reach Prometheus on Docker01 port 9090.
- [ ] Docker01 can reach only the required metrics target on k801.
- [ ] Disabled broad rules remain available for temporary rollback.
- [ ] Live View confirms the intended rules are matching.
- [ ] Rule descriptions match their real source, destination, and service.
- [ ] No Comcast port-forward or DMZ setting exposes the lab publicly.
- [ ] IPv6 policy has been reviewed separately from IPv4.

## Rollback procedure

If required traffic stops working:

1. Re-enable the previously disabled broad rule.
2. Apply the change.
3. Confirm connectivity returns.
4. Use Live View to identify the blocked source, destination, and port.
5. Add or correct one narrow rule.
6. Retest before disabling the broad rule again.

If firewall administration is lost entirely, use the Proxmox console for the OPNsense VM and restore the saved configuration if necessary.

## Interview-sized explanation

> I reviewed the existing inter-network firewall rules and found broad any-to-any access that worked but exceeded the required service flows. I backed up the configuration, created host and port aliases, replaced broad rules with stateful least-privilege rules based on the connection initiator, enabled temporary logging, and verified each flow through OPNsense Live View. I disabled old rules before deletion to preserve a rollback path and documented the final traffic matrix.

## Official references

- [OPNsense firewall rules](https://docs.opnsense.org/manual/firewall.html)
- [OPNsense aliases](https://docs.opnsense.org/manual/aliases.html)
- [OPNsense firewall logging](https://docs.opnsense.org/manual/logging_firewall.html)
