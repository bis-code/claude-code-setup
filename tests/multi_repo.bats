#!/usr/bin/env bats
# Tests for multi-repo functionality

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

# Multi-Repo Detection Tests
@test "detect_multi_repo: detects sibling repos by pattern" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/game" "$parent/frontend" "$parent/backend"

    run detect_multi_repo "$parent/game"
    assert_success
    assert_output --partial "detected"
}

@test "detect_multi_repo: reads existing config file" {
    mkdir -p "$TMP_DIR/.claw"
    cat > "$TMP_DIR/.claw/multi-repo.json" << 'EOF'
{
    "detected": true,
    "repos": ["repo1", "repo2"]
}
EOF
    run detect_multi_repo "$TMP_DIR"
    assert_success
    assert_output --partial "detected"
}

@test "detect_multi_repo: checks parent directory config" {
    local parent="$TMP_DIR/parent"
    local child="$parent/child"
    mkdir -p "$parent/.claw" "$child"

    cat > "$parent/.claw/multi-repo.json" << 'EOF'
{
    "detected": true,
    "repos": ["child", "sibling"]
}
EOF
    run detect_multi_repo "$child"
    assert_success
}

@test "detect_multi_repo: returns false for isolated repo" {
    mkdir -p "$TMP_DIR/isolated"
    run detect_multi_repo "$TMP_DIR/isolated"
    assert_success
    assert_output --partial '"detected": false'
}

# Cross-Repo Dependency Tests
@test "detect_cross_repo_dependencies: returns empty array by default" {
    run detect_cross_repo_dependencies "$TMP_DIR"
    assert_success
    assert_output "[]"
}

# Config Creation Tests
@test "create_multi_repo_config: creates config file" {
    mkdir -p "$TMP_DIR"
    run create_multi_repo_config "$TMP_DIR"
    assert_success
    assert [ -f "$TMP_DIR/.claw/multi-repo.json" ]
}

@test "create_multi_repo_config: creates .claw directory" {
    mkdir -p "$TMP_DIR"
    run create_multi_repo_config "$TMP_DIR"
    assert_success
    assert [ -d "$TMP_DIR/.claw" ]
}

# CLI Integration Tests
@test "claw multi-repo detect: runs detection" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/game" "$parent/frontend"
    cd "$parent/game"

    run "$PROJECT_ROOT/bin/claw" multi-repo detect
    assert_success
}

@test "claw multi-repo config: creates config" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    run "$PROJECT_ROOT/bin/claw" multi-repo config
    assert_success
    assert [ -d ".claw" ]
}

@test "claw multi-repo issues: attempts to fetch issues" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    run "$PROJECT_ROOT/bin/claw" multi-repo issues
    # May fail if not in a git repo with remote, but shouldn't crash
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

@test "claw multi-repo: unknown subcommand fails" {
    run "$PROJECT_ROOT/bin/claw" multi-repo unknown-cmd
    assert_failure
}

# Pattern Detection Tests
@test "detect_multi_repo: finds frontend sibling" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/game" "$parent/frontend"

    run detect_multi_repo "$parent/game"
    assert_success
    assert_output --partial "frontend"
}

@test "detect_multi_repo: finds backend sibling" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/api" "$parent/backend"

    run detect_multi_repo "$parent/api"
    assert_success
    assert_output --partial "backend"
}

@test "detect_multi_repo: finds contracts sibling" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/frontend" "$parent/contracts"

    run detect_multi_repo "$parent/frontend"
    assert_success
    assert_output --partial "contracts"
}
