#!/usr/bin/env bash
# tests/helpers/setup_helpers.bash
# Common setup() and teardown() functions for bats test suites.
# Uses temporary directories to isolate each test.

# DOTFILES_TEST_DIR is set per-test to a fresh temp dir acting as a Config_Store.

setup_dotfiles_env() {
    # Create a temporary Config_Store for the test
    export DOTFILES_TEST_DIR
    DOTFILES_TEST_DIR="$(mktemp -d)"
    export DOTFILES_DIR="$DOTFILES_TEST_DIR"

    # Create required structure
    mkdir -p "${DOTFILES_DIR}/bin/lib"
    mkdir -p "${DOTFILES_DIR}/config"
    mkdir -p "${DOTFILES_DIR}/files"
    mkdir -p "${DOTFILES_DIR}/profiles"
    touch "${DOTFILES_DIR}/files/manifest.txt"

    # Write minimal config
    cat > "${DOTFILES_DIR}/config/dotfiles.conf" <<'CONF'
DOTFILES_REMOTE=""
DOTFILES_PROFILE="default"
DOTFILES_PLUGIN_MANAGER="zinit"
DOTFILES_BRANCH="main"
CONF

    # Write default exclusions
    cat > "${DOTFILES_DIR}/config/exclusions.txt" <<'EXCL'
*_rsa
*_ed25519
*_ecdsa
*_dsa
*.pem
*.key
*.p12
*.pfx
*password*
*secret*
*token*
*credential*
*.env
.netrc
EXCL

    # Write default profile
    cat > "${DOTFILES_DIR}/profiles/default.yaml" <<'YAML'
name: default
description: Default profile
extends:
files:
  - zsh/.zshrc
  - zsh/.zprofile
  - zsh/.zshenv
  - git/.gitconfig
  - vim/.vimrc
  - tmux/.tmux.conf
  - ssh/config
tools:
  - zsh
  - git
  - vim
  - tmux
  - fzf
YAML

    # Create a fake HOME for the test
    export DOTFILES_ORIGINAL_HOME="$HOME"
    export HOME
    HOME="$(mktemp -d)"
}

teardown_dotfiles_env() {
    # Remove temp directories
    if [ -n "${DOTFILES_TEST_DIR:-}" ] && [ -d "$DOTFILES_TEST_DIR" ]; then
        rm -rf "$DOTFILES_TEST_DIR"
    fi
    if [ -n "${DOTFILES_ORIGINAL_HOME:-}" ]; then
        # Only remove if it's a temp dir
        case "$HOME" in
            /tmp/*) rm -rf "$HOME" ;;
        esac
        export HOME="$DOTFILES_ORIGINAL_HOME"
    fi
    unset DOTFILES_DIR DOTFILES_TEST_DIR
}

# Helper: create a temp file with given content
create_temp_file() {
    local content="${1:-hello world}"
    local tmpfile
    tmpfile="$(mktemp)"
    echo "$content" > "$tmpfile"
    echo "$tmpfile"
}

# Helper: create a regular file at a given path with content
create_file_at() {
    local path="$1"
    local content="${2:-default content}"
    mkdir -p "$(dirname "$path")"
    echo "$content" > "$path"
}

# Helper: assert that a path is a symlink pointing to expected target
assert_symlink_to() {
    local link="$1"
    local expected_target="$2"

    if [ ! -L "$link" ]; then
        echo "ASSERTION FAILED: '$link' is not a symlink" >&2
        return 1
    fi

    local actual_target
    actual_target="$(readlink "$link")"
    if [ "$actual_target" != "$expected_target" ]; then
        echo "ASSERTION FAILED: '$link' → '$actual_target' (expected '$expected_target')" >&2
        return 1
    fi
}

# Helper: source all lib scripts
source_lib() {
    local lib_root
    lib_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../bin/lib" && pwd)"
    # shellcheck disable=SC1090
    . "${lib_root}/config.sh"
    . "${lib_root}/sensitive.sh"
    . "${lib_root}/tracker.sh"
    . "${lib_root}/symlink.sh"
    . "${lib_root}/profile.sh"
    . "${lib_root}/git.sh"
}
