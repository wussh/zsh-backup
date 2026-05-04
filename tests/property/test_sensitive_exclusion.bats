#!/usr/bin/env bats
# tests/property/test_sensitive_exclusion.bats
# Property 3: Sensitive file exclusion
# Feature: zsh-dotfiles-setup, Property 3: sensitive file exclusion
#
# For any path matching an exclusion pattern, is_sensitive() SHALL return true.

load '../helpers/setup_helpers'
load '../helpers/generators'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

PROPERTY_ITERATIONS="${PROPERTY_ITERATIONS:-100}"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/sensitive.sh"
    load_exclusions
}

teardown() {
    teardown_dotfiles_env
}

_property3_iteration() {
    local _iter="$1"
    local fname
    fname="$(gen_sensitive_filename)"
    local path="/home/user/${fname}"

    if ! is_sensitive "$path"; then
        echo "Iteration $_iter: is_sensitive returned false for '$fname'" >&2
        return 1
    fi

    return 0
}

@test "Property 3: sensitive file exclusion (${PROPERTY_ITERATIONS} iterations)" {
    local failed=0
    for i in $(seq 1 "$PROPERTY_ITERATIONS"); do
        _property3_iteration "$i" || ((failed++))
    done
    [ "$failed" -eq 0 ]
}

_property3_custom_iteration() {
    local _iter="$1"
    local pattern="*.custom_priv_${_iter}"
    local fname="mykey.custom_priv_${_iter}"
    local path="/home/user/${fname}"

    add_user_exclusion "$pattern" >/dev/null
    load_exclusions

    if ! is_sensitive "$path"; then
        echo "Iteration $_iter: custom exclusion not detected for '$fname'" >&2
        return 1
    fi

    return 0
}

@test "Property 3: user-defined exclusions treated identically to defaults (${PROPERTY_ITERATIONS} iterations)" {
    local failed=0
    for i in $(seq 1 "$PROPERTY_ITERATIONS"); do
        _property3_custom_iteration "$i" || ((failed++))
    done
    [ "$failed" -eq 0 ]
}
