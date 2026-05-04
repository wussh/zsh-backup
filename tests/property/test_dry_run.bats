#!/usr/bin/env bats
# tests/property/test_dry_run.bats
# Property 8: Dry-run non-modification
# Feature: zsh-dotfiles-setup, Property 8: dry-run non-modification
#
# Running `dotfiles restore --dry-run` SHALL produce no changes to the filesystem.

load '../helpers/setup_helpers'
load '../helpers/generators'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

PROPERTY_ITERATIONS="${PROPERTY_ITERATIONS:-100}"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/sensitive.sh"
    . "${LIB_DIR}/tracker.sh"
    . "${LIB_DIR}/symlink.sh"
    . "${LIB_DIR}/profile.sh"
    load_exclusions

    # Set up some tracked files in the store
    mkdir -p "${DOTFILES_DIR}/files/zsh"
    echo "# zshrc" > "${DOTFILES_DIR}/files/zsh/.zshrc"
    echo -e "files/zsh/.zshrc\t${HOME}/.zshrc" > "${DOTFILES_DIR}/files/manifest.txt"
}

teardown() {
    teardown_dotfiles_env
}

_property8_iteration() {
    local _iter="$1"

    # Ensure no symlink exists at target
    rm -f "${HOME}/.zshrc"

    # Capture filesystem state before
    local before_home
    before_home="$(find "$HOME" -maxdepth 1 | sort)"
    local before_store
    before_store="$(find "${DOTFILES_DIR}/files" | sort)"

    # Run dry-run restore
    restore_all_symlinks "default" "true" >/dev/null 2>&1

    # Capture filesystem state after
    local after_home
    after_home="$(find "$HOME" -maxdepth 1 | sort)"
    local after_store
    after_store="$(find "${DOTFILES_DIR}/files" | sort)"

    if [ "$before_home" != "$after_home" ]; then
        echo "Iteration $_iter: HOME changed during dry-run" >&2
        return 1
    fi

    if [ "$before_store" != "$after_store" ]; then
        echo "Iteration $_iter: store changed during dry-run" >&2
        return 1
    fi

    return 0
}

@test "Property 8: dry-run non-modification (${PROPERTY_ITERATIONS} iterations)" {
    local failed=0
    for i in $(seq 1 "$PROPERTY_ITERATIONS"); do
        _property8_iteration "$i" || ((failed++))
    done
    [ "$failed" -eq 0 ]
}
