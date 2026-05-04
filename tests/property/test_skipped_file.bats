#!/usr/bin/env bats
# tests/property/test_skipped_file.bats
# Property 7: Skipped-file non-modification
# Feature: zsh-dotfiles-setup, Property 7: skipped-file non-modification
#
# For any non-existent path, `dotfiles add <path>` SHALL leave
# the Config_Store unchanged and emit a warning to stderr.

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
    load_exclusions
}

teardown() {
    teardown_dotfiles_env
}

_property7_iteration() {
    local _iter="$1"

    local nonexistent="${HOME}/.nonexistent_$(gen_random_string 12)"

    # Capture store state before
    local before
    before="$(find "${DOTFILES_DIR}/files" -type f | sort)"
    local manifest_before
    manifest_before="$(cat "${DOTFILES_DIR}/files/manifest.txt" 2>/dev/null)"

    # Run track_file on a non-existent path
    local output
    output="$(track_file "$nonexistent" 2>&1)"
    local rc=$?

    # Capture store state after
    local after
    after="$(find "${DOTFILES_DIR}/files" -type f | sort)"
    local manifest_after
    manifest_after="$(cat "${DOTFILES_DIR}/files/manifest.txt" 2>/dev/null)"

    # Assert: non-zero return code
    if [ "$rc" -eq 0 ]; then
        echo "Iteration $_iter: expected non-zero exit for non-existent file" >&2
        return 1
    fi

    # Assert: warning emitted
    if [[ ! "$output" =~ "WARNING" ]]; then
        echo "Iteration $_iter: no WARNING emitted" >&2
        return 1
    fi

    # Assert: store unchanged
    if [ "$before" != "$after" ]; then
        echo "Iteration $_iter: store modified for non-existent file" >&2
        return 1
    fi

    # Assert: manifest unchanged
    if [ "$manifest_before" != "$manifest_after" ]; then
        echo "Iteration $_iter: manifest modified for non-existent file" >&2
        return 1
    fi

    return 0
}

@test "Property 7: skipped-file non-modification (${PROPERTY_ITERATIONS} iterations)" {
    local failed=0
    for i in $(seq 1 "$PROPERTY_ITERATIONS"); do
        _property7_iteration "$i" || ((failed++))
    done
    [ "$failed" -eq 0 ]
}
