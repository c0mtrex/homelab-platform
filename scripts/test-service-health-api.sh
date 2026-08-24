#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
image_name="service-health-api:ci"
network_name="service-health-api-ci-$$"
dependency_name="service-health-dependency-$$"
application_name="service-health-api-ci-$$"

run_docker() {
    if [ -w /var/run/docker.sock ]; then
        docker "$@"
    else
        sudo docker "$@"
    fi
}

cleanup() {
    run_docker rm --force "$application_name" "$dependency_name" >/dev/null 2>&1 || true
    run_docker network rm "$network_name" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

printf '%s\n' "Building service-health API test image"
run_docker build \
    --tag "$image_name" \
    "$repository_root/docker/service-health-api"

printf '%s\n' "Creating isolated test network"
run_docker network create "$network_name" >/dev/null

printf '%s\n' "Starting a healthy dependency"
run_docker run --detach \
    --name "$dependency_name" \
    --network "$network_name" \
    "$image_name" >/dev/null

printf '%s\n' "Starting API under test"
run_docker run --detach \
    --name "$application_name" \
    --network "$network_name" \
    --publish 127.0.0.1::8000 \
    --env "DEPENDENCY_URL=http://$dependency_name:8000/health" \
    "$image_name" >/dev/null

host_port=$(run_docker port "$application_name" 8000/tcp | sed 's/.*://')
base_url="http://127.0.0.1:$host_port"

attempt=1
while [ "$attempt" -le 20 ]; do
    if curl --fail --silent --show-error "$base_url/health" >/dev/null 2>&1; then
        break
    fi
    sleep 1
    attempt=$((attempt + 1))
done

if [ "$attempt" -gt 20 ]; then
    printf '%s\n' "API did not become healthy" >&2
    run_docker logs "$application_name" >&2
    exit 1
fi

printf '%s\n' "Checking liveness response"
curl --fail --silent --show-error "$base_url/health" |
    grep --quiet '"status":"healthy"'

printf '%s\n' "Checking readiness response"
curl --fail --silent --show-error "$base_url/ready" |
    grep --quiet '"status":"ready"'

printf '%s\n' "Checking metrics response"
curl --fail --silent --show-error "$base_url/metrics" |
    grep --quiet '^service_health_http_requests_total'

printf '%s\n' "Checking non-root runtime user"
test "$(run_docker inspect "$application_name" --format '{{.Config.User}}')" = "app"

printf '%s\n' "Service-health API tests completed successfully"
