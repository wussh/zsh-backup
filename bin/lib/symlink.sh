#!/usr/bin/env bash
# bin/lib/symlink.sh
# Symlink Manager — creates, updates, and validates symlinks from home to Config_Store.
# Requires DOTFILES_DIR to be set before sourcing.

# create_symlink: creates a symlink at target_path pointing to store_path.
# Backs up any existing regular file with .bak.<timestamp> before replacing.
# Usage: create_symlink <store_path> <target_path> [dry_run=false]
create_symlink() {
    local store_path="$1"
    local target_path="$2"
    local dry_run="${3:-false}"

    # Expand store_path to absolute if not already
    case "$store_path" in
        /*) : ;;
        *)  store_path="${DOTFILES_DIR}/${store_path}" ;;
    esac

    if [ "$dry_run" = "true" ]; then
        echo "[DRY-RUN] Would create symlink: $target_path → $store_path"
        return 0
    fi

    # Ensure parent directory exists
    mkdir -p "$(dirname "$target_path")"

    # Handle existing path
    if [ -L "$target_path" ]; then
        local current_target
        current_target="$(readlink "$target_path")"
        if [ "$current_target" = "$store_path" ]; then
            echo "INFO: Symlink already up-to-date: $target_path"
            return 0
        fi
        # Wrong symlink — remove it
        rm "$target_path"
    elif [ -e "$target_path" ]; then
        # Regular file — back it up
        local ts
        ts="$(date +%Y%m%d_%H%M%S)"
        local backup="${target_path}.bak.${ts}"
        mv "$target_path" "$backup"
        echo "INFO: Backed up existing file $target_path → $backup"
    fi

    ln -s "$store_path" "$target_path"
    echo "INFO: Created symlink $target_path → $store_path"
}

# validate_symlink: checks whether target_path is a symlink pointing to store_path.
# Returns 0 if valid, 1 otherwise.
# Usage: validate_symlink <target_path> <store_path>
validate_symlink() {
    local target_path="$1"
    local store_path="$2"

    case "$store_path" in
        /*) : ;;
        *)  store_path="${DOTFILES_DIR}/${store_path}" ;;
    esac

    if [ ! -L "$target_path" ]; then
        return 1
    fi

    local current_target
    current_target="$(readlink "$target_path")"
    [ "$current_target" = "$store_path" ]
}

# update_symlink: updates a symlink if its target has changed.
# Usage: update_symlink <store_path> <target_path> [dry_run=false]
update_symlink() {
    local store_path="$1"
    local target_path="$2"
    local dry_run="${3:-false}"

    case "$store_path" in
        /*) : ;;
        *)  store_path="${DOTFILES_DIR}/${store_path}" ;;
    esac

    if validate_symlink "$target_path" "$store_path"; then
        echo "INFO: Symlink already correct: $target_path"
        return 0
    fi

    if [ "$dry_run" = "true" ]; then
        echo "[DRY-RUN] Would update symlink: $target_path → $store_path"
        return 0
    fi

    [ -L "$target_path" ] && rm "$target_path"
    create_symlink "$store_path" "$target_path" "$dry_run"
}

# restore_all_symlinks: iterates over manifest and creates/updates symlinks.
# Usage: restore_all_symlinks <profile> [dry_run=false]
restore_all_symlinks() {
    local profile="${1:-default}"
    local dry_run="${2:-false}"

    local manifest="${DOTFILES_DIR}/files/manifest.txt"
    if [ ! -f "$manifest" ]; then
        echo "WARNING: No manifest found at $manifest" >&2
        return 1
    fi

    # Load profile files if profile module is available
    local profile_files=()
    if declare -f get_profile_files &>/dev/null; then
        mapfile -t profile_files < <(get_profile_files "$profile")
    fi

    local created=0 updated=0 skipped=0

    while IFS=$'\t' read -r store_rel source_path; do
        # Skip comments / blank
        case "$store_rel" in ''|\#*) continue ;; esac

        # If profile files specified, filter
        if [ "${#profile_files[@]}" -gt 0 ]; then
            local in_profile=false
            local pf
            for pf in "${profile_files[@]}"; do
                if [ "$store_rel" = "$pf" ] || [ "files/$pf" = "$store_rel" ]; then
                    in_profile=true
                    break
                fi
            done
            if [ "$in_profile" = "false" ]; then
                ((skipped++))
                continue
            fi
        fi

        # Normalize source_path: substitute $HOME prefix for portability
        local target_path="${source_path/#\/home\/*\///"$HOME"/}"
        # Simple substitution: replace home prefix
        target_path="$(echo "$source_path" | sed "s|^/home/[^/]*/|$HOME/|")"

        local store_abs="${DOTFILES_DIR}/${store_rel}"
        if [ ! -e "$store_abs" ]; then
            echo "WARNING: Store file missing: $store_abs — skipping." >&2
            ((skipped++))
            continue
        fi

        if validate_symlink "$target_path" "$store_abs"; then
            echo "INFO: Already linked: $target_path"
            ((skipped++))
        elif [ -L "$target_path" ]; then
            update_symlink "$store_abs" "$target_path" "$dry_run"
            ((updated++))
        else
            create_symlink "$store_abs" "$target_path" "$dry_run"
            ((created++))
        fi
    done < "$manifest"

    echo ""
    echo "Restore summary: created=$created  updated=$updated  skipped=$skipped"
}
