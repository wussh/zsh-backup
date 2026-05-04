#!/usr/bin/env bats
# tests/unit/test_sensitive_filter.bats
# Unit tests for bin/lib/sensitive.sh

load '../helpers/setup_helpers'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/sensitive.sh"
    load_exclusions
}

teardown() {
    teardown_dotfiles_env
}

@test "is_sensitive returns true for *_rsa file" {
    run is_sensitive "/home/user/.ssh/id_rsa"
    [ "$status" -eq 0 ]
}

@test "is_sensitive returns true for *_ed25519 file" {
    run is_sensitive "/home/user/.ssh/id_ed25519"
    [ "$status" -eq 0 ]
}

@test "is_sensitive returns true for *.pem file" {
    run is_sensitive "/tmp/server.pem"
    [ "$status" -eq 0 ]
}

@test "is_sensitive returns true for *password* file" {
    run is_sensitive "/home/user/mypassword.txt"
    [ "$status" -eq 0 ]
}

@test "is_sensitive returns true for *secret* file" {
    run is_sensitive "/home/user/.mysecret"
    [ "$status" -eq 0 ]
}

@test "is_sensitive returns true for *token* file" {
    run is_sensitive "/home/user/api_token"
    [ "$status" -eq 0 ]
}

@test "is_sensitive returns true for .netrc" {
    run is_sensitive "/home/user/.netrc"
    [ "$status" -eq 0 ]
}

@test "is_sensitive returns false for .zshrc" {
    run is_sensitive "/home/user/.zshrc"
    [ "$status" -eq 1 ]
}

@test "is_sensitive returns false for .gitconfig" {
    run is_sensitive "/home/user/.gitconfig"
    [ "$status" -eq 1 ]
}

@test "is_sensitive returns false for .vimrc" {
    run is_sensitive "/home/user/.vimrc"
    [ "$status" -eq 1 ]
}

@test "add_user_exclusion adds custom pattern and is_sensitive detects it" {
    add_user_exclusion "*.mypriv"
    run is_sensitive "/home/user/key.mypriv"
    [ "$status" -eq 0 ]
}

@test "add_user_exclusion does not add duplicate patterns" {
    add_user_exclusion "*.mypriv"
    add_user_exclusion "*.mypriv"
    local count
    count="$(grep -c "^\\*\\.mypriv$" "${DOTFILES_DIR}/config/exclusions.txt")"
    [ "$count" -eq 1 ]
}

@test "load_exclusions falls back to defaults when file missing" {
    rm -f "${DOTFILES_DIR}/config/exclusions.txt"
    EXCLUSION_PATTERNS=()
    load_exclusions
    [ "${#EXCLUSION_PATTERNS[@]}" -gt 0 ]
}
