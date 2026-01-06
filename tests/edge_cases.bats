#!/usr/bin/env bats
# Edge case and error handling tests

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

# Unknown Command Tests
@test "claw: handles unknown command" {
    run "$PROJECT_ROOT/bin/claw" unknown-command
    assert_failure
    assert_output --partial "Unknown"
}

# Invalid Preset Tests
@test "claw init: handles invalid preset" {
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" init --preset invalid-preset
    assert_failure
    assert_output --partial "Unknown preset"
}

# Missing Argument Tests
@test "claw agents spawn: handles missing agent name" {
    run "$PROJECT_ROOT/bin/claw" agents spawn
    assert_failure
    assert_output --partial "Usage"
}

# Symlink Tests
@test "detect_project_type: handles symlinks" {
    mkdir -p "$TMP_DIR/real"
    cat > "$TMP_DIR/real/package.json" << 'EOF'
{"name": "test", "dependencies": {"react": "^18.0.0"}}
EOF
    ln -s "$TMP_DIR/real" "$TMP_DIR/link"

    run detect_project_type "$TMP_DIR/link"
    assert_success
    assert_output "web"
}

# Special Characters Tests
@test "detect_project_type: handles special characters in path" {
    mkdir -p "$TMP_DIR/my project (test)"
    cat > "$TMP_DIR/my project (test)/package.json" << 'EOF'
{"name": "test", "dependencies": {"react": "^18.0.0"}}
EOF
    run detect_project_type "$TMP_DIR/my project (test)"
    assert_success
    assert_output "web"
}

@test "claw init: handles directory with special characters" {
    mkdir -p "$TMP_DIR/my project (test)"
    cd "$TMP_DIR/my project (test)"
    run "$PROJECT_ROOT/bin/claw" init --preset base
    assert_success
    assert [ -d ".claude" ]
}

# Empty/Malformed Config Tests
@test "detect_project_type: handles empty package.json" {
    echo "{}" > "$TMP_DIR/package.json"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "unknown"
}

@test "detect_project_type: handles package.json with only name" {
    echo '{"name": "test"}' > "$TMP_DIR/package.json"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "unknown"
}

@test "get_agents_for_type: handles empty type" {
    run get_agents_for_type ""
    assert_success
    # Should return default agents
    assert_output --partial "senior-dev"
}

# Existing Directory Tests
@test "claw init: handles existing .claude directory" {
    mkdir -p "$TMP_DIR/.claude/commands"
    echo "existing content" > "$TMP_DIR/.claude/commands/test.md"
    cd "$TMP_DIR"

    run "$PROJECT_ROOT/bin/claw" init --preset base
    assert_success
    # Should not destroy existing content
    assert [ -f ".claude/commands/test.md" ]
}

# Version Tests
@test "claw version: includes version number" {
    run "$PROJECT_ROOT/bin/claw" version
    assert_success
    assert_output --partial "v"
}

# Script Executable Tests
@test "install.sh: script is executable" {
    assert [ -x "$PROJECT_ROOT/install.sh" ]
}

@test "bin/claw: script is executable" {
    assert [ -x "$PROJECT_ROOT/bin/claw" ]
}

# Library Loading Tests
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

# Output Format Tests
@test "claw detect: outputs valid structure" {
    mkdir -p "$TMP_DIR"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "test", "dependencies": {"react": "^18.0.0"}}
EOF
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "Project Type:"
}

@test "claw help: shows all main commands" {
    run "$PROJECT_ROOT/bin/claw" help
    assert_success
    assert_output --partial "init"
    assert_output --partial "detect"
    assert_output --partial "agents"
    assert_output --partial "leann"
}

# Preset Tests
@test "claw init --preset full: works" {
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" init --preset full
    assert_success
}

@test "claw init --preset base: works" {
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" init --preset base
    assert_success
}

@test "claw init --preset slim: works" {
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" init --preset slim
    assert_success
}

# Regression Tests
@test "regression: agents.sh regression: agents.sh \$2 unbound variable fix unbound variable fix" {
    # This tests the fix for ${2:-} in get_agent_prompt
    run get_agent_prompt "senior-dev"
    assert_success
}

@test "regression: detect_multi_repo returns 0 for no detection" {
    mkdir -p "$TMP_DIR/isolated"
    run detect_multi_repo "$TMP_DIR/isolated"
    assert_success
}
