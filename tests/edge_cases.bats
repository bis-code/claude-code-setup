#!/usr/bin/env bats
# Edge case and error handling tests for simplified claw architecture

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
# Library Detection Tests
# ============================================================================

@test "detect_project_type: handles symlinks" {
    source "$PROJECT_ROOT/lib/detect-project.sh"
    mkdir -p "$TMP_DIR/real"
    cat > "$TMP_DIR/real/package.json" << 'EOF'
{"name": "test", "dependencies": {"react": "^18.0.0"}}
EOF
    ln -s "$TMP_DIR/real" "$TMP_DIR/link"

    run detect_project_type "$TMP_DIR/link"
    assert_success
    assert_output "web"
}

@test "detect_project_type: handles special characters in path" {
    source "$PROJECT_ROOT/lib/detect-project.sh"
    mkdir -p "$TMP_DIR/my project (test)"
    cat > "$TMP_DIR/my project (test)/package.json" << 'EOF'
{"name": "test", "dependencies": {"react": "^18.0.0"}}
EOF
    run detect_project_type "$TMP_DIR/my project (test)"
    assert_success
    assert_output "web"
}

@test "detect_project_type: handles empty package.json" {
    source "$PROJECT_ROOT/lib/detect-project.sh"
    echo "{}" > "$TMP_DIR/package.json"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "unknown"
}

@test "detect_project_type: handles package.json with only name" {
    source "$PROJECT_ROOT/lib/detect-project.sh"
    echo '{"name": "test"}' > "$TMP_DIR/package.json"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "unknown"
}

# ============================================================================
# Agent Library Tests
# ============================================================================

@test "get_agents_for_type: handles empty type" {
    source "$PROJECT_ROOT/lib/agents.sh"
    run get_agents_for_type ""
    assert_success
    # Should return default agents
    assert_output --partial "senior-dev"
}

@test "regression: agents.sh unbound variable fix" {
    source "$PROJECT_ROOT/lib/agents.sh"
    # This tests the fix for ${2:-} in get_agent_prompt
    run get_agent_prompt "senior-dev"
    assert_success
}

# ============================================================================
# Script Executable Tests
# ============================================================================

@test "install.sh: script is executable" {
    assert [ -x "$PROJECT_ROOT/install.sh" ]
}

@test "bin/claw: script is executable" {
    assert [ -x "$PROJECT_ROOT/bin/claw" ]
}

# ============================================================================
# Library Loading Tests
# ============================================================================

@test "lib/detect-project.sh: can be sourced" {
    run bash -c "source '$PROJECT_ROOT/lib/detect-project.sh' && echo 'ok'"
    assert_success
    assert_output "ok"
}

@test "lib/agents.sh: can be sourced" {
    run bash -c "source '$PROJECT_ROOT/lib/agents.sh' && echo 'ok'"
    assert_success
    assert_output "ok"
}

@test "lib/leann-setup.sh: can be sourced" {
    run bash -c "source '$PROJECT_ROOT/lib/leann-setup.sh' && echo 'ok'"
    assert_success
    assert_output "ok"
}

@test "lib/repos.sh: can be sourced" {
    run bash -c "source '$PROJECT_ROOT/lib/repos.sh' && echo 'ok'"
    assert_success
    assert_output "ok"
}

# ============================================================================
# Repos Edge Cases
# ============================================================================

@test "repos: handles special characters in repo name" {
    source "$PROJECT_ROOT/lib/repos.sh"
    # Standard repo names should work
    run repos_add "my-org/my-repo"
    assert_success
}

@test "repos: rejects invalid format without slash" {
    source "$PROJECT_ROOT/lib/repos.sh"
    # Should reject repo without owner/repo format
    run repos_add "invalid-no-slash"
    assert_failure
}

@test "repos: handles very long repo names" {
    source "$PROJECT_ROOT/lib/repos.sh"
    local long_name="org/$(printf 'a%.0s' {1..200})"
    run repos_add "$long_name"
    # Should still work - GitHub allows long names
    assert_success
}

@test "repos: list with corrupted json recovers gracefully" {
    source "$PROJECT_ROOT/lib/repos.sh"
    echo "not valid json" > "$CLAW_HOME/repos.json"
    run repos_list
    # Should not crash
    assert_success
}

# ============================================================================
# CLI Edge Cases
# ============================================================================

@test "claw: --version always shows claw version" {
    run "$PROJECT_ROOT/bin/claw" --version
    assert_success
    assert_output --partial "claw v"
}

@test "claw repos: unknown subcommand shows error" {
    run "$PROJECT_ROOT/bin/claw" repos unknown-subcommand
    assert_failure
    assert_output --partial "Unknown repos command"
}

@test "claw repos add: requires argument" {
    run "$PROJECT_ROOT/bin/claw" repos add
    assert_failure
    assert_output --partial "Usage"
}

@test "claw repos remove: requires argument" {
    run "$PROJECT_ROOT/bin/claw" repos remove
    assert_failure
    assert_output --partial "Usage"
}

# Note: Tests for old claw commands (init, detect, agents) removed
# The simplified claw is a drop-in replacement for claude with multi-repo support
