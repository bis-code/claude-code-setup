#!/usr/bin/env bats
# Integration tests for claw CLI

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

@test "install.sh: installs to custom prefix" {
    run "$PROJECT_ROOT/install.sh" --prefix "$TMP_DIR"
    assert_success
}

@test "claw: shows help without errors" {
    run "$PROJECT_ROOT/bin/claw" help
    assert_success
    assert_output --partial "claw"
}

@test "claw version: shows version info" {
    run "$PROJECT_ROOT/bin/claw" version
    assert_success
    assert_output --partial "claw"
}

@test "claw detect: detects SaaS project correctly" {
    mkdir -p "$TMP_DIR"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "my-saas", "dependencies": {"next": "^14.0.0", "stripe": "^13.0.0"}}
EOF
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "saas"
}

@test "claw detect: detects Unity game project" {
    mkdir -p "$TMP_DIR/Assets" "$TMP_DIR/ProjectSettings"
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "game-unity"
}

@test "claw detect: detects monorepo with multiple packages" {
    mkdir -p "$TMP_DIR/packages/web" "$TMP_DIR/packages/api"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "monorepo", "workspaces": ["packages/*"]}
EOF
    cat > "$TMP_DIR/packages/web/package.json" << 'EOF'
{"name": "web", "dependencies": {"react": "^18.0.0"}}
EOF
    cat > "$TMP_DIR/packages/api/package.json" << 'EOF'
{"name": "api", "dependencies": {"express": "^4.18.0"}}
EOF
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "Packages:"
}

@test "claw multi-repo detect: finds sibling repos" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/game" "$parent/frontend"
    touch "$parent/game/.git" "$parent/frontend/.git"
    cd "$parent/game"
    run "$PROJECT_ROOT/bin/claw" multi-repo detect
    assert_success
}

@test "claw init: creates .claude directory structure" {
    mkdir -p "$TMP_DIR"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "test-project"}
EOF
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" init --preset base
    assert_success
    assert [ -d "$TMP_DIR/.claude" ]
}

@test "claw init: auto-detects preset based on project type" {
    mkdir -p "$TMP_DIR/Assets" "$TMP_DIR/ProjectSettings"
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" init
    assert_success
}

@test "claw agents list: shows agents for current project type" {
    mkdir -p "$TMP_DIR/Assets" "$TMP_DIR/ProjectSettings"
    cd "$TMP_DIR"
    run "$PROJECT_ROOT/bin/claw" agents list
    assert_success
    assert_output --partial "gameplay-programmer"
}

@test "claw agents spawn: shows agent prompt" {
    run "$PROJECT_ROOT/bin/claw" agents spawn senior-dev
    assert_success
    assert_output --partial "Senior Developer"
}

@test "claw leann status: shows installation status" {
    run "$PROJECT_ROOT/bin/claw" leann status
    assert_success
    assert_output --partial "LEANN Status"
}

@test "e2e: full workflow - init, detect, agents" {
    mkdir -p "$TMP_DIR"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "test", "dependencies": {"next": "^14.0.0", "stripe": "^13.0.0"}}
EOF
    cd "$TMP_DIR"

    run "$PROJECT_ROOT/bin/claw" init
    assert_success

    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "saas"

    run "$PROJECT_ROOT/bin/claw" agents list
    assert_success
}

@test "e2e: game project workflow" {
    mkdir -p "$TMP_DIR/Assets" "$TMP_DIR/ProjectSettings"
    cd "$TMP_DIR"

    run "$PROJECT_ROOT/bin/claw" init
    assert_success

    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "game-unity"

    run "$PROJECT_ROOT/bin/claw" agents list
    assert_success
    assert_output --partial "gameplay-programmer"
}
