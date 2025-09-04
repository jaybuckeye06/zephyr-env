#!/bin/bash
set -e

echo "Installing Zephyr Development Environment Feature..."

# Get feature options
ENABLE_DEBUGGING=${ENABLEDEBUGGING:-true}
ENABLE_CODE_QUALITY=${ENABLECODEQUALITY:-true} 
ENABLE_CLAUDE=${ENABLECLAUDE:-true}

# Install additional tools if code quality is enabled
if [ "$ENABLE_CODE_QUALITY" = "true" ]; then
    echo "Installing code quality tools..."
    apt-get update
    apt-get install -y clang-format clang-tidy cppcheck
    pip3 install pre-commit
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

# Install Claude Code if enabled
if [ "$ENABLE_CLAUDE" = "true" ]; then
    echo "Installing Claude Code CLI..."
    if ! command -v node >/dev/null 2>&1; then
        echo "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    fi
    npm install -g @anthropic-ai/claude-code || echo "Claude Code installation failed, continuing..."
fi

# Create development scripts directory
mkdir -p /usr/local/bin/zephyr-scripts

# Install development aliases script
cat > /usr/local/bin/zephyr-scripts/dev-aliases.sh << 'EOF'
#!/bin/bash
# Zephyr Development Aliases and Helper Functions

# Build aliases
alias zb='west build'
alias zbr='west build -t run'
alias zbc='west build -t clean'
alias zbf='west build -t flash'
alias zbm='west build -t menuconfig'

# Common board shortcuts
alias zb_nrf52840dk='west build -b nrf52840dk_nrf52840'
alias zb_nucleo='west build -b nucleo_f429zi'
alias zb_esp32='west build -b esp32_devkitc_wroom'
alias zb_rpi_pico='west build -b rpi_pico'

# West shortcuts
alias wu='west update --exclude-west'
alias wf='west flash'
alias wd='west debug'
alias ws='west build -t menuconfig'

# Load environment variables
export ZEPHYR_BASE="/opt/zephyr-project/zephyr"
export ZEPHYR_PROJECT_ROOT="/opt/zephyr-project"
export PATH="/opt/JLink:$PATH"

# Claude Code aliases
if command -v claude-code >/dev/null 2>&1; then
    alias cc='claude-code'
    alias cchelp='claude-code --help'
fi

echo "Zephyr development environment loaded!"
echo "Available aliases: zb, zbr, zbc, zbf, zbm, wu, wf, wd"
echo "Board shortcuts: zb_nrf52840dk, zb_nucleo, zb_esp32, zb_rpi_pico"
EOF

chmod +x /usr/local/bin/zephyr-scripts/dev-aliases.sh

# Add to bashrc for all users
echo "source /usr/local/bin/zephyr-scripts/dev-aliases.sh" >> /etc/bash.bashrc

# Install workspace initialization script
cat > /usr/local/bin/zephyr-scripts/init-workspace.sh << 'EOF'
#!/bin/bash
set -e

WORKSPACE_DIR=${1:-$(pwd)}
ZEPHYR_PROJECT_ROOT="/opt/zephyr-project"

echo "Initializing Zephyr workspace in: $WORKSPACE_DIR"

# Create .west directory structure
mkdir -p "$WORKSPACE_DIR/.west"

# Create west config that points to the pre-cached Zephyr
cat > "$WORKSPACE_DIR/.west/config" << WESTEOF
[manifest]
path = .
file = west.yml

[zephyr]
base = $ZEPHYR_PROJECT_ROOT/zephyr
WESTEOF

# Create a basic west.yml if it doesn't exist
if [ ! -f "$WORKSPACE_DIR/west.yml" ]; then
    echo "Creating default west.yml..."
    cat > "$WORKSPACE_DIR/west.yml" << WESTEOF
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
WESTEOF
fi

export ZEPHYR_BASE="$ZEPHYR_PROJECT_ROOT/zephyr"
export ZEPHYR_PROJECT_ROOT="$ZEPHYR_PROJECT_ROOT"

echo "✅ Workspace initialized successfully!"
echo "   ZEPHYR_BASE: $ZEPHYR_BASE"
echo "   Workspace: $WORKSPACE_DIR"
echo ""
echo "To update modules (excluding Zephyr core): west update --exclude-west"
echo "To build: west build -b <board> <app>"
EOF

chmod +x /usr/local/bin/zephyr-scripts/init-workspace.sh

# Install code quality script if enabled
if [ "$ENABLE_CODE_QUALITY" = "true" ]; then
    cat > /usr/local/bin/zephyr-scripts/code-quality.sh << 'EOF'
#!/bin/bash
# Code quality tools for Zephyr development

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_format() {
    print_status "Checking code format with clang-format..."
    
    files=$(find . -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.hpp" | grep -v build)
    
    if [ -z "$files" ]; then
        print_warning "No C/C++ files found to format"
        return 0
    fi
    
    format_issues=0
    for file in $files; do
        if ! clang-format --dry-run --Werror "$file" >/dev/null 2>&1; then
            print_error "Format issues in $file"
            format_issues=$((format_issues + 1))
        fi
    done
    
    if [ $format_issues -eq 0 ]; then
        print_status "All files are properly formatted ✓"
    else
        print_error "Found formatting issues in $format_issues files"
        return 1
    fi
}

format_code() {
    print_status "Formatting code with clang-format..."
    
    files=$(find . -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.hpp" | grep -v build)
    
    for file in $files; do
        clang-format -i "$file"
        echo "Formatted: $file"
    done
    
    print_status "Code formatting completed ✓"
}

case "$1" in
    "check") check_format ;;
    "format") format_code ;;
    *) echo "Usage: $0 {check|format}" ;;
esac
EOF

    chmod +x /usr/local/bin/zephyr-scripts/code-quality.sh
fi

# Add scripts to PATH
echo 'export PATH="/usr/local/bin/zephyr-scripts:$PATH"' >> /etc/bash.bashrc

echo "✅ Zephyr Development Environment Feature installed successfully!"