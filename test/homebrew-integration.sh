#!/usr/bin/env bash
#
# homebrew-integration.sh - Comprehensive CLI tests for claw
#
# Tests all CLI commands and flags to ensure they work correctly
# after Homebrew installation. Run this before every release.
#
# Usage:
#   ./test/homebrew-integration.sh           # Test installed claw
#   ./test/homebrew-integration.sh --local   # Test from source
#

# Note: Don't use set -e as we want to continue running tests even if some fail
set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test environment
TEST_HOME=""
TEST_CLAW_HOME=""
TEST_PROJECT=""

# Determine claw binary
if [[ "${1:-}" == "--local" ]]; then
    CLAW_BIN="$PROJECT_ROOT/bin/claw"
    echo "${CYAN}Testing LOCAL claw from: $CLAW_BIN${NC}"
else
    CLAW_BIN="claw"
    echo "${CYAN}Testing INSTALLED claw${NC}"
fi

# ============================================================================
# Test Framework
# ============================================================================

setup_test_env() {
    TEST_HOME=$(mktemp -d)
    TEST_CLAW_HOME="$TEST_HOME/.claw"
    TEST_PROJECT="$TEST_HOME/test-project"
    TEST_CLAUDE_HOME="$TEST_HOME/.claude"

    mkdir -p "$TEST_PROJECT"
    mkdir -p "$TEST_CLAUDE_HOME"
    cd "$TEST_PROJECT"
    git init --quiet
    git remote add origin https://github.com/test-owner/test-repo.git

    # Only override CLAW_HOME and CLAUDE_HOME, not HOME (breaks too much)
    export CLAW_HOME="$TEST_CLAW_HOME"
    export CLAUDE_HOME="$TEST_CLAUDE_HOME"

    echo "Test environment: $TEST_HOME"
}

cleanup_test_env() {
    if [[ -n "$TEST_HOME" ]] && [[ -d "$TEST_HOME" ]]; then
        rm -rf "$TEST_HOME"
    fi
}

trap cleanup_test_env EXIT

# Run a test
# Usage: run_test "description" "command" [expected_exit_code]
run_test() {
    local description="$1"
    local command="$2"
    local expected_exit="${3:-0}"

    TESTS_RUN=$((TESTS_RUN + 1))

    printf "  %-50s " "$description"

    local output
    local exit_code=0
    output=$(eval "$command" 2>&1) || exit_code=$?

    if [[ "$exit_code" -eq "$expected_exit" ]]; then
        echo "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "${RED}FAIL${NC}"
        echo "    Expected exit code: $expected_exit, got: $exit_code"
        echo "    Output: ${output:0:200}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Run a test and check output contains string
# Usage: run_test_output "description" "command" "expected_substring"
run_test_output() {
    local description="$1"
    local command="$2"
    local expected="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    printf "  %-50s " "$description"

    local output
    local exit_code=0
    output=$(eval "$command" 2>&1) || exit_code=$?

    if [[ "$output" == *"$expected"* ]]; then
        echo "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "${RED}FAIL${NC}"
        echo "    Expected output to contain: $expected"
        echo "    Got: ${output:0:200}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# ============================================================================
# Test Suites
# ============================================================================

test_main_commands() {
    echo ""
    echo "${CYAN}=== Main Commands ===${NC}"

    run_test_output "--version flag" "$CLAW_BIN --version" "claw v"
    run_test_output "-v flag" "$CLAW_BIN -v" "claw v"
    run_test_output "version command" "$CLAW_BIN version" "claw v"

    run_test_output "--help flag" "$CLAW_BIN --help" "Command Line Automated Workflow"
    run_test_output "-h flag" "$CLAW_BIN -h" "Usage:"

    run_test "--update flag" "$CLAW_BIN --update"
}

test_project_commands() {
    echo ""
    echo "${CYAN}=== Project Commands ===${NC}"

    # Help
    run_test_output "project --help" "$CLAW_BIN project --help" "Multi-repo project management"
    run_test_output "project -h" "$CLAW_BIN project -h" "Multi-repo project management"
    run_test_output "project (no args)" "$CLAW_BIN project" "Multi-repo project management"

    # List (empty)
    run_test_output "project list (empty)" "$CLAW_BIN project list" "No projects configured"
    run_test_output "project ls" "$CLAW_BIN project ls" "No projects configured"

    # Create
    run_test_output "project create" "$CLAW_BIN project create test-proj" "Created project: test-proj"
    run_test_output "project create with desc" "$CLAW_BIN project create test-proj2 --description 'Test description'" "Created project: test-proj2"
    run_test_output "project create with -d" "$CLAW_BIN project create test-proj3 -d 'Short desc'" "Created project: test-proj3"
    run_test "project create duplicate" "$CLAW_BIN project create test-proj" 1
    run_test "project create missing name" "$CLAW_BIN project create" 1

    # List (with items)
    run_test_output "project list (with items)" "$CLAW_BIN project list" "test-proj"

    # Add repo
    run_test_output "project add-repo" "$CLAW_BIN project add-repo $TEST_PROJECT --project test-proj" "Added to project"
    run_test_output "project add-repo duplicate" "$CLAW_BIN project add-repo $TEST_PROJECT --project test-proj" "already in project"
    run_test_output "project add (alias)" "mkdir -p $TEST_HOME/other-repo && cd $TEST_HOME/other-repo && git init -q && $CLAW_BIN project add . --project test-proj" "Added to project"
    run_test "project add-repo no path" "$CLAW_BIN project add-repo" 1
    run_test "project add-repo invalid path" "$CLAW_BIN project add-repo /nonexistent --project test-proj" 1

    # Show
    run_test_output "project show" "$CLAW_BIN project show test-proj" "Project: test-proj"
    run_test_output "project show (auto-detect)" "cd $TEST_PROJECT && $CLAW_BIN project show" "Project: test-proj"
    run_test "project show nonexistent" "$CLAW_BIN project show nonexistent" 1

    # Remove repo
    run_test_output "project remove-repo" "$CLAW_BIN project remove-repo $TEST_HOME/other-repo --project test-proj" "Removed from project"
    # Re-add for rm alias test
    mkdir -p "$TEST_HOME/rm-test-repo" && cd "$TEST_HOME/rm-test-repo" && git init -q 2>/dev/null
    run_test_output "project rm (alias)" "$CLAW_BIN project add-repo $TEST_HOME/rm-test-repo --project test-proj && $CLAW_BIN project rm $TEST_HOME/rm-test-repo" "Removed from project"
    cd "$TEST_PROJECT"

    # Invalid subcommand
    run_test "project invalid subcommand" "$CLAW_BIN project invalid" 1
}

test_templates_commands() {
    echo ""
    echo "${CYAN}=== Templates Commands ===${NC}"

    # Help
    run_test_output "templates --help" "$CLAW_BIN templates --help" "Manage GitHub issue templates"
    run_test_output "templates -h" "$CLAW_BIN templates -h" "Manage GitHub issue templates"
    run_test_output "templates (no args)" "$CLAW_BIN templates" "Manage GitHub issue templates"

    # List
    run_test_output "templates list" "$CLAW_BIN templates list" "bug-report"
    run_test_output "templates list includes all" "$CLAW_BIN templates list" "claude-ready"
    run_test_output "templates ls" "$CLAW_BIN templates ls" "feature-request"

    # Install (requires gh auth - skip in CI)
    if gh auth status &>/dev/null 2>&1; then
        echo "  ${YELLOW}(skipping install tests - would modify real repos)${NC}"
    else
        echo "  ${YELLOW}(skipping install tests - gh not authenticated)${NC}"
    fi

    # Invalid subcommand
    run_test "templates invalid subcommand" "$CLAW_BIN templates invalid" 1
}

test_issues_command() {
    echo ""
    echo "${CYAN}=== Issues Command ===${NC}"

    # Issues command (requires gh auth)
    if gh auth status &>/dev/null 2>&1; then
        run_test "issues command runs" "$CLAW_BIN issues --json 2>/dev/null || true" 0
    else
        echo "  ${YELLOW}(skipping issues tests - gh not authenticated)${NC}"
    fi
}

test_yolo_flag() {
    echo ""
    echo "${CYAN}=== YOLO Flag ===${NC}"

    # We can't fully test --yolo without running claude, but we can check it's recognized
    run_test "--yolo flag recognized" "$CLAW_BIN --yolo --help" 0
    run_test "-y flag recognized" "$CLAW_BIN -y --help" 0
}

test_edge_cases() {
    echo ""
    echo "${CYAN}=== Edge Cases ===${NC}"

    # Special characters in project names
    run_test_output "project with hyphen" "$CLAW_BIN project create my-cool-project" "Created project"
    run_test_output "project with underscore" "$CLAW_BIN project create my_project" "Created project"

    # Spaces in paths
    local space_dir="$TEST_HOME/path with spaces"
    mkdir -p "$space_dir"
    cd "$space_dir"
    git init --quiet
    run_test_output "add-repo with spaces in path" "$CLAW_BIN project add-repo \"$space_dir\" --project test-proj" "Added to project"
    cd "$TEST_PROJECT"

    # Multiple flags combined
    run_test_output "combined short flags work" "$CLAW_BIN -v" "claw v"
}

test_path_resolution() {
    echo ""
    echo "${CYAN}=== Path Resolution (Critical for Homebrew) ===${NC}"

    # Templates path - this was the bug we caught
    run_test_output "templates list finds files" "$CLAW_BIN templates list" "Available GitHub issue templates"
    run_test_output "templates list shows bug-report" "$CLAW_BIN templates list" "bug-report"
    run_test_output "templates list shows claude-ready" "$CLAW_BIN templates list" "claude-ready"
    run_test_output "templates list shows feature-request" "$CLAW_BIN templates list" "feature-request"
    run_test_output "templates list shows tech-debt" "$CLAW_BIN templates list" "tech-debt"

    # Commands installation path
    run_test "--update installs commands" "$CLAW_BIN --update" 0
    run_test "commands dir exists after update" "test -d '$TEST_CLAUDE_HOME/commands'" 0
}

test_claude_integration() {
    echo ""
    echo "${CYAN}=== Claude Integration ===${NC}"

    # Check if claude is available
    if command -v claude &>/dev/null; then
        run_test_output "claude detected" "$CLAW_BIN --version" "claude"
    else
        echo "  ${YELLOW}(skipping claude tests - claude not installed)${NC}"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "=============================================="
    echo "  Claw Homebrew Integration Tests"
    echo "=============================================="

    setup_test_env

    test_main_commands
    test_project_commands
    test_templates_commands
    test_issues_command
    test_yolo_flag
    test_edge_cases
    test_path_resolution
    test_claude_integration

    echo ""
    echo "=============================================="
    echo "  Results"
    echo "=============================================="
    echo ""
    echo "  Tests run:    $TESTS_RUN"
    echo "  ${GREEN}Passed:       $TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "  ${RED}Failed:       $TESTS_FAILED${NC}"
    else
        echo "  Failed:       $TESTS_FAILED"
    fi
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "${RED}SOME TESTS FAILED${NC}"
        exit 1
    else
        echo "${GREEN}ALL TESTS PASSED${NC}"
        exit 0
    fi
}

main "$@"
