#!/usr/bin/env bats
# tests/unit/test_git_ops.bats
# Unit tests for bin/lib/git.sh

load '../helpers/setup_helpers'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/git.sh"

    # Initialize a git repo in DOTFILES_DIR for testing
    git -C "$DOTFILES_DIR" init --quiet
    git -C "$DOTFILES_DIR" config user.email "test@test.com"
    git -C "$DOTFILES_DIR" config user.name "Test User"
}

teardown() {
    teardown_dotfiles_env
}

@test "git_init is idempotent if repo already exists" {
    run git_init "$DOTFILES_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already initialized" ]]
}

@test "git_commit creates a commit with given message" {
    echo "# test" > "${DOTFILES_DIR}/test.txt"
    git_commit "test commit message"

    local last_msg
    last_msg="$(git -C "$DOTFILES_DIR" log --oneline -1)"
    [[ "$last_msg" =~ "test commit message" ]]
}

@test "git_commit message format includes timestamp" {
    echo "# test" > "${DOTFILES_DIR}/test.txt"
    git_commit "dotfiles backup: $(date '+%Y-%m-%d %H:%M:%S')"

    local last_msg
    last_msg="$(git -C "$DOTFILES_DIR" log --format=%s -1)"
    [[ "$last_msg" =~ "dotfiles backup: " ]]
    [[ "$last_msg" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]
}

@test "git_commit does nothing when no changes" {
    # Make an initial commit first
    echo "# test" > "${DOTFILES_DIR}/test.txt"
    git -C "$DOTFILES_DIR" add -A
    git -C "$DOTFILES_DIR" commit -m "init" --quiet

    run git_commit "should be nothing"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Nothing to commit" ]]
}

@test "git_status returns porcelain output" {
    echo "# new" > "${DOTFILES_DIR}/new_file.txt"
    local status_output
    status_output="$(git_status)"
    [[ "$status_output" =~ "new_file.txt" ]]
}

@test "git_set_remote adds a new remote" {
    # Make an initial commit first so we have a repo
    echo "# init" > "${DOTFILES_DIR}/init.txt"
    git -C "$DOTFILES_DIR" add -A
    git -C "$DOTFILES_DIR" commit -m "init" --quiet

    git_set_remote "https://github.com/user/dotfiles.git"

    local remote_url
    remote_url="$(git -C "$DOTFILES_DIR" remote get-url origin)"
    [ "$remote_url" = "https://github.com/user/dotfiles.git" ]
}

@test "git_push fails gracefully on non-existent remote" {
    # Make initial commit
    echo "# init" > "${DOTFILES_DIR}/init.txt"
    git -C "$DOTFILES_DIR" add -A
    git -C "$DOTFILES_DIR" commit -m "init" --quiet

    git_set_remote "https://github.com/nonexistent/repo_xyz_test.git"

    run git_push "origin" "main"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "ERROR" ]]
}
