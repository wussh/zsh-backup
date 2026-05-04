#!/usr/bin/env bash
# bin/lib/git.sh
# Git Operations — wraps git commands for Config_Store management.
# Requires DOTFILES_DIR to be set before sourcing.

# git_init: initializes a git repo in dir if one doesn't exist.
# Usage: git_init <dir>
git_init() {
    local dir="${1:-$DOTFILES_DIR}"

    if [ -d "${dir}/.git" ]; then
        echo "INFO: Git repo already initialized in $dir"
        return 0
    fi

    git -C "$dir" init
    echo "INFO: Initialized git repo in $dir"
}

# git_commit: stages all changes and creates a commit.
# Usage: git_commit <message>
git_commit() {
    local message="${1:-dotfiles backup: $(date '+%Y-%m-%d %H:%M:%S')}"

    git -C "$DOTFILES_DIR" add -A

    if git -C "$DOTFILES_DIR" diff --cached --quiet; then
        echo "INFO: Nothing to commit."
        return 0
    fi

    git -C "$DOTFILES_DIR" commit -m "$message"
}

# git_push: pushes to the configured remote and branch.
# Logs errors without discarding local commits.
# Usage: git_push [remote] [branch]
git_push() {
    local remote="${1:-origin}"
    local branch="${2:-${DOTFILES_BRANCH:-main}}"

    if ! git -C "$DOTFILES_DIR" push "$remote" "$branch"; then
        echo "ERROR: git push failed (exit code $?). Network error or authentication failure." >&2
        echo "Local commit has been preserved. Re-run 'dotfiles backup' when connectivity is restored." >&2
        return 2
    fi
}

# git_pull: pulls latest changes from remote.
# Usage: git_pull [remote] [branch]
git_pull() {
    local remote="${1:-origin}"
    local branch="${2:-${DOTFILES_BRANCH:-main}}"

    if ! git -C "$DOTFILES_DIR" pull "$remote" "$branch"; then
        echo "ERROR: git pull failed." >&2
        return 2
    fi
}

# git_clone: clones a remote repository to a local directory.
# Usage: git_clone <url> <dir>
git_clone() {
    local url="$1"
    local dir="$2"

    if [ -z "$url" ] || [ -z "$dir" ]; then
        echo "ERROR: git_clone requires url and dir arguments." >&2
        return 2
    fi

    git clone "$url" "$dir"
}

# git_set_remote: configures the remote URL.
# Usage: git_set_remote <url> [remote_name]
git_set_remote() {
    local url="$1"
    local remote="${2:-origin}"

    if git -C "$DOTFILES_DIR" remote get-url "$remote" &>/dev/null; then
        git -C "$DOTFILES_DIR" remote set-url "$remote" "$url"
    else
        git -C "$DOTFILES_DIR" remote add "$remote" "$url"
    fi

    echo "INFO: Remote '$remote' set to $url"
}

# git_status: returns porcelain status output.
# Usage: git_status
git_status() {
    git -C "$DOTFILES_DIR" status --porcelain
}
