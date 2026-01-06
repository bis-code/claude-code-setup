#!/usr/bin/env bats
# Tests for manifest library functions
# Note: CLI tests for `claw init`, `claw upgrade`, `claw check` removed
# The simplified claw is a drop-in replacement for claude
# The manifest functions are still available via lib/manifest.sh

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

# ============================================================================
# Manifest Functions
# ============================================================================

@test "get_installed_version: returns 0.0.0 for no manifest" {
    mkdir -p "$TMP_DIR/project"
    run get_installed_version "$TMP_DIR/project"
    assert_success
    assert_output "0.0.0"
}

@test "get_installed_version: returns version from manifest" {
    mkdir -p "$TMP_DIR/project/.claude"
    cat > "$TMP_DIR/project/.claude/manifest.json" << 'EOF'
{
  "version": "1.2.3",
  "preset": "base"
}
EOF
    run get_installed_version "$TMP_DIR/project"
    assert_success
    assert_output "1.2.3"
}

@test "get_installed_preset: returns full for no manifest" {
    mkdir -p "$TMP_DIR/project"
    run get_installed_preset "$TMP_DIR/project"
    assert_success
    assert_output "full"
}

@test "get_installed_preset: returns preset from manifest" {
    mkdir -p "$TMP_DIR/project/.claude"
    cat > "$TMP_DIR/project/.claude/manifest.json" << 'EOF'
{
  "version": "1.0.0",
  "preset": "unity"
}
EOF
    run get_installed_preset "$TMP_DIR/project"
    assert_success
    assert_output "unity"
}

@test "calc_checksum: returns empty for nonexistent file" {
    run calc_checksum "$TMP_DIR/nonexistent"
    assert_success
    assert_output ""
}

@test "calc_checksum: returns valid checksum" {
    echo "test content" > "$TMP_DIR/testfile"
    run calc_checksum "$TMP_DIR/testfile"
    assert_success
    assert [ ${#output} -eq 64 ]  # SHA256 is 64 hex chars
}

@test "is_file_modified: returns false for nonexistent file" {
    mkdir -p "$TMP_DIR/project"
    run is_file_modified "$TMP_DIR/project" "nonexistent.md"
    assert_failure  # File doesn't exist = not modified
}

@test "is_file_modified: returns true for file not in manifest" {
    mkdir -p "$TMP_DIR/project"
    echo "content" > "$TMP_DIR/project/file.md"
    run is_file_modified "$TMP_DIR/project" "file.md"
    assert_success  # File exists but not in manifest = treated as modified
}

@test "write_manifest: creates valid JSON" {
    mkdir -p "$TMP_DIR/project"
    write_manifest "$TMP_DIR/project" "1.0.0" "base" "file1.md:abc123" "file2.md:def456"

    run cat "$TMP_DIR/project/.claude/manifest.json"
    assert_success
    assert_output --partial '"version": "1.0.0"'
    assert_output --partial '"preset": "base"'
    assert_output --partial '"generator": "claw"'
    assert_output --partial '"path": "file1.md"'
}

# Note: CLI tests for `claw init`, `claw upgrade`, `claw check` removed
# The simplified claw is a drop-in replacement for claude with multi-repo support
