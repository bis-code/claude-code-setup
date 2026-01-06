#!/usr/bin/env bash
#
# install.sh - Installation script for claw
#

set -euo pipefail

# Parse arguments
PREFIX="${PREFIX:-/usr/local}"
USE_SUDO=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            PREFIX="$2"
            USE_SUDO=false  # Don't use sudo for custom prefix
            shift 2
            ;;
        --no-sudo)
            USE_SUDO=false
            shift
            ;;
        *)
            shift
            ;;
    esac
done

BIN_DIR="${PREFIX}/bin"
LIB_DIR="${PREFIX}/lib/claw"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing claw to $PREFIX..."

# Create directories
if $USE_SUDO; then
    sudo mkdir -p "$BIN_DIR"
    sudo mkdir -p "$LIB_DIR"
    sudo cp -r "$SCRIPT_DIR/lib/"* "$LIB_DIR/"
    sudo cp -r "$SCRIPT_DIR/templates" "$LIB_DIR/"
    sudo cp "$SCRIPT_DIR/bin/claw" "$BIN_DIR/"
    sudo chmod +x "$BIN_DIR/claw"
else
    mkdir -p "$BIN_DIR"
    mkdir -p "$LIB_DIR"
    cp -r "$SCRIPT_DIR/lib/"* "$LIB_DIR/"
    cp -r "$SCRIPT_DIR/templates" "$LIB_DIR/"
    cp "$SCRIPT_DIR/bin/claw" "$BIN_DIR/"
    chmod +x "$BIN_DIR/claw"
fi

echo "Installed to $BIN_DIR/claw"
echo ""
echo "Run 'claw help' to get started."
