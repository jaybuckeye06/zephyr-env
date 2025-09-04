#!/bin/bash
set -e

# Initialize workspace script for Zephyr development
# This script sets up a workspace to use the pre-cached Zephyr installation

WORKSPACE_DIR=${1:-$(pwd)}
ZEPHYR_PROJECT_ROOT="/opt/zephyr-project"

echo "Initializing Zephyr workspace in: $WORKSPACE_DIR"

# Create .west directory structure
mkdir -p "$WORKSPACE_DIR/.west"

# Create west config that points to the pre-cached Zephyr
cat > "$WORKSPACE_DIR/.west/config" << EOF
[manifest]
path = .
file = west.yml

[zephyr]
base = $ZEPHYR_PROJECT_ROOT/zephyr
EOF

# Create a basic west.yml if it doesn't exist
if [ ! -f "$WORKSPACE_DIR/west.yml" ]; then
    echo "Creating default west.yml..."
    cat > "$WORKSPACE_DIR/west.yml" << EOF
manifest:
  self:
    west-commands: scripts/west-commands.yml

  remotes:
    - name: zephyrproject-rtos
      url-base: https://github.com/zephyrproject-rtos

  projects:
    - name: zephyr
      remote: zephyrproject-rtos
      revision: v4.1.0
      import:
        name-allowlist:
          - cmsis
          - hal_nxp
          - hal_nordic
          - hal_stm32
          - hal_rpi_pico
          - hal_espressif
          - littlefs
          - mcuboot
          - mbedtls
          - net-tools
          - segger
          - tinycrypt
          - zcbor
EOF
fi

# Set up environment variables
export ZEPHYR_BASE="$ZEPHYR_PROJECT_ROOT/zephyr"
export ZEPHYR_PROJECT_ROOT="$ZEPHYR_PROJECT_ROOT"

echo "✅ Workspace initialized successfully!"
echo "   ZEPHYR_BASE: $ZEPHYR_BASE"
echo "   Workspace: $WORKSPACE_DIR"
echo ""
echo "To update modules (excluding Zephyr core): west update --exclude-west"
echo "To build: west build -b <board> <app>"