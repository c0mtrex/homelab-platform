# Phase 005 — Kubernetes and GitOps

## Objective

Introduce Kubernetes and GitOps without discarding the platform already running on Proxmox, Docker, OPNsense, Prometheus, Grafana, and QNAP.

The phase converts K801 into a local Kubernetes learning environment, uses this repository as desired state, and keeps observability independent on Docker01.

## Starting state

- K801 runs Ubuntu 24.04 LTS with 4 vCPUs, 7.7 GiB RAM, and 27 GiB free storage.
- Docker 29.7.2 and containerd are running.
- `kubectl`, `kind`, Helm, and Kubernetes are not installed.
- Ports 8080 and 8081 are used by existing Nginx demonstrations and will be preserved.
- Admin01 can reach K801 over SSH.
- Docker01 runs Prometheus and Grafana on a separate network.
- OPNsense controls traffic between the lab and home networks.

## Safety prerequisites

- [ ] Confirm the Git working tree is clean and important configuration is pushed.
- [ ] Take a named Proxmox snapshot of K801.
- [ ] Confirm SSH access from Admin01.
- [ ] Record current disk, memory, listening ports, and Docker workloads.
- [ ] Define the removal procedure for the local cluster.

## Target architecture

```text
Admin01
  ├── Git and GitHub
  ├── kubectl and Helm
  └── browser access
          |
          v
K801 kind cluster
  ├── Kubernetes control plane
  ├── Argo CD
  ├── application Deployment
  ├── Service
  ├── health probes
  └── resource controls
          |
          | approved metric scrapes
          v
Docker01
  ├── Prometheus
  └── Grafana
```

## Stage 1 — Kubernetes fundamentals

- Install version-controlled releases of `kubectl` and `kind`.
- Create a local cluster with an explicit configuration file.
- Deploy a small containerized application.
- Create a Deployment and Service.
- Scale replicas and observe reconciliation.
- Perform a rolling update.
- Deploy an invalid image, investigate `ImagePullBackOff`, and roll back.

Evidence:

- Healthy nodes and pods
- Service response
- Three replicas
- Failed-image events
- Successful rollout recovery

## Stage 2 — Workload operations

- Create a namespace.
- Separate ordinary configuration from sensitive configuration.
- Add CPU and memory requests and limits.
- Add startup, readiness, and liveness probes where appropriate.
- Break readiness and liveness separately and document the different outcomes.
- Inspect pod events, logs, restart counts, and resource state.

Evidence:

- Version-controlled manifests
- Readiness removes an unhealthy pod from service traffic
- Liveness restarts a failed container
- Documented requests-versus-limits explanation

## Stage 3 — GitOps with Argo CD

- Install Helm.
- Install Argo CD in a dedicated namespace.
- Define an Argo CD Application in Git.
- Synchronize desired state from this repository.
- Change replica count through a pull request.
- Introduce manual drift and observe Argo CD status.
- Reconcile the cluster to Git rather than preserving an undocumented manual edit.

Evidence:

- Argo CD reports synchronized and healthy
- Git history identifies the deployed change
- Drift and reconciliation are documented

## Stage 4 — Reusable platform pattern

- Separate reusable base configuration from environment-specific values.
- Standardize labels and naming.
- Require immutable image references.
- Establish health and resource defaults.
- Add CI checks for YAML and Kubernetes manifests.
- Document a developer deployment path and an operator runbook.

Evidence:

- Another developer could follow the README without undocumented steps
- A deliberately invalid pull request fails validation
- A valid pull request passes validation

## Stage 5 — Observability integration

- Add Kubernetes and application metric targets to Prometheus.
- Restrict network access to the required source, destination, and ports.
- Build Grafana views for availability, errors, traffic, and saturation.
- Define one SLI and SLO.
- Trigger a controlled failure and observe metrics, events, and logs.

Evidence:

- Prometheus target is up
- Grafana displays Kubernetes or application data
- Failure produces an explainable telemetry signal
- Recovery is documented

## Failure exercises

- Invalid application syntax caught by CI
- Nonexistent image tag
- Failed readiness probe
- Failed liveness probe
- Missing required configuration
- Resource limit problem
- Manual cluster drift
- Failed rollout and rollback

## Definition of done

This phase is complete when the operator can:

- Explain Cluster, Node, Pod, Deployment, ReplicaSet, Service, and Ingress.
- Deploy, scale, update, diagnose, and roll back an application.
- Explain readiness, liveness, requests, and limits.
- Use events, logs, and metrics during troubleshooting.
- Explain GitOps and demonstrate Argo CD reconciliation.
- Describe the supported deployment path and its guardrails.
- Recover from the controlled failures without undocumented manual state.
- Clearly distinguish hands-on lab experience from production Kubernetes experience.
