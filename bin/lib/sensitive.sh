#!/usr/bin/env bash
# bin/lib/sensitive.sh
# Sensitive File Filter — prevents accidental tracking of secret files.
# Requires DOTFILES_DIR to be set before sourcing.

# Global array of exclusion patterns (populated by load_exclusions)
EXCLUSION_PATTERNS=()

# Default exclusion patterns (used if exclusions.txt is missing)
_DEFAULT_EXCLUSION_PATTERNS=(
    "*_rsa"
    "*_ed25519"
    "*_ecdsa"
    "*_dsa"
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    "*password*"
    "*secret*"
    "*token*"
    "*credential*"
    "*.env"
    ".netrc"
)

# load_exclusions: reads patterns from config/exclusions.txt into EXCLUSION_PATTERNS.
# Falls back to _DEFAULT_EXCLUSION_PATTERNS if the file doesn't exist.
load_exclusions() {
    EXCLUSION_PATTERNS=()
    local exclusions_file="${DOTFILES_DIR}/config/exclusions.txt"

    if [ ! -f "$exclusions_file" ]; then
        EXCLUSION_PATTERNS=("${_DEFAULT_EXCLUSION_PATTERNS[@]}")
        return 0
    fi

    while IFS= read -r line; do
        # Strip carriage returns (handle Windows-style CRLF line endings)
        line="${line%$'\r'}"
        # Skip blank lines and comments
        case "$line" in
            ''|\#*) continue ;;
        esac
        EXCLUSION_PATTERNS+=("$line")
    done < "$exclusions_file"

    # If file was empty or only comments, use defaults
    if [ "${#EXCLUSION_PATTERNS[@]}" -eq 0 ]; then
        EXCLUSION_PATTERNS=("${_DEFAULT_EXCLUSION_PATTERNS[@]}")
    fi
}

# is_sensitive: checks if a path matches any exclusion pattern.
# Matches against the basename of the path.
# Returns 0 (true) if sensitive, 1 (false) if safe.
# Usage: is_sensitive <path>
is_sensitive() {
    local path="$1"
    local basename
    basename="$(basename "$path")"

    # Ensure patterns are loaded
    if [ "${#EXCLUSION_PATTERNS[@]}" -eq 0 ]; then
        load_exclusions
    fi

    local pattern
    for pattern in "${EXCLUSION_PATTERNS[@]}"; do
        # Use case statement for glob matching (POSIX-compatible)
        case "$basename" in
            $pattern) return 0 ;;
        esac
    done

    return 1
}

# prompt_sensitive_confirm: warns user and asks for confirmation.
# Returns 0 if user confirms (y/Y), 1 otherwise.
# Usage: prompt_sensitive_confirm <path>
prompt_sensitive_confirm() {
    local path="$1"
    local basename
    basename="$(basename "$path")"

    # Find which pattern matched
    local matched_pattern=""
    local pattern
    for pattern in "${EXCLUSION_PATTERNS[@]}"; do
        case "$basename" in
            $pattern)
                matched_pattern="$pattern"
                break
                ;;
        esac
    done

    echo "WARNING: $path matches sensitive pattern '${matched_pattern:-sensitive}'." >&2
    printf "Are you sure you want to track this file? [y/N]: " >&2

    local answer
    read -r answer

    case "$answer" in
        [yY]) return 0 ;;
        *)    return 1 ;;
    esac
}

# add_user_exclusion: appends a pattern to config/exclusions.txt.
# Does not add duplicate patterns.
# Usage: add_user_exclusion <pattern>
add_user_exclusion() {
    local pattern="$1"
    local exclusions_file="${DOTFILES_DIR}/config/exclusions.txt"

    if [ -z "$pattern" ]; then
        echo "ERROR: add_user_exclusion requires a pattern argument" >&2
        return 1
    fi

    mkdir -p "$(dirname "$exclusions_file")"

    # Check for duplicate
    if [ -f "$exclusions_file" ] && grep -qxF "$pattern" "$exclusions_file"; then
        return 0
    fi

    # Append to file
    echo "$pattern" >> "$exclusions_file"

    # Reload patterns
    load_exclusions
}
