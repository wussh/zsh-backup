#!/usr/bin/env bash
# bin/lib/profile.sh
# Profile Manager — reads YAML-like profile manifests using awk/sed.
# Requires DOTFILES_DIR to be set before sourcing.

# load_profile: parse a profile YAML and print its raw content.
# Usage: load_profile <name>
load_profile() {
    local name="$1"
    local profile_file="${DOTFILES_DIR}/profiles/${name}.yaml"

    if [ ! -f "$profile_file" ]; then
        echo "WARNING: Profile '$name' not found at $profile_file" >&2
        return 1
    fi

    cat "$profile_file"
}

# _parse_yaml_list: extract list items under a given YAML key.
# Usage: _parse_yaml_list <file> <key>
_parse_yaml_list() {
    local file="$1"
    local key="$2"

    awk -v key="$key" '
        BEGIN { in_block=0 }
        /^[a-zA-Z]/ { in_block=0 }
        $0 ~ "^"key":" { in_block=1; next }
        in_block && /^  - / {
            sub(/^  - /, "")
            print
        }
    ' "$file"
}

# _parse_yaml_value: extract a scalar value for a given YAML key.
# Usage: _parse_yaml_value <file> <key>
_parse_yaml_value() {
    local file="$1"
    local key="$2"

    grep "^${key}:" "$file" | head -1 | sed "s/^${key}:[[:space:]]*//"
}

# _resolve_inheritance: merge parent profile (extends) recursively.
# Usage: _resolve_inheritance <name> <section>
_resolve_inheritance() {
    local name="$1"
    local section="$2"
    local profile_file="${DOTFILES_DIR}/profiles/${name}.yaml"

    [ -f "$profile_file" ] || return 1

    local parent
    parent="$(_parse_yaml_value "$profile_file" "extends")"

    # Output parent's items first (so child can override)
    if [ -n "$parent" ] && [ "$parent" != "null" ] && [ "$parent" != "$name" ]; then
        _resolve_inheritance "$parent" "$section"
    fi

    _parse_yaml_list "$profile_file" "$section"
}

# resolve_profile_inheritance: merge a profile with its parent.
# Outputs the merged list of files or tools for the given section.
# Usage: resolve_profile_inheritance <name> <section: files|tools>
resolve_profile_inheritance() {
    local name="$1"
    local section="${2:-files}"

    _resolve_inheritance "$name" "$section" | sort -u
}

# get_profile_files: returns the list of store-relative file paths for a profile.
# Usage: get_profile_files <name>
get_profile_files() {
    local name="$1"
    resolve_profile_inheritance "$name" "files"
}

# get_profile_tools: returns the list of tools declared in a profile.
# Usage: get_profile_tools <name>
get_profile_tools() {
    local name="$1"
    resolve_profile_inheritance "$name" "tools"
}

# list_profiles: lists all .yaml files in the profiles/ directory.
# Usage: list_profiles
list_profiles() {
    local profiles_dir="${DOTFILES_DIR}/profiles"
    if [ ! -d "$profiles_dir" ]; then
        echo "WARNING: No profiles directory found." >&2
        return 1
    fi

    for f in "$profiles_dir"/*.yaml; do
        [ -f "$f" ] || continue
        basename "$f" .yaml
    done
}
