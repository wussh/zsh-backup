#!/usr/bin/env bash
# bin/lib/config.sh
# Config Loader — reads and writes config/dotfiles.conf
# All functions respect environment variable overrides.

# Determine the Config_Store root directory
# DOTFILES_DIR must be set by the caller (dotfiles CLI or bootstrap.sh)
# before sourcing this file.

# load_config: sources config/dotfiles.conf and applies env var overrides.
# Environment variables set before calling load_config take precedence.
load_config() {
    local conf_file="${DOTFILES_DIR}/config/dotfiles.conf"

    # Save any env overrides before sourcing (sourcing would overwrite them)
    local env_remote="${DOTFILES_REMOTE:-}"
    local env_profile="${DOTFILES_PROFILE:-}"
    local env_plugin_manager="${DOTFILES_PLUGIN_MANAGER:-}"
    local env_branch="${DOTFILES_BRANCH:-}"

    if [ -f "$conf_file" ]; then
        # shellcheck source=/dev/null
        . "$conf_file"
    fi

    # Re-apply env overrides (env takes precedence over file)
    [ -n "$env_remote" ]         && DOTFILES_REMOTE="$env_remote"
    [ -n "$env_profile" ]        && DOTFILES_PROFILE="$env_profile"
    [ -n "$env_plugin_manager" ] && DOTFILES_PLUGIN_MANAGER="$env_plugin_manager"
    [ -n "$env_branch" ]         && DOTFILES_BRANCH="$env_branch"

    # Set defaults if still unset
    DOTFILES_REMOTE="${DOTFILES_REMOTE:-}"
    DOTFILES_PROFILE="${DOTFILES_PROFILE:-default}"
    DOTFILES_PLUGIN_MANAGER="${DOTFILES_PLUGIN_MANAGER:-zinit}"
    DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

    export DOTFILES_REMOTE DOTFILES_PROFILE DOTFILES_PLUGIN_MANAGER DOTFILES_BRANCH
}

# get_config: prints the value of a config key.
# Usage: get_config KEY
get_config() {
    local key="$1"
    local conf_file="${DOTFILES_DIR}/config/dotfiles.conf"

    if [ -z "$key" ]; then
        echo "ERROR: get_config requires a key argument" >&2
        return 1
    fi

    if [ ! -f "$conf_file" ]; then
        echo "ERROR: Config file not found: $conf_file" >&2
        return 1
    fi

    # Extract value: match KEY="value" or KEY=value
    local value
    value=$(grep "^${key}=" "$conf_file" | head -1 | sed "s/^${key}=//;s/^['\"]//;s/['\"]$//")
    echo "$value"
}

# set_config: sets a key=value pair in config/dotfiles.conf.
# Updates existing key or appends if not found.
# Usage: set_config KEY VALUE
set_config() {
    local key="$1"
    local value="$2"
    local conf_file="${DOTFILES_DIR}/config/dotfiles.conf"

    if [ -z "$key" ]; then
        echo "ERROR: set_config requires a key argument" >&2
        return 1
    fi

    # Create config directory and file if they don't exist
    mkdir -p "$(dirname "$conf_file")"
    touch "$conf_file"

    if grep -q "^${key}=" "$conf_file"; then
        # Replace existing line using a temp file for portability
        local tmp_file
        tmp_file=$(mktemp)
        sed "s|^${key}=.*|${key}=\"${value}\"|" "$conf_file" > "$tmp_file"
        mv "$tmp_file" "$conf_file"
    else
        # Append new key
        echo "${key}=\"${value}\"" >> "$conf_file"
    fi
}

# init_config: creates a default config/dotfiles.conf if none exists.
init_config() {
    local conf_file="${DOTFILES_DIR}/config/dotfiles.conf"

    if [ -f "$conf_file" ]; then
        return 0
    fi

    mkdir -p "$(dirname "$conf_file")"
    cat > "$conf_file" << 'EOF'
# Dotfiles Manager Configuration
# This file is sourced as shell script. Values can be overridden by environment variables.

# Remote git repository URL for the Config_Store
DOTFILES_REMOTE=""

# Active profile name (default, personal, server, work)
DOTFILES_PROFILE="default"

# Plugin manager to use (zinit, oh-my-zsh, antigen)
DOTFILES_PLUGIN_MANAGER="zinit"

# Git branch to use for the Config_Store
DOTFILES_BRANCH="main"
EOF
}
