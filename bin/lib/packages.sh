#!/usr/bin/env bash
# bin/lib/packages.sh
# Package Installer — detects the system package manager and installs tools.

# detect_package_manager: sets PKG_MANAGER to the name of the available manager.
# Returns 0 on success, 2 if no supported manager found.
detect_package_manager() {
    if command -v brew &>/dev/null; then
        PKG_MANAGER="brew"
    elif command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt-get"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
    elif command -v apk &>/dev/null; then
        PKG_MANAGER="apk"
    else
        echo "ERROR: No supported package manager found." >&2
        echo "Supported: brew, apt-get, yum/dnf, pacman, apk" >&2
        echo "Please install one of the above and re-run bootstrap." >&2
        return 2
    fi
    export PKG_MANAGER
}

# is_package_installed: checks if a command exists via command -v.
# Usage: is_package_installed <name>
is_package_installed() {
    local name="$1"
    command -v "$name" &>/dev/null
}

# install_package: installs a package using the detected package manager.
# Usage: install_package <name>
install_package() {
    local name="$1"

    if [ -z "$PKG_MANAGER" ]; then
        detect_package_manager || return $?
    fi

    case "$PKG_MANAGER" in
        brew)
            brew install "$name"
            ;;
        apt-get)
            sudo apt-get install -y "$name"
            ;;
        dnf)
            sudo dnf install -y "$name"
            ;;
        yum)
            sudo yum install -y "$name"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$name"
            ;;
        apk)
            sudo apk add --no-cache "$name"
            ;;
        *)
            echo "ERROR: Unknown package manager: $PKG_MANAGER" >&2
            return 2
            ;;
    esac
}
