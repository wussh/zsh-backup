#!/usr/bin/env bats
# tests/unit/test_plugins.bats

setup() {
    load "../helpers/setup_helpers.bash"
    setup_dotfiles_env
    source_lib

    # Mock directory for plugin managers
    export MOCK_HOME="$HOME"
    mkdir -p "$MOCK_HOME"

    # Mock external commands by adding a temp bin to PATH
    export MOCK_BIN="${DOTFILES_TEST_DIR}/mock_bin"
    mkdir -p "$MOCK_BIN"
    export PATH="$MOCK_BIN:$PATH"

    # Default mocks (can be overridden in tests)
    cat <<EOF > "${MOCK_BIN}/curl"
#!/bin/sh
echo "mock curl called with: \$*"
exit 0
EOF
    chmod +x "${MOCK_BIN}/curl"

    cat <<EOF > "${MOCK_BIN}/zsh"
#!/bin/sh
echo "mock zsh called with: \$*"
exit 0
EOF
    chmod +x "${MOCK_BIN}/zsh"

    cat <<EOF > "${MOCK_BIN}/git"
#!/bin/sh
echo "mock git called with: \$*"
exit 0
EOF
    chmod +x "${MOCK_BIN}/git"
}

teardown() {
    teardown_dotfiles_env
}

@test "is_plugin_manager_installed returns 0 if zinit is present" {
    export DOTFILES_PLUGIN_MANAGER="zinit"
    mkdir -p "${HOME}/.local/share/zinit/zinit.git"
    touch "${HOME}/.local/share/zinit/zinit.git/zinit.zsh"
    run is_plugin_manager_installed "zinit"
    [ "$status" -eq 0 ]
}

@test "is_plugin_manager_installed returns 1 if zinit is missing" {
    export DOTFILES_PLUGIN_MANAGER="zinit"
    run is_plugin_manager_installed "zinit"
    [ "$status" -eq 1 ]
}

@test "install_plugin_manager zinit calls curl" {
    export DOTFILES_PLUGIN_MANAGER="zinit"
    run install_plugin_manager "zinit"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installing zinit..." ]]
    [[ "$output" =~ "mock curl called" ]]
}

@test "install_plugin zinit calls zsh" {
    export DOTFILES_PLUGIN_MANAGER="zinit"
    # Mock zinit installed
    mkdir -p "${HOME}/.local/share/zinit/zinit.git"
    touch "${HOME}/.local/share/zinit/zinit.git/zinit.zsh"
    
    run install_plugin "user/repo"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mock zsh called" ]]
    [[ "$output" =~ "zinit light 'user/repo'" ]]
}

@test "install_all_plugins reads plugins.txt" {
    echo "user/repo1" > "${DOTFILES_DIR}/plugins.txt"
    echo "user/repo2" >> "${DOTFILES_DIR}/plugins.txt"
    
    # Mock zinit
    export DOTFILES_PLUGIN_MANAGER="zinit"
    mkdir -p "${HOME}/.local/share/zinit/zinit.git"
    touch "${HOME}/.local/share/zinit/zinit.git/zinit.zsh"

    run install_all_plugins
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installed plugin user/repo1" ]]
    [[ "$output" =~ "Installed plugin user/repo2" ]]
}
