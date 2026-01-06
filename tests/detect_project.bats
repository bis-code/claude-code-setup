#!/usr/bin/env bats
# Unit tests for project detection

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

@test "detect_project_type: identifies SaaS project (Next.js + Stripe)" {
    mkdir -p "$TMP_DIR"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "my-saas", "dependencies": {"next": "^14.0.0", "stripe": "^13.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "saas"
}

@test "detect_project_type: identifies Unity game project" {
    mkdir -p "$TMP_DIR/Assets" "$TMP_DIR/ProjectSettings"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "game-unity"
}

@test "detect_project_type: identifies Hardhat/Web3 project" {
    mkdir -p "$TMP_DIR"
    touch "$TMP_DIR/hardhat.config.js"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "web3"
}

@test "detect_project_type: identifies library project" {
    mkdir -p "$TMP_DIR"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "my-lib", "main": "index.js"}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "library"
}

@test "detect_project_type: returns unknown for empty directory" {
    mkdir -p "$TMP_DIR"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "unknown"
}

@test "detect_monorepo_packages: detects pnpm workspace" {
    mkdir -p "$TMP_DIR/packages/app" "$TMP_DIR/packages/lib"
    cat > "$TMP_DIR/pnpm-workspace.yaml" << 'EOF'
packages:
  - 'packages/*'
EOF
    run detect_monorepo_packages "$TMP_DIR"
    assert_success
    assert_output --partial "packages/app"
}

@test "detect_monorepo_packages: single project returns single entry" {
    mkdir -p "$TMP_DIR"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "single-project"}
EOF
    run detect_monorepo_packages "$TMP_DIR"
    assert_success
    assert_output --partial "$TMP_DIR"
}

@test "get_agents_for_type: returns game agents for Unity" {
    run get_agents_for_type "game-unity"
    assert_success
    assert_output --partial "gameplay-programmer"
    assert_output --partial "systems-programmer"
}

@test "get_agents_for_type: returns SaaS agents" {
    run get_agents_for_type "saas"
    assert_success
    assert_output --partial "senior-dev"
    assert_output --partial "product"
}

@test "get_agents_for_type: returns default agents for unknown type" {
    run get_agents_for_type "unknown"
    assert_success
    assert_output --partial "senior-dev"
}

@test "detect_multi_repo: detects sibling repositories" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/game" "$parent/frontend" "$parent/backend"
    touch "$parent/game/.git" "$parent/frontend/.git" "$parent/backend/.git"

    run detect_multi_repo "$parent/game"
    assert_success
}

@test "detect_multi_repo: returns false for standalone repo" {
    mkdir -p "$TMP_DIR/standalone"
    run detect_multi_repo "$TMP_DIR/standalone"
    assert_success
    assert_output --partial '"detected": false'
}

@test "full detection flow: monorepo with multiple package types" {
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

    run detect_monorepo_packages "$TMP_DIR"
    assert_success
    assert_output --partial "packages/web"
    assert_output --partial "packages/api"
}

@test "print_detection_summary: outputs readable summary" {
    mkdir -p "$TMP_DIR"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "test", "dependencies": {"next": "^14.0.0"}}
EOF
    run print_detection_summary "$TMP_DIR"
    assert_success
    assert_output --partial "Project Type:"
}
