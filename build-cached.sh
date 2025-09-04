#!/bin/bash
# Optimized Docker build script with caching

set -e

# Enable BuildKit for cache mount support
export DOCKER_BUILDKIT=1

echo "Building Zephyr environment with cache optimization..."

# Build with cache mounts enabled
docker build \
  --progress=plain \
  --tag zephyr-env:latest \
  --tag zephyr-env:cached \
  .

echo "✅ Build completed with cache optimization!"
echo ""
echo "Cache benefits:"
echo "  - APT packages cached in /var/cache/apt and /var/lib/apt"
echo "  - Pip packages cached in /root/.cache/pip"
echo "  - npm packages cached in /root/.npm"
echo ""
echo "On subsequent builds, package downloads will be significantly faster!"