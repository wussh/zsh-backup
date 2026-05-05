#!/usr/bin/env bats
# tests/integration/test_bootstrap.bats
# Integration tests for the bootstrap sequence and CLI subcommands.
# Run inside a Docker container or directly on WSL with all dependencies present.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../" && pwd)"

setup() {
    export TEST_HOME
    TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"

    export DOTFILES_DIR
    DOTFILES_DIR="$(mktemp -d)"

    # Copy repo into DOTFILES_DIR
    cp -r "${REPO_ROOT}/." "$DOTFILES_DIR/"
    rm -rf "${DOTFILES_DIR}/.git"

    # Disable remote git operations in tests
    export DOTFILES_REMOTE=""
    if [ -f "${DOTFILES_DIR}/config/dotfiles.conf" ]; then
        sed -i 's/^DOTFILES_REMOTE=.*/DOTFILES_REMOTE=""/' "${DOTFILES_DIR}/config/dotfiles.conf"
    fi

    export PATH="${DOTFILES_DIR}/bin:$PATH"

    # Configure git
    git config --global user.email "test@test.com" 2>/dev/null || true
    git config --global user.name "Test User" 2>/dev/null || true
}

teardown() {
    rm -rf "$TEST_HOME" "$DOTFILES_DIR" 2>/dev/null || true
    unset DOTFILES_DIR HOME
}

@test "dotfiles --help exits 0 and shows usage" {
    run dotfiles --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "dotfiles init creates manifest and config" {
    run dotfiles init
    [ -f "${DOTFILES_DIR}/files/manifest.txt" ]
    [ -f "${DOTFILES_DIR}/config/dotfiles.conf" ]
}

@test "dotfiles add tracks an existing file" {
    echo "# test" > "${TEST_HOME}/.zshrc"
    run dotfiles add "${TEST_HOME}/.zshrc"
    [ -L "${TEST_HOME}/.zshrc" ]
    grep -q ".zshrc" "${DOTFILES_DIR}/files/manifest.txt"
}

@test "dotfiles add warns and returns 1 for missing file" {
    run dotfiles add "${TEST_HOME}/.nonexistent_xyz"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "WARNING" ]]
}

@test "dotfiles status shows tracked files" {
    echo "# zshrc" > "${TEST_HOME}/.zshrc"
    dotfiles add "${TEST_HOME}/.zshrc" >/dev/null

    run dotfiles status
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".zshrc" ]]
}

@test "dotfiles profile list shows available profiles" {
    run dotfiles profile list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "default" ]]
}

@test "dotfiles profile use sets active profile" {
    run dotfiles profile use "server"
    [ "$status" -eq 0 ]
    local val
    val="$(grep '^DOTFILES_PROFILE=' "${DOTFILES_DIR}/config/dotfiles.conf" | sed 's/.*="\(.*\)"/\1/')"
    [ "$val" = "server" ]
}

@test "dotfiles restore --dry-run does not create symlinks" {
    # Set up a tracked file
    mkdir -p "${DOTFILES_DIR}/files/zsh"
    echo "# zshrc" > "${DOTFILES_DIR}/files/zsh/.zshrc"
    echo -e "files/zsh/.zshrc\t${TEST_HOME}/.zshrc" > "${DOTFILES_DIR}/files/manifest.txt"

    run dotfiles restore --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "[DRY-RUN]" ]]
    [ ! -L "${TEST_HOME}/.zshrc" ]
}

@test "dotfiles restore creates symlinks for tracked files" {
    mkdir -p "${DOTFILES_DIR}/files/zsh"
    echo "# zshrc" > "${DOTFILES_DIR}/files/zsh/.zshrc"
    echo -e "files/zsh/.zshrc\t${TEST_HOME}/.zshrc" > "${DOTFILES_DIR}/files/manifest.txt"

    # Initialize git first (needed for git_pull in restore)
    git -C "$DOTFILES_DIR" init --quiet
    git -C "$DOTFILES_DIR" add -A
    git -C "$DOTFILES_DIR" commit -m "init" --quiet

    # Unset remote so restore doesn't try to pull
    export DOTFILES_REMOTE=""

    run dotfiles restore --profile default
    [ "$status" -eq 0 ]
    [ -L "${TEST_HOME}/.zshrc" ]
}

@test "dotfiles backup creates a git commit with timestamp message" {
    git -C "$DOTFILES_DIR" init --quiet
    echo "# file" > "${DOTFILES_DIR}/files/test.txt"

    run dotfiles backup
    [ "$status" -eq 0 ]

    local msg
    msg="$(git -C "$DOTFILES_DIR" log --format=%s -1)"
    [[ "$msg" =~ "dotfiles backup:" ]]
}

@test "bootstrap.sh runs without errors on minimal config" {
    # Run bootstrap with no remote (just sets up empty repo)
    run bash "${DOTFILES_DIR}/bin/bootstrap.sh" --no-chsh
    # Should not exit 2 (fatal error) even if some steps are no-ops
    [ "$status" -ne 2 ]
}

@test "dotfiles is idempotent: restore twice produces same state" {
    mkdir -p "${DOTFILES_DIR}/files/zsh"
    echo "# zshrc" > "${DOTFILES_DIR}/files/zsh/.zshrc"
    echo -e "files/zsh/.zshrc\t${TEST_HOME}/.zshrc" > "${DOTFILES_DIR}/files/manifest.txt"
    export DOTFILES_REMOTE=""

    git -C "$DOTFILES_DIR" init --quiet
    git -C "$DOTFILES_DIR" add -A
    git -C "$DOTFILES_DIR" commit -m "init" --quiet

    dotfiles restore --profile default >/dev/null

    local state1
    state1="$(find "$TEST_HOME" -maxdepth 1 | sort)"

    dotfiles restore --profile default >/dev/null

    local state2
    state2="$(find "$TEST_HOME" -maxdepth 1 | sort)"

    [ "$state1" = "$state2" ]
}
