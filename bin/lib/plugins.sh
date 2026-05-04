#!/usr/bin/env bash
# bin/lib/plugins.sh
# Plugin Installer — installs zsh plugins using the configured Plugin_Manager.
# Requires DOTFILES_DIR and DOTFILES_PLUGIN_MANAGER to be set before sourcing.

# is_plugin_manager_installed: checks for the plugin manager's presence.
# Usage: is_plugin_manager_installed <name>
is_plugin_manager_installed() {
    local name="${1:-${DOTFILES_PLUGIN_MANAGER:-zinit}}"

    case "$name" in
        zinit)
            [ -f "${HOME}/.local/share/zinit/zinit.git/zinit.zsh" ] || \
            [ -f "${HOME}/.zinit/bin/zinit.zsh" ]
            ;;
        oh-my-zsh)
            [ -d "${HOME}/.oh-my-zsh" ]
            ;;
        antigen)
            [ -f "${HOME}/.antigen/antigen.zsh" ] || command -v antigen &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# install_plugin_manager: installs the given plugin manager if not present.
# Usage: install_plugin_manager [name]
install_plugin_manager() {
    local name="${1:-${DOTFILES_PLUGIN_MANAGER:-zinit}}"

    if is_plugin_manager_installed "$name"; then
        echo "INFO: Plugin manager '$name' is already installed."
        return 0
    fi

    case "$name" in
        zinit)
            echo "INFO: Installing zinit..."
            bash -c "$(curl --fail --silent --show-error --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
            ;;
        oh-my-zsh)
            echo "INFO: Installing Oh My Zsh..."
            sh -c "$(curl --fail --silent --show-error --location https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            ;;
        antigen)
            echo "INFO: Installing antigen..."
            mkdir -p "${HOME}/.antigen"
            curl --fail --silent --show-error --location "https://git.io/antigen" -o "${HOME}/.antigen/antigen.zsh"
            ;;
        *)
            echo "ERROR: Unsupported plugin manager: $name" >&2
            echo "Supported: zinit, oh-my-zsh, antigen" >&2
            return 2
            ;;
    esac
}

# is_plugin_installed: checks if a plugin directory/file exists.
# Usage: is_plugin_installed <name>
is_plugin_installed() {
    local name="$1"
    local plugin_dir

    # Determine plugin directory based on plugin manager
    case "${DOTFILES_PLUGIN_MANAGER:-zinit}" in
        zinit)
            plugin_dir="${HOME}/.local/share/zinit/plugins"
            [ -d "${plugin_dir}/${name/\//_}" ] || [ -d "${plugin_dir}/${name}" ]
            ;;
        oh-my-zsh)
            plugin_dir="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins"
            local pname
            pname="$(basename "$name")"
            [ -d "${plugin_dir}/${pname}" ]
            ;;
        antigen)
            # Antigen bundles
            plugin_dir="${HOME}/.antigen/bundles"
            [ -d "${plugin_dir}/${name}" ] 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# install_plugin: installs a single plugin via the configured plugin manager.
# Usage: install_plugin <plugin_spec>
install_plugin() {
    local plugin_spec="$1"
    local pname
    pname="$(basename "$plugin_spec")"

    if is_plugin_installed "$plugin_spec"; then
        echo "INFO: Plugin '$pname' is already installed — skipping."
        return 0
    fi

    case "${DOTFILES_PLUGIN_MANAGER:-zinit}" in
        zinit)
            # zinit light installs without tracking
            zsh -c "source \${HOME}/.local/share/zinit/zinit.git/zinit.zsh 2>/dev/null || \
                    source \${HOME}/.zinit/bin/zinit.zsh 2>/dev/null; \
                    zinit light '${plugin_spec}'" 2>&1
            ;;
        oh-my-zsh)
            local plugin_dir="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/${pname}"
            if [ -d "$plugin_dir" ]; then
                echo "INFO: Plugin '$pname' already present."
                return 0
            fi
            git clone --depth=1 "https://github.com/${plugin_spec}.git" "$plugin_dir"
            ;;
        antigen)
            # Antigen needs to be run inside zsh
            zsh -c "source \${HOME}/.antigen/antigen.zsh; antigen bundle '${plugin_spec}'; antigen apply" 2>&1
            ;;
        *)
            echo "ERROR: Unsupported plugin manager: ${DOTFILES_PLUGIN_MANAGER}" >&2
            return 2
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo "WARNING: Failed to install plugin ${plugin_spec}. Continuing..." >&2
        return 1
    fi

    echo "INFO: Installed plugin $plugin_spec"
}

# install_all_plugins: reads plugins.txt and installs each plugin.
# Skips already-installed plugins and continues on failure.
# Usage: install_all_plugins
install_all_plugins() {
    local plugins_file="${DOTFILES_DIR}/plugins.txt"

    if [ ! -f "$plugins_file" ]; then
        echo "WARNING: No plugins.txt found at $plugins_file" >&2
        return 1
    fi

    local failed=0

    while IFS= read -r line; do
        # Strip carriage returns
        line="${line%$'\r'}"
        # Skip blank lines and comments
        case "$line" in ''|\#*) continue ;; esac

        install_plugin "$line" || ((failed++))
    done < "$plugins_file"

    if [ "$failed" -gt 0 ]; then
        echo "WARNING: $failed plugin(s) failed to install." >&2
        return 1
    fi

    return 0
}
