#!/bin/sh
set -eu

argocd_version="v3.5.2"
manifest_sha256="9a87f2b3e14c278f12501eb0ef5c3955b27cf05370ca425381c6a908cf85a5c5"
manifest_url="https://raw.githubusercontent.com/argoproj/argo-cd/${argocd_version}/manifests/install.yaml"

run_kubectl() {
    if command -v k3s >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            k3s kubectl "$@"
        else
            sudo k3s kubectl "$@"
        fi
    elif command -v kubectl >/dev/null 2>&1; then
        kubectl "$@"
    else
        printf '%s\n' "Neither k3s nor kubectl is installed" >&2
        exit 1
    fi
}

download_and_verify_manifest() {
    manifest_file=$(mktemp)
    trap 'rm -f "$manifest_file"' EXIT HUP INT TERM

    printf 'Downloading Argo CD %s installation manifest\n' "$argocd_version"
    curl \
        --fail \
        --location \
        --silent \
        --show-error \
        "$manifest_url" \
        --output "$manifest_file"

    actual_sha256=$(sha256sum "$manifest_file" | awk '{print $1}')
    if [ "$actual_sha256" != "$manifest_sha256" ]; then
        printf 'Argo CD manifest checksum mismatch\n' >&2
        printf 'Expected: %s\n' "$manifest_sha256" >&2
        printf 'Actual:   %s\n' "$actual_sha256" >&2
        exit 1
    fi

    printf 'Verified manifest SHA-256: %s\n' "$actual_sha256"
}

show_status() {
    run_kubectl get \
        deployment,statefulset,pods,service \
        --namespace argocd \
        --output wide
}

usage() {
    printf 'Usage: %s verify|apply|status\n' "$0" >&2
}

case "${1:-}" in
    verify)
        download_and_verify_manifest
        printf '%s\n' "Verification completed without changing the cluster"
        ;;
    apply)
        download_and_verify_manifest

        run_kubectl create namespace argocd \
            --dry-run=client \
            --output yaml |
            run_kubectl apply --filename -

        run_kubectl apply \
            --namespace argocd \
            --server-side \
            --force-conflicts \
            --filename "$manifest_file"

        printf '%s\n' "Argo CD resources submitted to the cluster"
        printf 'Inspect them with: %s status\n' "$0"
        ;;
    status)
        show_status
        ;;
    *)
        usage
        exit 2
        ;;
esac
