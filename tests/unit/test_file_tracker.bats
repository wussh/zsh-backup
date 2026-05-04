#!/usr/bin/env bats
# tests/unit/test_file_tracker.bats
# Unit tests for bin/lib/tracker.sh

load '../helpers/setup_helpers'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/sensitive.sh"
    . "${LIB_DIR}/tracker.sh"
    load_exclusions
}

teardown() {
    teardown_dotfiles_env
}

@test "track_file copies file to store and creates manifest entry" {
    local src="${HOME}/.zshrc"
    echo "# zshrc" > "$src"

    track_file "$src"

    local store_rel
    store_rel="$(get_store_path "$src")"
    [ -f "${DOTFILES_DIR}/${store_rel}" ]

    grep -qF "$src" "${DOTFILES_DIR}/files/manifest.txt"
}

@test "track_file returns 1 and warns when file does not exist" {
    run track_file "${HOME}/.nonexistent_file_xyz"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "WARNING" ]]
}

@test "track_file overwrites existing tracked file with current version" {
    local src="${HOME}/.zshrc"
    echo "version1" > "$src"
    track_file "$src"

    echo "version2" > "$src"
    track_file "$src"

    local store_rel
    store_rel="$(get_store_path "$src")"
    local content
    content="$(cat "${DOTFILES_DIR}/${store_rel}")"
    [ "$content" = "version2" ]
}

@test "is_tracked returns true for tracked file" {
    local src="${HOME}/.zshrc"
    echo "# zshrc" > "$src"
    track_file "$src"

    run is_tracked "$src"
    [ "$status" -eq 0 ]
}

@test "is_tracked returns false for untracked file" {
    run is_tracked "${HOME}/.not_tracked"
    [ "$status" -eq 1 ]
}

@test "untrack_file removes file from store and manifest" {
    local src="${HOME}/.zshrc"
    echo "# zshrc" > "$src"
    track_file "$src"

    untrack_file "$src"

    run is_tracked "$src"
    [ "$status" -eq 1 ]

    local store_rel
    store_rel="$(get_store_path "$src")"
    [ ! -f "${DOTFILES_DIR}/${store_rel}" ]
}

@test "get_store_path maps .zshrc to files/zsh/.zshrc" {
    local result
    result="$(get_store_path "${HOME}/.zshrc")"
    [ "$result" = "files/zsh/.zshrc" ]
}

@test "get_store_path maps .gitconfig to files/git/.gitconfig" {
    local result
    result="$(get_store_path "${HOME}/.gitconfig")"
    [ "$result" = "files/git/.gitconfig" ]
}

@test "get_store_path maps .ssh/config to files/ssh/config" {
    local result
    result="$(get_store_path "${HOME}/.ssh/config")"
    [ "$result" = "files/ssh/config" ]
}
