#!/usr/bin/env bats
# tests/property/test_symlink_roundtrip.bats
# Property 1: Symlink round-trip correctness
# Feature: zsh-dotfiles-setup, Property 1: symlink round-trip correctness
#
# For any tracked file, after `dotfiles add <path>` followed by `dotfiles restore`,
# the original path SHALL exist as a symlink pointing to the correct store file,
# and the content accessible via the symlink SHALL be identical to the original.

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
    load_exclusions
}

teardown() {
    teardown_dotfiles_env
}

_property1_iteration() {
    local _iter="$1"

    # Generate random file name and content
    local fname
    fname=".dotfile_safe_$(gen_random_string 8)"
    local content
    content="$(gen_random_content 3)"

    local src="${HOME}/${fname}"
    echo "$content" > "$src"

    # Track the file
    track_file "$src" >/dev/null

    # Get store path and create symlink
    local store_rel
    store_rel="$(get_store_path "$src")"
    local store_abs="${DOTFILES_DIR}/${store_rel}"

    # Remove original and restore via symlink
    rm "$src"
    create_symlink "$store_abs" "$src" >/dev/null

    # Assert: symlink exists and content is correct
    if [ ! -L "$src" ]; then
        echo "Iteration $_iter: $src is not a symlink" >&2
        return 1
    fi

    local restored_content
    restored_content="$(cat "$src")"
    if [ "$restored_content" != "$content" ]; then
        echo "Iteration $_iter: content mismatch" >&2
        return 1
    fi

    # Cleanup
    rm -f "$src" "$store_abs"
    sed -i "/$fname/d" "${DOTFILES_DIR}/files/manifest.txt" 2>/dev/null || true
    return 0
}

@test "Property 1: symlink round-trip correctness (${PROPERTY_ITERATIONS} iterations)" {
    local failed=0
    for i in $(seq 1 "$PROPERTY_ITERATIONS"); do
        _property1_iteration "$i" || ((failed++))
    done
    [ "$failed" -eq 0 ]
}
