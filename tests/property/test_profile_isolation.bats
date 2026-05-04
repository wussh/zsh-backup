#!/usr/bin/env bats
# tests/property/test_profile_isolation.bats
# Property 4: Profile file isolation
# Feature: zsh-dotfiles-setup, Property 4: profile file isolation
#
# For any profile P and any file F NOT in P, restore --profile P SHALL NOT
# create a symlink for file F.

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

_property4_iteration() {
    local _iter="$1"

    # Create two files
    local fname_a=".dotfile_a_${_iter}"
    local fname_b=".dotfile_b_${_iter}"
    echo "content_a" > "${HOME}/${fname_a}"
    echo "content_b" > "${HOME}/${fname_b}"

    # Manually create store files
    mkdir -p "${DOTFILES_DIR}/files/zsh"
    cp "${HOME}/${fname_a}" "${DOTFILES_DIR}/files/zsh/${fname_a}"

    # Write manifest with both files
    {
        echo -e "files/zsh/${fname_a}\t${HOME}/${fname_a}"
    } >> "${DOTFILES_DIR}/files/manifest.txt"

    # Create a profile that only includes fname_a
    cat > "${DOTFILES_DIR}/profiles/test_profile_${_iter}.yaml" <<YAML
name: test_profile_${_iter}
description: Test profile ${_iter}
extends:
files:
  - zsh/${fname_a}
tools: []
YAML

    # Run restore with that profile
    restore_all_symlinks "test_profile_${_iter}" "false" >/dev/null 2>&1

    # Assert: fname_a is a symlink
    if [ ! -L "${HOME}/${fname_a}" ]; then
        echo "Iteration $_iter: ${fname_a} should be a symlink" >&2
        return 1
    fi

    # Assert: fname_b is NOT a symlink (it's not in the profile)
    if [ -L "${HOME}/${fname_b}" ]; then
        echo "Iteration $_iter: ${fname_b} should NOT be a symlink" >&2
        return 1
    fi

    # Cleanup
    rm -f "${HOME}/${fname_a}" "${HOME}/${fname_b}"
    rm -f "${DOTFILES_DIR}/files/zsh/${fname_a}"
    rm -f "${DOTFILES_DIR}/profiles/test_profile_${_iter}.yaml"
    > "${DOTFILES_DIR}/files/manifest.txt"
    return 0
}

@test "Property 4: profile file isolation (${PROPERTY_ITERATIONS} iterations)" {
    local failed=0
    for i in $(seq 1 "$PROPERTY_ITERATIONS"); do
        _property4_iteration "$i" || ((failed++))
    done
    [ "$failed" -eq 0 ]
}
