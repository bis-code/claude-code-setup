#!/usr/bin/env bats
# Comprehensive project type detection tests

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

# Game Projects
@test "detect_project_type: identifies Godot project" {
    touch "$TMP_DIR/project.godot"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "game-godot"
}

@test "detect_project_type: identifies Unity with nested Assets" {
    mkdir -p "$TMP_DIR/Assets/Scripts" "$TMP_DIR/ProjectSettings"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "game-unity"
}

# Rust Projects
@test "detect_project_type: identifies Rust CLI (has [[bin]])" {
    cat > "$TMP_DIR/Cargo.toml" << 'EOF'
[package]
name = "my-cli"
[[bin]]
name = "cli"
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "cli"
}

@test "detect_project_type: identifies Rust library (no [[bin]])" {
    cat > "$TMP_DIR/Cargo.toml" << 'EOF'
[package]
name = "my-lib"
[lib]
crate-type = ["lib"]
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "library"
}

# Python Projects
@test "detect_project_type: identifies Python ML project (torch)" {
    cat > "$TMP_DIR/pyproject.toml" << 'EOF'
[project]
name = "ml-project"
dependencies = ["torch>=2.0"]
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "data-ml"
}

@test "detect_project_type: identifies Python ML from requirements.txt" {
    echo "tensorflow>=2.0" > "$TMP_DIR/requirements.txt"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "data-ml"
}

@test "detect_project_type: identifies Python library (has packages)" {
    cat > "$TMP_DIR/pyproject.toml" << 'EOF'
[project]
name = "my-lib"
[tool.setuptools.packages]
find = {}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "library"
}

# Mobile Projects
@test "detect_project_type: identifies React Native mobile app" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "mobile-app", "dependencies": {"react-native": "^0.72.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "mobile"
}

@test "detect_project_type: identifies Expo mobile app" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "expo-app", "dependencies": {"expo": "^49.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "mobile"
}

# Desktop Projects
@test "detect_project_type: identifies Electron desktop app" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "desktop-app", "dependencies": {"electron": "^27.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "desktop"
}

@test "detect_project_type: identifies Tauri desktop app" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "tauri-app", "dependencies": {"@tauri-apps/api": "^1.5.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "desktop"
}

# API Projects
@test "detect_project_type: identifies Express API" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "api", "dependencies": {"express": "^4.18.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "api"
}

@test "detect_project_type: identifies Fastify API" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "api", "dependencies": {"fastify": "^4.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "api"
}

@test "detect_project_type: identifies NestJS API" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "api", "dependencies": {"@nestjs/core": "^10.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "api"
}

# Web Projects
@test "detect_project_type: identifies pure React web" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "web", "dependencies": {"react": "^18.0.0", "react-dom": "^18.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "web"
}

@test "detect_project_type: identifies Vue web" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "web", "dependencies": {"vue": "^3.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "web"
}

@test "detect_project_type: identifies Svelte web" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "web", "dependencies": {"svelte": "^4.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "web"
}

@test "detect_project_type: identifies Next.js without auth/payments as web" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "web", "dependencies": {"next": "^14.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "web"
}

@test "detect_project_type: identifies Nuxt as web" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "web", "dependencies": {"nuxt": "^3.0.0"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "web"
}

# CLI Projects
@test "detect_project_type: identifies npm package with bin as CLI" {
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "my-cli", "bin": {"cli": "./bin/cli.js"}}
EOF
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "cli"
}

@test "detect_project_type: identifies Go CLI (has cmd/)" {
    mkdir -p "$TMP_DIR/cmd/mycli"
    touch "$TMP_DIR/go.mod"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "cli"
}

@test "detect_project_type: identifies Go library (no cmd/)" {
    touch "$TMP_DIR/go.mod"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "library"
}

# Web3 Projects
@test "detect_project_type: identifies Foundry project" {
    touch "$TMP_DIR/foundry.toml"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "web3"
}

@test "detect_project_type: identifies Hardhat TS project" {
    touch "$TMP_DIR/hardhat.config.ts"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "web3"
}

# Monorepo Detection
@test "detect_monorepo_packages: detects npm workspaces" {
    mkdir -p "$TMP_DIR/packages/app" "$TMP_DIR/packages/lib"
    cat > "$TMP_DIR/package.json" << 'EOF'
{"name": "monorepo", "workspaces": ["packages/*"]}
EOF
    run detect_monorepo_packages "$TMP_DIR"
    assert_success
    assert_output --partial "packages/app"
}

@test "detect_monorepo_packages: detects lerna" {
    mkdir -p "$TMP_DIR/packages/a" "$TMP_DIR/packages/b"
    cat > "$TMP_DIR/lerna.json" << 'EOF'
{"packages": ["packages/*"]}
EOF
    run detect_monorepo_packages "$TMP_DIR"
    assert_success
    assert_output --partial "packages/"
}

@test "detect_monorepo_packages: detects turborepo" {
    mkdir -p "$TMP_DIR/apps/web" "$TMP_DIR/packages/ui"
    cat > "$TMP_DIR/turbo.json" << 'EOF'
{"pipeline": {}}
EOF
    cat > "$TMP_DIR/package.json" << 'EOF'
{"workspaces": ["apps/*", "packages/*"]}
EOF
    run detect_monorepo_packages "$TMP_DIR"
    assert_success
}

@test "detect_monorepo_packages: detects nx" {
    mkdir -p "$TMP_DIR/apps/app1" "$TMP_DIR/libs/lib1"
    cat > "$TMP_DIR/nx.json" << 'EOF'
{}
EOF
    run detect_monorepo_packages "$TMP_DIR"
    assert_success
}

@test "detect_monorepo_packages: detects cargo workspace" {
    mkdir -p "$TMP_DIR/crates/core" "$TMP_DIR/crates/cli"
    cat > "$TMP_DIR/Cargo.toml" << 'EOF'
[workspace]
members = ["crates/*"]
EOF
    run detect_monorepo_packages "$TMP_DIR"
    assert_success
    assert_output --partial "crates/"
}

# Edge Cases
@test "detect_project_type: handles missing package.json gracefully" {
    mkdir -p "$TMP_DIR"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "unknown"
}

@test "detect_project_type: handles malformed package.json" {
    echo "not valid json" > "$TMP_DIR/package.json"
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "unknown"
}

@test "detect_project_type: handles nested project markers" {
    mkdir -p "$TMP_DIR/sub/Assets" "$TMP_DIR/sub/ProjectSettings"
    # Should not detect Unity in parent
    run detect_project_type "$TMP_DIR"
    assert_success
    assert_output "unknown"
}
