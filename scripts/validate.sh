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

printf '%s\n' "Checking tracked text files for CRLF line endings"
if git grep --files-with-matches "$(printf '\r')" -- '*.md' '*.sh' '*.yaml' '*.yml'; then
    printf '%s\n' "CRLF line endings found in tracked text files" >&2
    exit 1
fi

printf '%s\n' "Checking Docker Compose models"
run_docker compose --file docker/monitoring/compose.yaml config --quiet
run_docker compose --file docker/portainer/compose.yaml config --quiet
run_docker compose --file docker/service-health-api/compose.yaml config --quiet

printf '%s\n' "Checking Prometheus configuration"
run_docker run --rm \
    --entrypoint promtool \
    --volume "$repository_root/docker/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
    prom/prometheus:latest \
    check config /etc/prometheus/prometheus.yml

printf '%s\n' "Validation completed successfully"
