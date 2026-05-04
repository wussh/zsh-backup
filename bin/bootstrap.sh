#!/usr/bin/env bash
# bin/bootstrap.sh
# Bootstrap Script — self-contained environment setup.
# Run with: curl -fsSL <url> | bash
# Or:       bash bootstrap.sh [--profile <name>] [--remote <url>] [--no-chsh]
#
# Requirements: curl/wget, git, a supported package manager.
# This script is intentionally self-contained (no sourcing of lib files).

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
DOTFILES_REMOTE="${DOTFILES_REMOTE:-}"
DOTFILES_PROFILE="${DOTFILES_PROFILE:-default}"
DOTFILES_PLUGIN_MANAGER="${DOTFILES_PLUGIN_MANAGER:-zinit}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"
DO_CHSH=true

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --profile)  shift; DOTFILES_PROFILE="$1" ;;
        --remote)   shift; DOTFILES_REMOTE="$1" ;;
        --no-chsh)  DO_CHSH=false ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
log_info()    { echo "[INFO]    $*"; }
log_warning() { echo "[WARNING] $*" >&2; }
log_error()   { echo "[ERROR]   $*" >&2; }

# ---------------------------------------------------------------------------
# Step 1: Detect OS and package manager
# ---------------------------------------------------------------------------
log_info "Detecting package manager..."
PKG_MANAGER=""
if command -v brew &>/dev/null;    then PKG_MANAGER="brew"
elif command -v apt-get &>/dev/null; then PKG_MANAGER="apt-get"
elif command -v dnf &>/dev/null;   then PKG_MANAGER="dnf"
elif command -v yum &>/dev/null;   then PKG_MANAGER="yum"
elif command -v pacman &>/dev/null; then PKG_MANAGER="pacman"
elif command -v apk &>/dev/null;   then PKG_MANAGER="apk"
else
    log_error "No supported package manager found."
    log_error "Supported: brew, apt-get, yum/dnf, pacman, apk"
    log_error "Please install one of the above and re-run bootstrap."
    exit 2
fi
log_info "Using package manager: $PKG_MANAGER"

# Internal install helper
pkg_install() {
    local name="$1"
    case "$PKG_MANAGER" in
        brew)    brew install "$name" ;;
        apt-get) sudo apt-get install -y "$name" ;;
        dnf)     sudo dnf install -y "$name" ;;
        yum)     sudo yum install -y "$name" ;;
        pacman)  sudo pacman -S --noconfirm "$name" ;;
        apk)     sudo apk add --no-cache "$name" ;;
    esac
}

# ---------------------------------------------------------------------------
# Step 2: Install git if not present
# ---------------------------------------------------------------------------
if ! command -v git &>/dev/null; then
    log_info "Installing git..."
    pkg_install git
fi
log_info "git: $(git --version)"

# ---------------------------------------------------------------------------
# Step 3: Install zsh if not present
# ---------------------------------------------------------------------------
if ! command -v zsh &>/dev/null; then
    log_info "Installing zsh..."
    pkg_install zsh
fi
log_info "zsh: $(zsh --version)"

# ---------------------------------------------------------------------------
# Step 4: Clone the Config_Store
# ---------------------------------------------------------------------------
if [ -d "$DOTFILES_DIR/.git" ]; then
    log_info "Config_Store already exists at $DOTFILES_DIR — pulling latest..."
    git -C "$DOTFILES_DIR" pull origin "$DOTFILES_BRANCH" || \
        log_warning "git pull failed — using local state."
elif [ -n "$DOTFILES_REMOTE" ]; then
    log_info "Cloning Config_Store from $DOTFILES_REMOTE..."
    git clone "$DOTFILES_REMOTE" "$DOTFILES_DIR"
else
    log_info "No DOTFILES_REMOTE set — initializing empty Config_Store at $DOTFILES_DIR"
    mkdir -p "$DOTFILES_DIR"
    git -C "$DOTFILES_DIR" init
fi

# ---------------------------------------------------------------------------
# Step 5: Source config
# ---------------------------------------------------------------------------
CONF_FILE="${DOTFILES_DIR}/config/dotfiles.conf"
if [ -f "$CONF_FILE" ]; then
    # shellcheck source=/dev/null
    . "$CONF_FILE"
fi
# Re-apply any CLI overrides (they take precedence)
DOTFILES_PROFILE="${DOTFILES_PROFILE:-default}"
DOTFILES_PLUGIN_MANAGER="${DOTFILES_PLUGIN_MANAGER:-zinit}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

log_info "Active profile: $DOTFILES_PROFILE"

# ---------------------------------------------------------------------------
# Step 6: Install plugin manager
# ---------------------------------------------------------------------------
install_plugin_manager_zinit() {
    if [ -f "${HOME}/.local/share/zinit/zinit.git/zinit.zsh" ] || \
       [ -f "${HOME}/.zinit/bin/zinit.zsh" ]; then
        log_info "zinit is already installed."
        return 0
    fi
    log_info "Installing zinit..."
    bash -c "$(curl --fail --silent --show-error --location \
        https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)" || \
        log_warning "zinit installation may have partially failed."
}

install_plugin_manager_ohmyzsh() {
    if [ -d "${HOME}/.oh-my-zsh" ]; then
        log_info "Oh My Zsh is already installed."
        return 0
    fi
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl --fail --silent --show-error --location \
        https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_plugin_manager_antigen() {
    if [ -f "${HOME}/.antigen/antigen.zsh" ]; then
        log_info "antigen is already installed."
        return 0
    fi
    log_info "Installing antigen..."
    mkdir -p "${HOME}/.antigen"
    curl --fail --silent --show-error --location "https://git.io/antigen" \
        -o "${HOME}/.antigen/antigen.zsh"
}

case "$DOTFILES_PLUGIN_MANAGER" in
    zinit)     install_plugin_manager_zinit ;;
    oh-my-zsh) install_plugin_manager_ohmyzsh ;;
    antigen)   install_plugin_manager_antigen ;;
    *)
        log_warning "Unknown plugin manager: $DOTFILES_PLUGIN_MANAGER — skipping."
        ;;
esac

# ---------------------------------------------------------------------------
# Step 7: Install plugins from plugins.txt
# ---------------------------------------------------------------------------
PLUGINS_FILE="${DOTFILES_DIR}/plugins.txt"
INSTALLED_PLUGINS=()
FAILED_PLUGINS=()

if [ -f "$PLUGINS_FILE" ]; then
    log_info "Installing plugins from plugins.txt..."
    while IFS= read -r line; do
        line="${line%$'\r'}"
        case "$line" in ''|\#*) continue ;; esac

        pname="$(basename "$line")"

        case "$DOTFILES_PLUGIN_MANAGER" in
            zinit)
                # Clone directly under zinit plugins directory
                zinit_dir="${HOME}/.local/share/zinit/plugins"
                safe_name="${line//\//_}"
                if [ -d "${zinit_dir}/${safe_name}" ]; then
                    log_info "Plugin '$pname' already installed — skipping."
                    INSTALLED_PLUGINS+=("$pname")
                    continue
                fi
                ;;
            oh-my-zsh)
                plugin_dir="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/${pname}"
                if [ -d "$plugin_dir" ]; then
                    log_info "Plugin '$pname' already installed — skipping."
                    INSTALLED_PLUGINS+=("$pname")
                    continue
                fi
                git clone --depth=1 "https://github.com/${line}.git" "$plugin_dir" && \
                    INSTALLED_PLUGINS+=("$pname") || FAILED_PLUGINS+=("$pname")
                continue
                ;;
        esac

        # Fallback: try git clone into a local plugins dir
        plug_local_dir="${DOTFILES_DIR}/plugins/${pname}"
        if [ -d "$plug_local_dir" ]; then
            log_info "Plugin '$pname' already present locally — skipping."
            INSTALLED_PLUGINS+=("$pname")
        else
            mkdir -p "$(dirname "$plug_local_dir")"
            if git clone --depth=1 "https://github.com/${line}.git" "$plug_local_dir" 2>/dev/null; then
                INSTALLED_PLUGINS+=("$pname")
                log_info "Installed plugin: $pname"
            else
                log_warning "Failed to install plugin ${line}. Continuing..."
                FAILED_PLUGINS+=("$pname")
            fi
        fi
    done < "$PLUGINS_FILE"
else
    log_info "No plugins.txt found — skipping plugin installation."
fi

# ---------------------------------------------------------------------------
# Step 8: Install tools from tools.txt (filtered by profile)
# ---------------------------------------------------------------------------
TOOLS_FILE="${DOTFILES_DIR}/tools.txt"
INSTALLED_TOOLS=()
FAILED_TOOLS=()

# Get profile tools list (simple awk parse of profiles/<name>.yaml)
get_profile_tools_list() {
    local profile_file="${DOTFILES_DIR}/profiles/${DOTFILES_PROFILE}.yaml"
    [ -f "$profile_file" ] || return
    awk 'BEGIN{in_block=0} /^tools:/{in_block=1;next} /^[a-zA-Z]/{in_block=0} in_block && /^  - /{sub(/^  - /,"");print}' "$profile_file"
}

PROFILE_TOOLS=()
mapfile -t PROFILE_TOOLS < <(get_profile_tools_list)

if [ -f "$TOOLS_FILE" ]; then
    log_info "Installing tools from tools.txt..."
    while IFS= read -r line; do
        line="${line%$'\r'}"
        case "$line" in ''|\#*) continue ;; esac

        # Parse tool_name[:package_name]
        tool_cmd="${line%%:*}"
        tool_pkg="${line#*:}"
        [ "$tool_pkg" = "$line" ] && tool_pkg="$tool_cmd"

        # If profile tools list is non-empty, filter
        if [ "${#PROFILE_TOOLS[@]}" -gt 0 ]; then
            in_profile=false
            for pt in "${PROFILE_TOOLS[@]}"; do
                [ "$pt" = "$tool_cmd" ] && in_profile=true && break
            done
            if [ "$in_profile" = "false" ]; then
                continue
            fi
        fi

        if command -v "$tool_cmd" &>/dev/null; then
            log_info "Tool '$tool_cmd' is already installed — skipping."
            INSTALLED_TOOLS+=("$tool_cmd")
        else
            log_info "Installing tool: $tool_pkg..."
            if pkg_install "$tool_pkg"; then
                INSTALLED_TOOLS+=("$tool_cmd")
            else
                log_warning "Failed to install tool: $tool_pkg. Continuing..."
                FAILED_TOOLS+=("$tool_cmd")
            fi
        fi
    done < "$TOOLS_FILE"
else
    log_info "No tools.txt found — skipping tool installation."
fi

# ---------------------------------------------------------------------------
# Step 9: Restore symlinks for active profile
# ---------------------------------------------------------------------------
MANIFEST="${DOTFILES_DIR}/files/manifest.txt"
RESTORED_FILES=()

if [ -f "$MANIFEST" ]; then
    log_info "Restoring symlinks for profile: $DOTFILES_PROFILE..."

    # Get profile file list
    get_profile_files_list() {
        local pf="${DOTFILES_DIR}/profiles/${DOTFILES_PROFILE}.yaml"
        [ -f "$pf" ] || return
        awk 'BEGIN{in_block=0} /^files:/{in_block=1;next} /^[a-zA-Z]/{in_block=0} in_block && /^  - /{sub(/^  - /,"");print}' "$pf"
    }

    PROFILE_FILES=()
    mapfile -t PROFILE_FILES < <(get_profile_files_list)

    while IFS=$'\t' read -r store_rel source_path; do
        case "$store_rel" in ''|\#*) continue ;; esac

        # Filter by profile if profile has explicit file list
        if [ "${#PROFILE_FILES[@]}" -gt 0 ]; then
            in_pf=false
            for pf in "${PROFILE_FILES[@]}"; do
                if [ "$store_rel" = "$pf" ] || [ "files/$pf" = "$store_rel" ]; then
                    in_pf=true; break
                fi
            done
            [ "$in_pf" = "false" ] && continue
        fi

        store_abs="${DOTFILES_DIR}/${store_rel}"
        target_path="$(echo "$source_path" | sed "s|^/home/[^/]*/|${HOME}/|")"

        [ -e "$store_abs" ] || { log_warning "Store file missing: $store_abs — skipping."; continue; }

        # Check if already a correct symlink
        if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$store_abs" ]; then
            log_info "Symlink already up-to-date: $target_path"
            RESTORED_FILES+=("$target_path")
            continue
        fi

        mkdir -p "$(dirname "$target_path")"

        # Backup existing regular file
        if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
            ts="$(date +%Y%m%d_%H%M%S)"
            mv "$target_path" "${target_path}.bak.${ts}"
            log_info "Backed up $target_path → ${target_path}.bak.${ts}"
        fi

        [ -L "$target_path" ] && rm "$target_path"
        ln -s "$store_abs" "$target_path"
        log_info "Created symlink $target_path → $store_abs"
        RESTORED_FILES+=("$target_path")
    done < "$MANIFEST"
else
    log_info "No manifest found — skipping symlink restoration."
fi

# ---------------------------------------------------------------------------
# Step 10: Completion summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
echo "  Bootstrap Complete"
echo "============================================================"
echo ""
echo "Profile: $DOTFILES_PROFILE"
echo "Plugin Manager: $DOTFILES_PLUGIN_MANAGER"
echo ""

if [ "${#INSTALLED_TOOLS[@]}" -gt 0 ]; then
    echo "Installed tools:"
    printf '  - %s\n' "${INSTALLED_TOOLS[@]}"
fi
if [ "${#FAILED_TOOLS[@]}" -gt 0 ]; then
    echo "Failed tools:"
    printf '  - %s\n' "${FAILED_TOOLS[@]}"
fi
echo ""
if [ "${#INSTALLED_PLUGINS[@]}" -gt 0 ]; then
    echo "Installed plugins:"
    printf '  - %s\n' "${INSTALLED_PLUGINS[@]}"
fi
if [ "${#FAILED_PLUGINS[@]}" -gt 0 ]; then
    echo "Failed plugins:"
    printf '  - %s\n' "${FAILED_PLUGINS[@]}"
fi
echo ""
if [ "${#RESTORED_FILES[@]}" -gt 0 ]; then
    echo "Restored config files:"
    printf '  - %s\n' "${RESTORED_FILES[@]}"
fi
echo ""

# ---------------------------------------------------------------------------
# Step 11: Optionally set zsh as the default shell
# ---------------------------------------------------------------------------
if [ "$DO_CHSH" = "true" ] && command -v zsh &>/dev/null; then
    ZSH_PATH="$(command -v zsh)"
    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 2>/dev/null || echo "$SHELL")"
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        log_info "Setting zsh as default shell..."
        chsh -s "$ZSH_PATH" || log_warning "chsh failed — set your shell manually."
    else
        log_info "zsh is already the default shell."
    fi
fi

echo "Done! Restart your shell or run: exec zsh"
