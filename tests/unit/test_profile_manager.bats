#!/usr/bin/env bats
# tests/unit/test_profile_manager.bats
# Unit tests for bin/lib/profile.sh

load '../helpers/setup_helpers'

BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
LIB_DIR="${BATS_TEST_DIRNAME}/../../bin/lib"

setup() {
    setup_dotfiles_env
    # shellcheck disable=SC1090
    . "${LIB_DIR}/profile.sh"

    # Create test profiles
    cat > "${DOTFILES_DIR}/profiles/default.yaml" <<'YAML'
name: default
description: Default profile
extends:
files:
  - zsh/.zshrc
  - zsh/.zprofile
  - git/.gitconfig
tools:
  - zsh
  - git
YAML

    cat > "${DOTFILES_DIR}/profiles/server.yaml" <<'YAML'
name: server
description: Server profile
extends: default
files:
  - tmux/.tmux.conf
  - ssh/config
tools:
  - tmux
exclude_tools:
  - gui-apps
YAML

    cat > "${DOTFILES_DIR}/profiles/personal.yaml" <<'YAML'
name: personal
description: Personal profile
extends: default
files:
  - vim/.vimrc
tools:
  - vim
YAML
}

teardown() {
    teardown_dotfiles_env
}

@test "list_profiles returns all .yaml profile names" {
    run list_profiles
    [ "$status" -eq 0 ]
    [[ "$output" =~ "default" ]]
    [[ "$output" =~ "server" ]]
    [[ "$output" =~ "personal" ]]
}

@test "get_profile_files returns files for default profile" {
    run get_profile_files "default"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "zsh/.zshrc" ]]
    [[ "$output" =~ "git/.gitconfig" ]]
}

@test "get_profile_files includes inherited files from parent" {
    run get_profile_files "server"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "zsh/.zshrc" ]]
    [[ "$output" =~ "tmux/.tmux.conf" ]]
}

@test "get_profile_tools returns tools for default profile" {
    run get_profile_tools "default"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "zsh" ]]
    [[ "$output" =~ "git" ]]
}

@test "get_profile_tools includes inherited tools from parent" {
    run get_profile_tools "server"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "zsh" ]]
    [[ "$output" =~ "tmux" ]]
}

@test "load_profile warns and returns 1 for missing profile" {
    run load_profile "nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "WARNING" ]]
}
