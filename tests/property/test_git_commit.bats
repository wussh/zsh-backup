#!/usr/bin/env bats
# tests/property/test_git_commit.bats
# Property 6: Git commit on backup
# Feature: zsh-dotfiles-setup, Property 6: git commit on backup
#
# For any set of changes to tracked files, running `dotfiles backup` SHALL
# result in a new git commit with a timestamp-format message.

load '../helpers/setup_helpers'
load '../helpers/generators'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

PROPERTY_ITERATIONS="${PROPERTY_ITERATIONS:-100}"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/git.sh"

    git -C "$DOTFILES_DIR" init --quiet
    git -C "$DOTFILES_DIR" config user.email "test@test.com"
    git -C "$DOTFILES_DIR" config user.name "Test User"

    # Initial commit
    echo "# init" > "${DOTFILES_DIR}/init.txt"
    git -C "$DOTFILES_DIR" add -A
    git -C "$DOTFILES_DIR" commit -m "init" --quiet
}

teardown() {
    teardown_dotfiles_env
}

_property6_iteration() {
    local _iter="$1"

    # Make a random change
    local content
    content="$(gen_random_content 2)"
    echo "$content" > "${DOTFILES_DIR}/file_${_iter}.txt"

    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    git_commit "dotfiles backup: ${ts}" >/dev/null 2>&1

    # Assert: new commit exists with matching message
    local last_msg
    last_msg="$(git -C "$DOTFILES_DIR" log --format=%s -1)"

    if [[ ! "$last_msg" =~ ^dotfiles\ backup:\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
        echo "Iteration $_iter: commit message format mismatch: '$last_msg'" >&2
        return 1
    fi

    return 0
}

@test "Property 6: git commit on backup (${PROPERTY_ITERATIONS} iterations)" {
    local failed=0
    for i in $(seq 1 "$PROPERTY_ITERATIONS"); do
        _property6_iteration "$i" || ((failed++))
    done
    [ "$failed" -eq 0 ]
}
