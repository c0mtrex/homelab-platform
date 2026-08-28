# Argo CD Bootstrap

## Purpose

Argo CD will provide continuous delivery for the K3s staging environment. It runs inside the private cluster and pulls approved desired state from GitHub after changes merge to `main`.

```text
Pull request
    -> GitHub Actions CI
    -> Merge to main
    -> Argo CD detects desired-state change
    -> Manual synchronization during the learning phase
    -> K3s staging resources reconciled
```

No self-hosted GitHub Actions runner is placed inside the homelab network.

## Pinned version

```text
Argo CD: v3.5.2
Installation manifest SHA-256:
9a87f2b3e14c278f12501eb0ef5c3955b27cf05370ca425381c6a908cf85a5c5
```

The bootstrap script downloads the official version-specific manifest and refuses to apply it unless the checksum matches.

## Safety decisions

- Use the non-HA installation because this is a single-node lab.
- Take a Proxmox snapshot before installation.
- Pin an exact Argo CD release.
- Verify the downloaded manifest before applying it.
- Begin with manual application synchronization.
- Do not enable automatic pruning initially.
- Do not enable self-healing initially.
- Access the UI through a port forward before configuring Ingress.
- Do not store the initial administrator password in Git.

## Bootstrap script modes

### Verify without changing K3s

```bash
./scripts/bootstrap-argocd.sh verify
```

This downloads the official manifest, calculates its SHA-256, compares it with the pinned value, and deletes the temporary file when finished.

### Install after verification

```bash
./scripts/bootstrap-argocd.sh apply
```

This performs the following actions:

1. Downloads and verifies the pinned manifest again.
2. Declaratively creates the `argocd` namespace if it does not exist.
3. Uses server-side apply for the official installation resources.
4. Uses `--force-conflicts`, as required by the official Argo CD installation instructions for its large CRDs.

### Inspect installation status

```bash
./scripts/bootstrap-argocd.sh status
```

This reads Deployments, StatefulSets, Pods, and Services from the `argocd` namespace. It does not change the cluster.

## Wait for the components

After applying, inspect the status and wait for the main workloads:

```bash
sudo k3s kubectl get pods \
  --namespace argocd \
  --watch
```

Stop watching with `Ctrl+C` after the Pods report `Running` and their containers report ready.

Then verify rollout status:

```bash
for deployment in \
  argocd-applicationset-controller \
  argocd-dex-server \
  argocd-notifications-controller \
  argocd-redis \
  argocd-repo-server \
  argocd-server; do
    sudo k3s kubectl rollout status \
      "deployment/$deployment" \
      --namespace argocd \
      --timeout 5m
done
```

The application controller may be a StatefulSet rather than a Deployment:

```bash
sudo k3s kubectl rollout status \
  statefulset/argocd-application-controller \
  --namespace argocd \
  --timeout 5m
```

## Initial UI access

Keep the Argo CD API server private initially.

On k801:

```bash
sudo k3s kubectl port-forward \
  --namespace argocd \
  service/argocd-server \
  8085:443
```

From admin01, create an SSH tunnel to that listener:

```bash
ssh \
  -L 8085:127.0.0.1:8085 \
  browne@10.10.0.130
```

Open this on admin01:

```text
https://127.0.0.1:8085
```

The browser will warn about the default self-signed certificate. Do not expose this interface through OPNsense or Traefik until authentication and TLS decisions have been reviewed.

## Initial administrator credential

Retrieve the generated password only when needed:

```bash
sudo k3s kubectl get secret \
  argocd-initial-admin-secret \
  --namespace argocd \
  --output jsonpath='{.data.password}' |
  base64 --decode

printf '\n'
```

The username is:

```text
admin
```

Do not place the decoded password in shell scripts, Git, screenshots, chat logs, or documentation.

## Next configuration step

After the installation is healthy, create a declarative Argo CD `Application` resource that watches:

```text
Repository: https://github.com/c0mtrex/homelab-platform.git
Revision: main
Path: kubernetes/staging
Destination: the in-cluster Kubernetes API
```

The first synchronization will remain manual. Automatic sync, pruning, and self-healing will be introduced separately so their effects can be observed safely.

## Official references

- [Argo CD installation](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/)
- [Argo CD getting started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Argo CD automated synchronization](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)
