#!/usr/bin/env bats
# tests/unit/test_symlink_manager.bats
# Unit tests for bin/lib/symlink.sh

load '../helpers/setup_helpers'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/symlink.sh"
}

teardown() {
    teardown_dotfiles_env
}

@test "create_symlink creates a symlink at target_path" {
    local store_file="${DOTFILES_DIR}/files/zsh/.zshrc"
    mkdir -p "$(dirname "$store_file")"
    echo "# zshrc" > "$store_file"

    local target="${HOME}/.zshrc"
    create_symlink "$store_file" "$target"

    [ -L "$target" ]
    assert_symlink_to "$target" "$store_file"
}

@test "create_symlink backs up existing regular file" {
    local store_file="${DOTFILES_DIR}/files/zsh/.zshrc"
    mkdir -p "$(dirname "$store_file")"
    echo "# stored" > "$store_file"

    local target="${HOME}/.zshrc"
    echo "# original" > "$target"

    create_symlink "$store_file" "$target"

    # Backup should exist
    local bak_count
    bak_count="$(ls "${HOME}"/.zshrc.bak.* 2>/dev/null | wc -l)"
    [ "$bak_count" -ge 1 ]
    [ -L "$target" ]
}

@test "create_symlink is idempotent (already up-to-date)" {
    local store_file="${DOTFILES_DIR}/files/zsh/.zshrc"
    mkdir -p "$(dirname "$store_file")"
    echo "# zshrc" > "$store_file"

    local target="${HOME}/.zshrc"
    create_symlink "$store_file" "$target"
    create_symlink "$store_file" "$target"

    # Should still be one correct symlink, no extra backup
    local bak_count
    bak_count="$(ls "${HOME}"/.zshrc.bak.* 2>/dev/null | wc -l)"
    [ "$bak_count" -eq 0 ]
    [ -L "$target" ]
}

@test "validate_symlink returns 0 for correct symlink" {
    local store_file="${DOTFILES_DIR}/files/zsh/.zshrc"
    mkdir -p "$(dirname "$store_file")"
    echo "# zshrc" > "$store_file"

    local target="${HOME}/.zshrc"
    ln -s "$store_file" "$target"

    run validate_symlink "$target" "$store_file"
    [ "$status" -eq 0 ]
}

@test "validate_symlink returns 1 for missing symlink" {
    run validate_symlink "${HOME}/.no_such_link" "${DOTFILES_DIR}/files/zsh/.zshrc"
    [ "$status" -eq 1 ]
}

@test "validate_symlink returns 1 for wrong target symlink" {
    local target="${HOME}/.zshrc"
    ln -s "/some/other/path" "$target"

    run validate_symlink "$target" "${DOTFILES_DIR}/files/zsh/.zshrc"
    [ "$status" -eq 1 ]
}

@test "create_symlink dry_run prints action without modifying filesystem" {
    local store_file="${DOTFILES_DIR}/files/zsh/.zshrc"
    mkdir -p "$(dirname "$store_file")"
    echo "# zshrc" > "$store_file"

    local target="${HOME}/.zshrc"
    run create_symlink "$store_file" "$target" "true"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "[DRY-RUN]" ]]
    [ ! -L "$target" ]
}
