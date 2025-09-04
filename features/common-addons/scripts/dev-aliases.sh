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
alias wu='west update --exclude-west'  # Update modules but not Zephyr core
alias wf='west flash'
alias wd='west debug'
alias ws='west build -t menuconfig'

# Git shortcuts for Zephyr development
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -10'

# Helper functions
zephyr_init() {
    local board=${1:-nrf52840dk_nrf52840}
    local app=${2:-hello_world}
    
    echo "Initializing Zephyr project for board: $board, app: $app"
    /opt/zephyr-project/scripts/init-workspace.sh
    west build -b "$board" "/opt/zephyr-project/zephyr/samples/hello_world"
}

zephyr_clean_build() {
    local board=${1:-nrf52840dk_nrf52840}
    local app=${2:-.}
    
    echo "Clean building for board: $board"
    rm -rf build
    west build -b "$board" "$app"
}

zephyr_menuconfig() {
    west build -t menuconfig
    echo "Configuration saved. Run 'west build' to rebuild with new config."
}

zephyr_size() {
    if [ -f "build/zephyr/zephyr.elf" ]; then
        arm-zephyr-eabi-size build/zephyr/zephyr.elf
        echo ""
        echo "Memory usage details:"
        west build -t ram_report
        west build -t rom_report
    else
        echo "No build found. Run 'west build' first."
    fi
}

# Load environment variables
export ZEPHYR_BASE="/opt/zephyr-project/zephyr"
export ZEPHYR_PROJECT_ROOT="/opt/zephyr-project"
export PATH="/opt/JLink:$PATH"

# Claude Code aliases
if command -v claude >/dev/null 2>&1; then
    alias cc='claude'
    alias cchelp='claude --help'
    alias ccdoctor='claude doctor'
fi

# Set up completions if available
if command -v west >/dev/null 2>&1; then
    eval "$(west completion bash 2>/dev/null || true)"
fi

echo "Zephyr development environment loaded!"
echo "Available aliases: zb, zbr, zbc, zbf, zbm, wu, wf, wd"
echo "Board shortcuts: zb_nrf52840dk, zb_nucleo, zb_esp32, zb_rpi_pico"
echo "Helper functions: zephyr_init, zephyr_clean_build, zephyr_menuconfig, zephyr_size"