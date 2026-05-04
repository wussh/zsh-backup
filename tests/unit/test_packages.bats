#!/usr/bin/env bats
# tests/unit/test_packages.bats
# Unit tests for bin/lib/packages.sh

load '../helpers/setup_helpers'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/packages.sh"
}

teardown() {
    teardown_dotfiles_env
    unset PKG_MANAGER
}

@test "detect_package_manager sets PKG_MANAGER to a supported value" {
    PKG_MANAGER=""
    detect_package_manager
    local supported="brew apt-get dnf yum pacman apk"
    [[ "$supported" =~ $PKG_MANAGER ]]
}

@test "is_package_installed returns 0 for bash (always present)" {
    run is_package_installed "bash"
    [ "$status" -eq 0 ]
}

@test "is_package_installed returns 1 for nonexistent command" {
    run is_package_installed "this_command_does_not_exist_xyz_abc_123"
    [ "$status" -eq 1 ]
}

@test "detect_package_manager returns 2 when no package manager is available" {
    # Mock PATH to remove all package managers
    local original_PATH="$PATH"
    PATH="/no/such/path"
    run detect_package_manager
    PATH="$original_PATH"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "No supported package manager found" ]]
}

@test "install_package error message lists supported managers on failure" {
    local original_PATH="$PATH"
    PATH="/no/such/path"
    PKG_MANAGER=""
    run detect_package_manager
    PATH="$original_PATH"
    [[ "$output" =~ "brew" ]]
    [[ "$output" =~ "apt-get" ]]
    [[ "$output" =~ "pacman" ]]
}
