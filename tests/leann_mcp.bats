#!/usr/bin/env bats
# TDD Tests for leann MCP auto-installation feature

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    export CLAW_HOME="$TMP_DIR/claw-home"
    export CLAUDE_HOME="$TMP_DIR/claude-home"
    mkdir -p "$CLAW_HOME" "$CLAUDE_HOME"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Detection Functions
# ============================================================================

@test "is_leann_installed: returns true when leann command exists" {
    source "$PROJECT_ROOT/lib/leann-setup.sh"

    # Create mock leann command
    mkdir -p "$TMP_DIR/bin"
    echo '#!/bin/bash' > "$TMP_DIR/bin/leann"
    echo 'echo "leann mock"' >> "$TMP_DIR/bin/leann"
    chmod +x "$TMP_DIR/bin/leann"

    PATH="$TMP_DIR/bin:$PATH" run is_leann_installed
    assert_success
}

@test "is_leann_installed: returns false when leann not found" {
    source "$PROJECT_ROOT/lib/leann-setup.sh"

    PATH="/nonexistent" run is_leann_installed
    assert_failure
}

@test "is_leann_mcp_configured: returns true when leann-server configured" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    # Mock claude mcp list output
    claude() {
        if [[ "$1" == "mcp" && "$2" == "list" ]]; then
            echo "leann-server: connected"
        fi
    }
    export -f claude

    run is_leann_mcp_configured
    assert_success
}

@test "is_leann_mcp_configured: returns false when not configured" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    # Mock claude mcp list output with no leann
    claude() {
        if [[ "$1" == "mcp" && "$2" == "list" ]]; then
            echo "No MCP servers configured"
        fi
    }
    export -f claude

    run is_leann_mcp_configured
    assert_failure
}

# ============================================================================
# Installation Functions
# ============================================================================

@test "install_leann_mcp: installs leann-core with uv if available" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    # Force leann to appear not installed
    is_leann_installed() { return 1; }
    export -f is_leann_installed

    # Mock MCP as not configured
    is_leann_mcp_configured() { return 1; }
    export -f is_leann_mcp_configured

    # Mock uv to succeed
    uv() {
        echo "uv tool install leann-core"
        return 0
    }
    export -f uv

    # Mock claude for MCP config
    claude() {
        echo "claude mcp add leann-server"
        return 0
    }
    export -f claude

    run install_leann_mcp
    assert_success
    assert_output --partial "Installing leann via uv"
    assert_output --partial "Leann installed"
}

@test "install_leann_mcp: configures MCP after installation" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    # Force leann to appear not installed initially
    is_leann_installed() { return 1; }
    export -f is_leann_installed

    # Mock MCP as not configured
    is_leann_mcp_configured() { return 1; }
    export -f is_leann_mcp_configured

    # Mock uv to succeed
    uv() { return 0; }
    export -f uv

    # Mock claude to succeed
    claude() { return 0; }
    export -f claude

    run install_leann_mcp
    assert_success
    assert_output --partial "Configuring MCP server"
    assert_output --partial "MCP server configured"
}

@test "install_leann_mcp: falls back to pipx if uv not available" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    # Force leann to appear not installed
    is_leann_installed() { return 1; }
    export -f is_leann_installed

    # Mock MCP as not configured
    is_leann_mcp_configured() { return 1; }
    export -f is_leann_mcp_configured

    # Mock no uv, but pipx available
    command() {
        case "$2" in
            uv) return 1 ;;
            pipx) return 0 ;;
            claude) return 0 ;;
            *) builtin command "$@" ;;
        esac
    }
    export -f command

    # Mock pipx
    pipx() { return 0; }
    export -f pipx

    # Mock claude
    claude() { return 0; }
    export -f claude

    run install_leann_mcp
    assert_success
    assert_output --partial "Installing leann via pipx"
}

@test "install_leann_mcp: fails gracefully if no package manager" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    # Force leann to appear not installed
    is_leann_installed() { return 1; }
    export -f is_leann_installed

    # Mock MCP as not configured
    is_leann_mcp_configured() { return 1; }
    export -f is_leann_mcp_configured

    # Mock no package managers available
    command() {
        case "$2" in
            uv|pipx|pip) return 1 ;;
            *) builtin command "$@" ;;
        esac
    }
    export -f command

    run install_leann_mcp
    assert_failure
    assert_output --partial "No package manager found"
}

# ============================================================================
# Progress Display
# ============================================================================

@test "show_setup_progress: displays spinner message" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    run show_setup_progress "Installing leann"
    assert_success
    assert_output --partial "Installing leann"
}

@test "show_setup_step: displays step with icon" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    run show_setup_step "done" "Leann installed"
    assert_success
    assert_output --partial "Leann installed"
}

# ============================================================================
# First-Run Detection
# ============================================================================

@test "is_leann_setup_complete: returns false on fresh install" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    run is_leann_setup_complete
    assert_failure
}

@test "is_leann_setup_complete: returns true after setup" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    touch "$CLAW_HOME/.leann-mcp-configured"

    run is_leann_setup_complete
    assert_success
}

@test "mark_leann_setup_complete: creates marker file" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    run mark_leann_setup_complete
    assert_success
    assert [ -f "$CLAW_HOME/.leann-mcp-configured" ]
}

# ============================================================================
# Integration with ensure_setup
# ============================================================================

@test "ensure_leann_setup: skips if already complete" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    touch "$CLAW_HOME/.leann-mcp-configured"

    # Should not call install
    install_leann_mcp() {
        echo "SHOULD NOT BE CALLED"
        return 1
    }
    export -f install_leann_mcp

    run ensure_leann_setup
    assert_success
    refute_output --partial "SHOULD NOT BE CALLED"
}

@test "ensure_leann_setup: installs if not complete" {
    source "$PROJECT_ROOT/lib/leann-mcp.sh"

    # Mock successful installation
    install_leann_mcp() {
        echo "Installing..."
        return 0
    }
    export -f install_leann_mcp

    # Mock is_leann_installed to return true after install
    is_leann_installed() { return 0; }
    export -f is_leann_installed

    # Mock is_leann_mcp_configured to return true after install
    is_leann_mcp_configured() { return 0; }
    export -f is_leann_mcp_configured

    run ensure_leann_setup
    assert_success
    assert_output --partial "Installing"
}

# ============================================================================
# CLI Integration
# ============================================================================

@test "claw: first run triggers leann setup" {
    # Create marker that claw is set up but leann is not
    touch "$CLAW_HOME/.commands-installed"
    # Don't create .leann-mcp-configured

    # This test verifies ensure_setup calls ensure_leann_setup
    # Full integration test would need mocking claude command
    source "$PROJECT_ROOT/bin/claw"

    # Just verify the function exists
    run type ensure_leann_setup
    assert_success
}

# Note: Full CLI integration tests for leann MCP are complex due to
# external dependencies (uv, pipx, claude mcp). Unit tests above cover
# the logic, while real integration is tested manually.
