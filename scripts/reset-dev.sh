#!/bin/zsh
set -e

echo "=== Stopping and removing dev containers & volumes ==="
docker-compose -f ../docker-compose.dev.yml down -v --remove-orphans

echo "=== Pruning unused Docker resources (images, networks, volumes) ==="
docker system prune -af --volumes

echo "=== Rebuilding images without cache ==="
docker-compose -f ../docker-compose.dev.yml build --no-cache

echo "=== Starting dev environment ==="
docker-compose -f ../docker-compose.dev.yml up
