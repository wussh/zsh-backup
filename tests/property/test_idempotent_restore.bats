#!/usr/bin/env bats
# tests/property/test_idempotent_restore.bats
# Property 2: Idempotent restore
# Feature: zsh-dotfiles-setup, Property 2: idempotent restore
#
# Running `dotfiles restore` twice SHALL produce the same filesystem state.

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
}

teardown() {
    teardown_dotfiles_env
}

_setup_tracked_files() {
    local count="${1:-3}"
    for i in $(seq 1 "$count"); do
        local fname=".safe_file_${i}_$(gen_random_string 4)"
        local src="${HOME}/${fname}"
        echo "content_$i" > "$src"
        track_file "$src" >/dev/null 2>&1 || true
    done
}

_property2_iteration() {
    local _iter="$1"
    local manifest="${DOTFILES_DIR}/files/manifest.txt"

    _setup_tracked_files 2

    # First restore
    restore_all_symlinks "default" "false" >/dev/null 2>&1

    # Capture state after first restore
    local state1
    state1="$(find "$HOME" -maxdepth 1 -name '.safe_file_*' | sort)"

    # Count .bak files
    local bak1
    bak1="$(find "$HOME" -maxdepth 1 -name '*.bak.*' 2>/dev/null | wc -l)"

    # Second restore
    restore_all_symlinks "default" "false" >/dev/null 2>&1

    local state2
    state2="$(find "$HOME" -maxdepth 1 -name '.safe_file_*' | sort)"

    local bak2
    bak2="$(find "$HOME" -maxdepth 1 -name '*.bak.*' 2>/dev/null | wc -l)"

    if [ "$state1" != "$state2" ]; then
        echo "Iteration $_iter: filesystem state changed between restores" >&2
        return 1
    fi

    if [ "$bak1" != "$bak2" ]; then
        echo "Iteration $_iter: extra .bak files created on second restore" >&2
        return 1
    fi

    # Cleanup
    > "$manifest"
    find "$HOME" -maxdepth 1 -name '.safe_file_*' -delete 2>/dev/null || true
    find "$HOME" -maxdepth 1 -name '*.bak.*' -delete 2>/dev/null || true
    return 0
}

@test "Property 2: idempotent restore (${PROPERTY_ITERATIONS} iterations)" {
    local failed=0
    for i in $(seq 1 "$PROPERTY_ITERATIONS"); do
        _property2_iteration "$i" || ((failed++))
    done
    [ "$failed" -eq 0 ]
}
