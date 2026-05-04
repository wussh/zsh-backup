#!/usr/bin/env bash
# tests/helpers/generators.bash
# Random input generator functions for property-based tests.
# Each test property runs a minimum of 100 iterations.

# PROPERTY_ITERATIONS: number of iterations per property test (default 100)
PROPERTY_ITERATIONS="${PROPERTY_ITERATIONS:-100}"

# gen_random_string: generates a random alphanumeric string of given length.
# Usage: gen_random_string [length]
gen_random_string() {
    local length="${1:-8}"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# gen_random_filename: generates a random dotfile-style filename.
# Usage: gen_random_filename
gen_random_filename() {
    local names=(".zshrc_test" ".zprofile_test" ".vimrc_test" ".gitconfig_test" ".tmux_test")
    local idx=$(( RANDOM % ${#names[@]} ))
    echo "${names[$idx]}_$(gen_random_string 4)"
}

# gen_random_content: generates random file content (multiple lines).
# Usage: gen_random_content [lines]
gen_random_content() {
    local lines="${1:-5}"
    for _ in $(seq 1 "$lines"); do
        gen_random_string 32
    done
}

# gen_sensitive_filename: generates a filename matching a sensitive pattern.
# Usage: gen_sensitive_filename
gen_sensitive_filename() {
    local patterns=(
        "id_rsa"
        "id_ed25519"
        "id_ecdsa"
        "server.pem"
        "private.key"
        "mypassword"
        "mysecret"
        "api_token"
        "mycredential"
        ".env"
        ".netrc"
        "keystore.p12"
        "cert.pfx"
    )
    local idx=$(( RANDOM % ${#patterns[@]} ))
    local base="${patterns[$idx]}"
    case "$base" in
        ".env"|".netrc")
            echo "$base"
            ;;
        id_rsa|id_ed25519|id_ecdsa|id_dsa|*.pem|*.key|*.p12|*.pfx)
            # Keep suffix-sensitive patterns at filename end.
            echo "$(gen_random_string 4)_${base}"
            ;;
        *)
            echo "${base}_$(gen_random_string 4)"
            ;;
    esac
}

# gen_safe_filename: generates a filename that does NOT match any sensitive pattern.
# Usage: gen_safe_filename
gen_safe_filename() {
    echo ".dotfile_safe_$(gen_random_string 8)"
}

# gen_random_profile: generates a random profile name (from existing profiles).
# Usage: gen_random_profile
gen_random_profile() {
    local profiles=("default" "server" "personal" "work")
    local idx=$(( RANDOM % ${#profiles[@]} ))
    echo "${profiles[$idx]}"
}

# run_property: runs a property test function N times.
# Usage: run_property <function_name> [iterations]
run_property() {
    local fn="$1"
    local iterations="${2:-$PROPERTY_ITERATIONS}"
    local failed=0

    for i in $(seq 1 "$iterations"); do
        if ! "$fn" "$i"; then
            echo "FAILED on iteration $i" >&2
            ((failed++))
        fi
    done

    if [ "$failed" -gt 0 ]; then
        echo "$failed/$iterations iterations failed." >&2
        return 1
    fi

    echo "All $iterations iterations passed."
    return 0
}
