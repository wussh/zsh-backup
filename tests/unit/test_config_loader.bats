#!/usr/bin/env bats
# tests/unit/test_config_loader.bats
# Unit tests for bin/lib/config.sh

setup() {
    # Create a temporary directory for each test
    TEST_DIR="$(mktemp -d)"
    export DOTFILES_DIR="$TEST_DIR"
    mkdir -p "$TEST_DIR/config"

    # Source the config loader
    # shellcheck source=bin/lib/config.sh
    source "${BATS_TEST_DIRNAME}/../../bin/lib/config.sh"

    # Clear any env overrides from previous tests
    unset DOTFILES_REMOTE DOTFILES_PROFILE DOTFILES_PLUGIN_MANAGER DOTFILES_BRANCH
}

teardown() {
    rm -rf "$TEST_DIR"
}

# --- load_config tests ---

@test "load_config: sources conf file and sets DOTFILES_PROFILE" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_PROFILE="myprofile"
DOTFILES_PLUGIN_MANAGER="oh-my-zsh"
DOTFILES_BRANCH="develop"
DOTFILES_REMOTE="https://example.com/dotfiles.git"
EOF
    load_config
    [ "$DOTFILES_PROFILE" = "myprofile" ]
}

@test "load_config: sets default DOTFILES_PROFILE when conf missing" {
    load_config
    [ "$DOTFILES_PROFILE" = "default" ]
}

@test "load_config: sets default DOTFILES_PLUGIN_MANAGER when conf missing" {
    load_config
    [ "$DOTFILES_PLUGIN_MANAGER" = "zinit" ]
}

@test "load_config: sets default DOTFILES_BRANCH when conf missing" {
    load_config
    [ "$DOTFILES_BRANCH" = "main" ]
}

@test "load_config: env var DOTFILES_PROFILE overrides conf file value" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_PROFILE="from_file"
EOF
    export DOTFILES_PROFILE="from_env"
    load_config
    [ "$DOTFILES_PROFILE" = "from_env" ]
}

@test "load_config: env var DOTFILES_PLUGIN_MANAGER overrides conf file value" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_PLUGIN_MANAGER="oh-my-zsh"
EOF
    export DOTFILES_PLUGIN_MANAGER="antigen"
    load_config
    [ "$DOTFILES_PLUGIN_MANAGER" = "antigen" ]
}

@test "load_config: env var DOTFILES_BRANCH overrides conf file value" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_BRANCH="develop"
EOF
    export DOTFILES_BRANCH="feature-branch"
    load_config
    [ "$DOTFILES_BRANCH" = "feature-branch" ]
}

@test "load_config: env var DOTFILES_REMOTE overrides conf file value" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_REMOTE="https://file.example.com/dotfiles.git"
EOF
    export DOTFILES_REMOTE="https://env.example.com/dotfiles.git"
    load_config
    [ "$DOTFILES_REMOTE" = "https://env.example.com/dotfiles.git" ]
}

# --- get_config tests ---

@test "get_config: returns correct value for existing key" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_PROFILE="server"
EOF
    result=$(get_config DOTFILES_PROFILE)
    [ "$result" = "server" ]
}

@test "get_config: returns empty string for key with empty value" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_REMOTE=""
EOF
    result=$(get_config DOTFILES_REMOTE)
    [ "$result" = "" ]
}

@test "get_config: fails with error when conf file missing" {
    run get_config DOTFILES_PROFILE
    [ "$status" -ne 0 ]
}

@test "get_config: fails with error when no key argument" {
    touch "$TEST_DIR/config/dotfiles.conf"
    run get_config
    [ "$status" -ne 0 ]
}

# --- set_config tests ---

@test "set_config: updates existing key in conf file" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_PROFILE="default"
EOF
    set_config DOTFILES_PROFILE "server"
    result=$(get_config DOTFILES_PROFILE)
    [ "$result" = "server" ]
}

@test "set_config: appends new key if not present" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_PROFILE="default"
EOF
    set_config DOTFILES_BRANCH "develop"
    result=$(get_config DOTFILES_BRANCH)
    [ "$result" = "develop" ]
}

@test "set_config: creates conf file if it does not exist" {
    set_config DOTFILES_PROFILE "personal"
    [ -f "$TEST_DIR/config/dotfiles.conf" ]
    result=$(get_config DOTFILES_PROFILE)
    [ "$result" = "personal" ]
}

# --- init_config tests ---

@test "init_config: creates conf file if it does not exist" {
    init_config
    [ -f "$TEST_DIR/config/dotfiles.conf" ]
}

@test "init_config: created conf file contains DOTFILES_PROFILE default" {
    init_config
    result=$(get_config DOTFILES_PROFILE)
    [ "$result" = "default" ]
}

@test "init_config: does not overwrite existing conf file" {
    cat > "$TEST_DIR/config/dotfiles.conf" << 'EOF'
DOTFILES_PROFILE="custom"
EOF
    init_config
    result=$(get_config DOTFILES_PROFILE)
    [ "$result" = "custom" ]
}
