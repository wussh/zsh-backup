#!/usr/bin/env bash
# bin/lib/tracker.sh
# File Tracker — copies files into the Config_Store and records mappings.
# Requires DOTFILES_DIR to be set before sourcing.
# Depends on: sensitive.sh (is_sensitive, prompt_sensitive_confirm)

MANIFEST_FILE="${DOTFILES_DIR}/files/manifest.txt"

# get_store_path: maps a source path to its location under files/.
# Usage: get_store_path <source_path>
# Outputs the store-relative path (e.g. files/zsh/.zshrc)
get_store_path() {
    local source_path="$1"
    local user_home="${DOTFILES_TARGET_HOME:-$HOME}"

    # Resolve to absolute path
    source_path="$(realpath -m "$source_path")"

    # Strip target home prefix to get home-relative path
    local rel_path="${source_path#"$user_home"/}"

    # Map known dotfiles to category subdirectories
    local basename
    basename="$(basename "$source_path")"

    case "$rel_path" in
        .zshrc|.zprofile|.zshenv|.zsh_aliases|.zsh_functions) echo "files/zsh/$basename" ;;
        .gitconfig)   echo "files/git/$basename" ;;
        .vimrc)       echo "files/vim/$basename" ;;
        .config/nvim/*|.config/nvim) echo "files/nvim/$basename" ;;
        .tmux.conf)   echo "files/tmux/$basename" ;;
        .ssh/config)  echo "files/ssh/config" ;;
        *)            echo "files/${rel_path}" ;;
    esac
}

# is_tracked: checks if a source path is already recorded in manifest.txt.
# Returns 0 if tracked, 1 if not.
# Usage: is_tracked <source_path>
is_tracked() {
    local source_path="$1"
    source_path="$(realpath -m "$source_path")"
    local manifest="${DOTFILES_DIR}/files/manifest.txt"

    [ -f "$manifest" ] && grep -qF "$source_path" "$manifest"
}

# _manifest_update: update or append a mapping in manifest.txt
_manifest_update() {
    local store_rel="$1"
    local source_path="$2"
    local manifest="${DOTFILES_DIR}/files/manifest.txt"

    mkdir -p "$(dirname "$manifest")"
    touch "$manifest"

    if grep -qF "$source_path" "$manifest"; then
        # Update existing entry
        local tmp
        tmp="$(mktemp)"
        grep -vF "$source_path" "$manifest" > "$tmp" || true
        printf "%s\t%s\n" "$store_rel" "$source_path" >> "$tmp"
        mv "$tmp" "$manifest"
    else
        echo -e "${store_rel}\t${source_path}" >> "$manifest"
    fi
}

# track_file: copies a file to the store and records the mapping.
# Usage: track_file <source_path>
# Returns 0 on success, 1 on warning/skip, 2 on fatal error.
track_file() {
    local source_path="$1"

    # Resolve absolute path
    source_path="$(realpath -m "$source_path")"

    # Guard: source must exist
    if [ ! -e "$source_path" ]; then
        echo "WARNING: Skipping $source_path — file does not exist." >&2
        return 1
    fi

    # Guard: check sensitive patterns
    if is_sensitive "$source_path"; then
        if ! prompt_sensitive_confirm "$source_path"; then
            echo "INFO: Skipping $source_path — user declined." >&2
            return 1
        fi
    fi

    local store_rel
    store_rel="$(get_store_path "$source_path")"
    local store_abs="${DOTFILES_DIR}/${store_rel}"

    # Create parent directory in store
    mkdir -p "$(dirname "$store_abs")"

    # Copy file (overwrite if already tracked)
    if [ -d "$source_path" ]; then
        cp -r "$source_path" "$store_abs"
    else
        cp "$source_path" "$store_abs"
    fi

    # Record mapping
    _manifest_update "$store_rel" "$source_path"

    echo "INFO: Tracked $source_path → $store_rel"
    return 0
}

# untrack_file: removes a file from the store and manifest.
# Usage: untrack_file <source_path>
untrack_file() {
    local source_path="$1"
    source_path="$(realpath -m "$source_path")"

    local manifest="${DOTFILES_DIR}/files/manifest.txt"

    if [ ! -f "$manifest" ] || ! grep -qF "$source_path" "$manifest"; then
        echo "WARNING: $source_path is not tracked." >&2
        return 1
    fi

    local store_rel
    store_rel="$(grep -F "$source_path" "$manifest" | awk '{print $1}')"
    local store_abs="${DOTFILES_DIR}/${store_rel}"

    # Remove from store
    rm -rf "$store_abs"

    # Remove from manifest
    local tmp
    tmp="$(mktemp)"
    grep -vF "$source_path" "$manifest" > "$tmp" || true
    mv "$tmp" "$manifest"

    echo "INFO: Untracked $source_path"
    return 0
}
