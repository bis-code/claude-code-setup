#!/usr/bin/env bats
# TDD Tests for multi-repo functionality

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    export CLAW_HOME="$TMP_DIR/claw-home"
    mkdir -p "$CLAW_HOME"

    # Source the repos module (will create after tests)
    [[ -f "$PROJECT_ROOT/lib/repos.sh" ]] && source "$PROJECT_ROOT/lib/repos.sh"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# repos add
# ============================================================================

@test "repos: add creates repos.json if not exists" {
    run repos_add "owner/repo"
    assert_success
    assert [ -f "$CLAW_HOME/repos.json" ]
}

@test "repos: add stores repo in correct format" {
    repos_add "myorg/myrepo"

    run cat "$CLAW_HOME/repos.json"
    assert_output --partial "myorg/myrepo"
}

@test "repos: add multiple repos" {
    repos_add "owner/repo1"
    repos_add "owner/repo2"

    run repos_list
    assert_output --partial "owner/repo1"
    assert_output --partial "owner/repo2"
}

@test "repos: add is idempotent (no duplicates)" {
    repos_add "owner/repo"
    repos_add "owner/repo"
    repos_add "owner/repo"

    # Should only appear once
    local count
    count=$(repos_list | grep -c "owner/repo")
    [[ "$count" -eq 1 ]]
}

@test "repos: add validates format - rejects missing slash" {
    run repos_add "invalidrepo"
    assert_failure
    assert_output --partial "Invalid"
}

@test "repos: add validates format - rejects empty owner" {
    run repos_add "/repo"
    assert_failure
    assert_output --partial "Invalid"
}

@test "repos: add validates format - rejects empty repo" {
    run repos_add "owner/"
    assert_failure
    assert_output --partial "Invalid"
}

@test "repos: add accepts valid formats" {
    run repos_add "owner/repo"
    assert_success

    run repos_add "my-org/my-repo"
    assert_success

    run repos_add "Owner123/Repo_456"
    assert_success
}

# ============================================================================
# repos list
# ============================================================================

@test "repos: list shows empty message when no repos" {
    run repos_list
    assert_success
    assert_output --partial "No repos tracked"
}

@test "repos: list shows all tracked repos" {
    repos_add "org1/repo1"
    repos_add "org2/repo2"
    repos_add "org3/repo3"

    run repos_list
    assert_success
    assert_output --partial "org1/repo1"
    assert_output --partial "org2/repo2"
    assert_output --partial "org3/repo3"
}

@test "repos: list shows count" {
    repos_add "owner/repo1"
    repos_add "owner/repo2"

    run repos_list
    assert_output --partial "2"
}

# ============================================================================
# repos remove
# ============================================================================

@test "repos: remove deletes repo from list" {
    repos_add "owner/repo1"
    repos_add "owner/repo2"

    repos_remove "owner/repo1"

    run repos_list
    refute_output --partial "owner/repo1"
    assert_output --partial "owner/repo2"
}

@test "repos: remove handles non-existent repo gracefully" {
    repos_add "owner/repo1"

    run repos_remove "owner/nonexistent"
    assert_success
    assert_output --partial "not tracked"
}

@test "repos: remove last repo leaves empty list" {
    repos_add "owner/repo"
    repos_remove "owner/repo"

    run repos_list
    assert_output --partial "No repos tracked"
}

# ============================================================================
# repos clear
# ============================================================================

@test "repos: clear removes all repos" {
    repos_add "owner/repo1"
    repos_add "owner/repo2"
    repos_add "owner/repo3"

    repos_clear

    run repos_list
    assert_output --partial "No repos tracked"
}

@test "repos: clear works when already empty" {
    run repos_clear
    assert_success
}

# ============================================================================
# get_tracked_repos (for commands to use)
# ============================================================================

@test "repos: get_tracked_repos returns empty array when none" {
    run get_tracked_repos
    assert_success
    assert_output ""
}

@test "repos: get_tracked_repos returns all repos" {
    repos_add "owner/repo1"
    repos_add "owner/repo2"

    run get_tracked_repos
    assert_output --partial "owner/repo1"
    assert_output --partial "owner/repo2"
}

# ============================================================================
# Integration with current directory
# ============================================================================

@test "repos: get_all_repos includes current dir repo if in git repo" {
    cd "$TMP_DIR"
    git init -q
    git remote add origin "https://github.com/current/repo.git"

    repos_add "other/repo"

    run get_all_repos
    assert_output --partial "current/repo"
    assert_output --partial "other/repo"
}

@test "repos: get_all_repos deduplicates if current repo is tracked" {
    cd "$TMP_DIR"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    repos_add "owner/repo"

    # Should only appear once
    local count
    count=$(get_all_repos | grep -c "owner/repo")
    [[ "$count" -eq 1 ]]
}

@test "repos: get_all_repos works outside git repo" {
    cd "$TMP_DIR"
    # Not a git repo

    repos_add "owner/repo"

    run get_all_repos
    assert_success
    assert_output --partial "owner/repo"
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "repos: handles repos.json corruption gracefully" {
    echo "not valid json" > "$CLAW_HOME/repos.json"

    run repos_list
    assert_success
    # Should recover gracefully
}

@test "repos: add with trailing/leading spaces is trimmed" {
    run repos_add "  owner/repo  "
    assert_success

    # Check the actual stored value, not the formatted output
    run jq -r '.repos[0]' "$CLAW_HOME/repos.json"
    assert_output "owner/repo"
}
