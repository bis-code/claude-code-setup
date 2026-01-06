#!/usr/bin/env bash
# Test helper functions for BATS tests

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT

# Source the libraries
source "$PROJECT_ROOT/lib/detect-project.sh"
source "$PROJECT_ROOT/lib/agents.sh"
source "$PROJECT_ROOT/lib/leann-setup.sh"

# Create a temporary directory for tests
create_test_dir() {
    local dir
    dir=$(mktemp -d -t claw-test-XXXXXX)
    echo "$dir"
}

# Clean up a test directory
cleanup_test_dir() {
    local dir="$1"
    if [[ -n "$dir" && -d "$dir" && "$dir" == /tmp/* ]]; then
        rm -rf "$dir"
    fi
}

# Create a mock package.json
create_package_json() {
    local dir="$1"
    local content="$2"
    echo "$content" > "$dir/package.json"
}

# Create a mock pyproject.toml
create_pyproject_toml() {
    local dir="$1"
    local content="$2"
    echo "$content" > "$dir/pyproject.toml"
}

# Create a mock Cargo.toml
create_cargo_toml() {
    local dir="$1"
    local content="$2"
    echo "$content" > "$dir/Cargo.toml"
}
