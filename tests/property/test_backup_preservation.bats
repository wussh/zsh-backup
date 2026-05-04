#!/usr/bin/env bats
# tests/property/test_backup_preservation.bats
# Property 5: Backup file preservation
# Feature: zsh-dotfiles-setup, Property 5: backup file preservation
#
# For any regular file at a target path, restore SHALL create a .bak copy
# before replacing it with a symlink.

load '../helpers/setup_helpers'
load '../helpers/generators'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

PROPERTY_ITERATIONS="${PROPERTY_ITERATIONS:-100}"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/symlink.sh"
}

teardown() {
    teardown_dotfiles_env
}

_property5_iteration() {
    local _iter="$1"

    local fname=".regular_file_${_iter}"
    local content="original_content_${_iter}_$(gen_random_string 8)"
    local target="${HOME}/${fname}"
    local store_file="${DOTFILES_DIR}/files/test/${fname}"

    # Create original regular file at target
    echo "$content" > "$target"

    # Create a store file
    mkdir -p "$(dirname "$store_file")"
    echo "new_content_${_iter}" > "$store_file"

    # Create symlink (should backup regular file)
    create_symlink "$store_file" "$target" >/dev/null 2>&1

    # Assert: backup file exists with original content
    local bak_file
    bak_file="$(ls "${HOME}/${fname}.bak."* 2>/dev/null | head -1)"

    if [ -z "$bak_file" ]; then
        echo "Iteration $_iter: no .bak file created" >&2
        return 1
    fi

    local bak_content
    bak_content="$(cat "$bak_file")"
    if [ "$bak_content" != "$content" ]; then
        echo "Iteration $_iter: .bak content mismatch" >&2
        return 1
    fi

    # Assert: target is now a symlink
    if [ ! -L "$target" ]; then
        echo "Iteration $_iter: target is not a symlink after restore" >&2
        return 1
    fi

    # Cleanup
    rm -f "$target" "$bak_file" "$store_file"
    return 0
}

@test "Property 5: backup file preservation (${PROPERTY_ITERATIONS} iterations)" {
    local failed=0
    for i in $(seq 1 "$PROPERTY_ITERATIONS"); do
        _property5_iteration "$i" || ((failed++))
    done
    [ "$failed" -eq 0 ]
}
