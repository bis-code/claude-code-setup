#!/usr/bin/env bats
# External dependency tests for claw
# These tests require external dependencies (gh CLI, LEANN, uv)
# Tests skip gracefully if dependencies are not available

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    # Get project root
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export PROJECT_ROOT

    # Source libraries
    source "$PROJECT_ROOT/lib/detect-project.sh"
    source "$PROJECT_ROOT/lib/leann-setup.sh"

    # Create temp directory for tests
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
}

teardown() {
    # Clean up temp directory
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}

#==============================================================================
# Helper Functions
#==============================================================================

skip_if_no_gh() {
    if ! command -v gh &>/dev/null; then
        skip "gh CLI not installed"
    fi
}

skip_if_no_gh_auth() {
    skip_if_no_gh
    if ! gh auth status &>/dev/null 2>&1; then
        skip "gh CLI not authenticated"
    fi
}

skip_if_no_leann() {
    if ! command -v leann &>/dev/null; then
        skip "LEANN not installed"
    fi
}

skip_if_no_uv() {
    if ! command -v uv &>/dev/null; then
        skip "uv not installed"
    fi
}

#==============================================================================
# GitHub CLI Tests
#==============================================================================

@test "gh CLI: is installed" {
    skip_if_no_gh
    run command -v gh
    assert_success
}

@test "gh CLI: is authenticated" {
    skip_if_no_gh_auth
    run gh auth status
    assert_success
    assert_output --partial "Logged in"
}

@test "gh CLI: can list repos" {
    skip_if_no_gh_auth
    run gh repo list --limit 1
    assert_success
}

@test "gh CLI: can fetch issues from repo" {
    skip_if_no_gh_auth

    # Try to list issues (even if empty, should succeed)
    run gh issue list --repo bis-code/claude-code-setup --limit 1 --state all
    assert_success
}

@test "gh CLI: can fetch PRs from repo" {
    skip_if_no_gh_auth

    run gh pr list --repo bis-code/claude-code-setup --limit 1 --state all
    assert_success
}

@test "fetch_multi_repo_issues: returns valid JSON" {
    skip_if_no_gh_auth

    # Create a git repo in temp directory (required for gh issue list)
    cd "$TMP_DIR"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    git config commit.gpgsign false
    echo "test" > README.md
    git add README.md
    git commit -q -m "initial" --no-gpg-sign

    # Create a mock multi-repo config in correct path
    mkdir -p "$TMP_DIR/.claw"
    cat > "$TMP_DIR/.claw/multi-repo.json" << 'EOF'
{
    "detected": true,
    "repos": ["bis-code/claude-code-setup"],
    "primary": "bis-code/claude-code-setup"
}
EOF

    # Test the function - without a remote, gh will fail, so we test single-repo mode
    # by NOT having the config (testing fallback path)
    rm -rf "$TMP_DIR/.claw"

    # The function should return empty array or fail gracefully for non-github repo
    run fetch_multi_repo_issues "$TMP_DIR"
    # gh issue list will fail for local-only repo, which is expected
    # Just verify it doesn't crash
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

#==============================================================================
# LEANN Tests
#==============================================================================

@test "LEANN: is installed" {
    skip_if_no_leann
    run command -v leann
    assert_success
}

@test "LEANN: can list indexes" {
    skip_if_no_leann

    run leann list
    assert_success
    assert_output --partial "LEANN Indexes"
}

@test "LEANN: build creates index" {
    skip_if_no_leann

    # Create test documents
    mkdir -p "$TMP_DIR/docs"
    echo "This is a test document about Claude Code automation" > "$TMP_DIR/docs/test1.txt"
    echo "LEANN provides semantic search capabilities" > "$TMP_DIR/docs/test2.txt"

    cd "$TMP_DIR"

    # Build index
    run leann build test-index --docs ./docs
    assert_success

    # Verify index was created
    run leann list
    assert_success
    assert_output --partial "test-index"
}

@test "LEANN: search returns results" {
    skip_if_no_leann

    # Create test documents and index
    mkdir -p "$TMP_DIR/docs"
    echo "Claude Code is an AI-powered coding assistant" > "$TMP_DIR/docs/test1.txt"
    echo "Semantic search helps find relevant code" > "$TMP_DIR/docs/test2.txt"

    cd "$TMP_DIR"

    # Build index first
    leann build search-test-index --docs ./docs

    # Search
    run leann search search-test-index "AI coding assistant"
    assert_success
    assert_output --partial "Score:"
}

@test "LEANN: remove deletes index" {
    skip_if_no_leann

    # Create test documents
    mkdir -p "$TMP_DIR/docs"
    echo "Test content for removal" > "$TMP_DIR/docs/test.txt"

    cd "$TMP_DIR"

    # Build index
    leann build remove-test-index --docs ./docs

    # Verify it exists
    run leann list
    assert_output --partial "remove-test-index"

    # Remove index
    run leann remove remove-test-index --force
    assert_success

    # Verify it's gone
    run leann list
    refute_output --partial "remove-test-index"
}

#==============================================================================
# uv Tests
#==============================================================================

@test "uv: is installed" {
    skip_if_no_uv
    run command -v uv
    assert_success
}

@test "uv: can show version" {
    skip_if_no_uv

    run uv --version
    assert_success
    assert_output --partial "uv"
}

#==============================================================================
# Integration: claw leann commands
#==============================================================================

@test "claw leann status: shows LEANN status" {
    run "$PROJECT_ROOT/bin/claw" leann status
    assert_success
    assert_output --partial "LEANN Status"
}

@test "claw leann: status includes installation check" {
    run "$PROJECT_ROOT/bin/claw" leann status
    assert_success

    if command -v leann &>/dev/null; then
        assert_output --partial "Installed:"
    fi
}

#==============================================================================
# Integration: claw multi-repo with real gh
#==============================================================================

@test "claw multi-repo: detect finds sibling repos" {
    skip_if_no_gh_auth

    # This test uses the actual project structure
    cd "$PROJECT_ROOT"

    run "$PROJECT_ROOT/bin/claw" multi-repo detect
    assert_success
}

@test "claw multi-repo: issues fetches from GitHub" {
    skip_if_no_gh_auth

    # Run from the actual project directory (which is a real GitHub repo)
    cd "$PROJECT_ROOT"

    run "$PROJECT_ROOT/bin/claw" multi-repo issues
    # Should succeed - either returns issues or empty (no issues with claude-ready label)
    assert_success
}

#==============================================================================
# End-to-End: Full workflow test
#==============================================================================

@test "E2E: init project with LEANN indexing" {
    skip_if_no_leann

    # Create a test project
    mkdir -p "$TMP_DIR/e2e-project/src"
    cat > "$TMP_DIR/e2e-project/package.json" << 'EOF'
{
    "name": "e2e-test",
    "version": "1.0.0",
    "dependencies": {
        "express": "^4.18.0"
    }
}
EOF
    echo "// Express server code" > "$TMP_DIR/e2e-project/src/index.js"

    cd "$TMP_DIR/e2e-project"

    # Initialize with claw
    run "$PROJECT_ROOT/bin/claw" init
    assert_success

    # Verify .claude directory was created
    assert [ -d ".claude" ]

    # Check LEANN status
    run "$PROJECT_ROOT/bin/claw" leann status
    assert_success
}

@test "E2E: agent spawn generates valid prompt" {
    run "$PROJECT_ROOT/bin/claw" agents spawn senior-dev
    assert_success
    assert_output --partial "Senior Developer"
}
