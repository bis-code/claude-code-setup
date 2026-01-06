#!/usr/bin/env bats
# Tests for LEANN library functions
# Note: CLI tests for `claw leann` removed - simplified claw doesn't have leann subcommand
# The library functions are still available via lib/leann-setup.sh

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
}

teardown() {
    rm -rf "$TMP_DIR"
}

# Installation Check Tests
@test "is_leann_installed: returns correct status" {
    run is_leann_installed
    # Should succeed if leann is installed, fail otherwise
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

@test "is_uv_installed: returns correct status" {
    run is_uv_installed
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

# Status Tests
@test "leann_status: outputs status information" {
    run leann_status
    assert_success
    assert_output --partial "LEANN Status"
}

@test "leann_status: shows installation status" {
    run leann_status
    assert_success
    assert_output --partial "Installed:"
}

# Agent Instructions Tests
@test "get_leann_agent_instructions: returns valid instructions" {
    run get_leann_agent_instructions
    assert_success
    assert_output --partial "LEANN"
}

@test "get_leann_agent_instructions: includes search guidance" {
    run get_leann_agent_instructions
    assert_success
    assert_output --partial "search"
}

# Injection Tests
@test "inject_leann_instructions: modifies target file" {
    local target="$TMP_DIR/CLAUDE.md"
    echo "# Project Instructions" > "$target"
    echo "" >> "$target"
    echo "## Development" >> "$target"

    run inject_leann_instructions "$target"
    assert_success

    run cat "$target"
    assert_output --partial "LEANN"
}

@test "inject_leann_instructions: handles missing file" {
    run inject_leann_instructions "$TMP_DIR/nonexistent.md"
    assert_failure
}

# Command Routing Tests
@test "leann_cmd: routes status command" {
    run leann_cmd status
    assert_success
    assert_output --partial "LEANN Status"
}

@test "leann_cmd: routes help command" {
    run leann_cmd help
    assert_success
    assert_output --partial "LEANN Commands"
}

@test "leann_cmd: handles unknown command" {
    run leann_cmd unknown-cmd
    assert_failure
}

# Fallback Search Tests
@test "fallback_search: searches files when LEANN unavailable" {
    mkdir -p "$TMP_DIR/src"
    echo "function testFunction() {}" > "$TMP_DIR/src/test.js"
    echo "const anotherFunction = () => {}" > "$TMP_DIR/src/another.js"

    cd "$TMP_DIR"
    run fallback_search "function"
    assert_success
    assert_output --partial "test.js"
}

@test "fallback_search: returns empty for no matches" {
    mkdir -p "$TMP_DIR/src"
    echo "const x = 1" > "$TMP_DIR/src/test.js"

    cd "$TMP_DIR"
    run fallback_search "nonexistent-pattern-xyz"
    # Should succeed but return no output
    assert_success
}

# Index Name Generation Tests
@test "get_index_name: generates name from directory" {
    cd "$TMP_DIR"
    mkdir -p "my-project"
    cd "my-project"
    run get_index_name
    assert_success
    assert_output "my-project"
}

@test "get_index_name: sanitizes uppercase" {
    cd "$TMP_DIR"
    mkdir -p "MyProject"
    cd "MyProject"
    run get_index_name
    assert_success
    assert_output "myproject"
}

@test "get_index_name: sanitizes special characters" {
    cd "$TMP_DIR"
    mkdir -p "my_project.test"
    cd "my_project.test"
    run get_index_name
    assert_success
    # Special chars replaced with dashes
    assert_output "my-project-test"
}

# Index Exists Tests (mocked - can't test real leann without it installed)
@test "index_exists: returns false when leann not installed" {
    # Temporarily override is_leann_installed
    is_leann_installed() { return 1; }
    export -f is_leann_installed

    run index_exists "test-index"
    assert_failure
}

# Search with fallback Tests
@test "search_index: falls back to grep when leann not installed" {
    # Create test files
    mkdir -p "$TMP_DIR/src"
    echo "authentication handler code" > "$TMP_DIR/src/auth.js"

    # Override is_leann_installed to return false
    is_leann_installed() { return 1; }
    export -f is_leann_installed

    cd "$TMP_DIR"
    run search_index "authentication"
    assert_success
    assert_output --partial "auth.js"
}

@test "search_index: shows usage when no query" {
    run search_index ""
    assert_failure
    assert_output --partial "Usage:"
}

# Install LEANN Tests (mocked)
@test "install_leann: fails when no package manager available" {
    # Override all package manager checks to return false
    command() {
        case "$2" in
            pipx|uv|pip) return 1 ;;
            *) builtin command "$@" ;;
        esac
    }
    export -f command

    run install_leann
    assert_failure
    assert_output --partial "No package manager found"
}

# Build Index Tests
@test "build_index: uses directory name as default index" {
    cd "$TMP_DIR"
    mkdir -p "test-project"
    cd "test-project"

    # Mock is_leann_installed to return true
    is_leann_installed() { return 0; }
    export -f is_leann_installed

    # Mock leann build to just echo
    leann() { echo "leann $*"; }
    export -f leann

    run build_index
    assert_success
    assert_output --partial "test-project"
}

@test "build_index: accepts custom index name" {
    cd "$TMP_DIR"

    is_leann_installed() { return 0; }
    export -f is_leann_installed

    leann() { echo "leann $*"; }
    export -f leann

    run build_index "custom-index" "."
    assert_success
    assert_output --partial "custom-index"
}

# Note: CLI integration tests for `claw leann` removed
# The simplified claw is a drop-in replacement for claude with multi-repo support
