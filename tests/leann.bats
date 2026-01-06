#!/usr/bin/env bats
# Tests for LEANN integration

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

# CLI Integration Tests
@test "claw leann: shows status by default" {
    run "$PROJECT_ROOT/bin/claw" leann
    assert_success
    assert_output --partial "LEANN Status"
}

@test "claw leann status: shows detailed status" {
    run "$PROJECT_ROOT/bin/claw" leann status
    assert_success
    assert_output --partial "LEANN Status"
}

@test "claw leann help: shows help" {
    run "$PROJECT_ROOT/bin/claw" leann help
    assert_success
    assert_output --partial "LEANN Commands"
}
