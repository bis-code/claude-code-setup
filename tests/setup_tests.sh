#!/usr/bin/env bash
# Setup script for test dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up test dependencies..."

# Install BATS
if [ ! -d "$SCRIPT_DIR/bats" ]; then
    echo "Installing BATS..."
    git clone --depth 1 https://github.com/bats-core/bats-core.git "$SCRIPT_DIR/bats"
fi

# Install bats-support
if [ ! -d "$SCRIPT_DIR/test_helper/bats-support" ]; then
    echo "Installing bats-support..."
    mkdir -p "$SCRIPT_DIR/test_helper"
    git clone --depth 1 https://github.com/bats-core/bats-support.git "$SCRIPT_DIR/test_helper/bats-support"
fi

# Install bats-assert
if [ ! -d "$SCRIPT_DIR/test_helper/bats-assert" ]; then
    echo "Installing bats-assert..."
    git clone --depth 1 https://github.com/bats-core/bats-assert.git "$SCRIPT_DIR/test_helper/bats-assert"
fi

echo "Test dependencies installed!"
echo ""
echo "Run tests with:"
echo "  $SCRIPT_DIR/bats/bin/bats $SCRIPT_DIR/"
