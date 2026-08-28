#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repository_root"

run_docker() {
    if [ -w /var/run/docker.sock ]; then
        docker "$@"
    else
        sudo docker "$@"
    fi
}
kubeconform_image="ghcr.io/yannh/kubeconform:v0.8.0-alpine@sha256:461fae0fa54c5fe64028152533e57f6b88adb1d26dbafd80092e7310d349ae48"

printf '%s\n' "Checking tracked text files for CRLF line endings"
if git grep --files-with-matches "$(printf '\r')" -- '*.md' '*.sh' '*.yaml' '*.yml'; then
    printf '%s\n' "CRLF line endings found in tracked text files" >&2
    exit 1
fi

printf '%s\n' "Checking Docker Compose models"
run_docker compose --file docker/monitoring/compose.yaml config --quiet
run_docker compose --file docker/portainer/compose.yaml config --quiet
run_docker compose --file docker/service-health-api/compose.yaml config --quiet

printf '%s\n' "Checking Kubernetes manifests"
run_docker run --rm \
    --volume "$repository_root:/work:ro" \
    --workdir /work \
    "$kubeconform_image" \
    -kubernetes-version 1.36.0 \
    -strict \
    -summary \
    -verbose \
    kubernetes

printf '%s\n' "Checking Grafana dashboard definitions"
  for dashboard_file in docker/monitoring/grafana/dashboards/*.json; do
      [ -f "$dashboard_file" ] || continue

      jq -e '
          .apiVersion == "dashboard.grafana.app/v2" and
          .kind == "Dashboard" and
          (.metadata.name | type == "string" and length > 0) and
          (.metadata | has("generation") | not) and
          (.metadata | has("creationTimestamp") | not) and
          (.spec.title | type == "string" and length > 0) and
          (.spec.elements | type == "object" and length > 0) and
          ([
              .. |
              objects |
              select(.kind? == "DataQuery" and .group? == "prometheus")
          ] | length > 0) and
          all(
              .. |
              objects |
              select(.kind? == "DataQuery" and .group? == "prometheus");
              (.datasource.name? | type == "string" and length > 0)
          )
      ' "$dashboard_file" >/dev/null
  done



printf '%s\n' "Checking Prometheus configuration"
run_docker run --rm \
    --entrypoint promtool \
    --volume "$repository_root/docker/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
    prom/prometheus:latest \
    check config /etc/prometheus/prometheus.yml

printf '%s\n' "Validation completed successfully"
