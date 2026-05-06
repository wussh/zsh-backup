# ============================================================
# Section 1: Powerlevel10k Instant Prompt (MUST BE AT TOP)
# ============================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# Section 2: Oh-My-Zsh Configuration
# ============================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Empty - using powerlevel10k loaded later

# Uncomment to disable auto-update
# zstyle ':omz:update' mode disabled

plugins=(git)

source $ZSH/oh-my-zsh.sh

# ============================================================
# Section 3: Plugin Configuration (Order is Critical!)
# ============================================================
# Load autosuggestions first (doesn't depend on completion)
source /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Load autocomplete after oh-my-zsh initializes completion
source /home/linuxbrew/.linuxbrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# ============================================================
# Starship Prompt (replaced by fzf in Section 6 after PATH is configured)
# Starship init moved to Section 6 after brew shellenv

# ============================================================
# Section 4: Theme Configuration
# ============================================================
# source /home/linuxbrew/.linuxbrew/share/powerlevel10k/powerlevel10k.zsh-theme  # Disabled - using Starship instead
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh  # Disabled - using Starship instead

# ============================================================
# Section 5: PATH Configuration
# ============================================================
# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Starship Prompt (needs brew shellenv first)
eval "$(starship init zsh)"

# System paths
export PATH=$PATH:/snap/bin
export PATH=$PATH:/usr/bin

# Go
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Local bin
export PATH="/home/wush/.local/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Zoxide (cd replacement) - MOVED TO SECTION 6

# ============================================================
# Section 6: Tool Initialization
# ============================================================
# Conda
# >>> conda initialize >>>
__conda_setup="$('/home/wush/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/wush/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/wush/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/wush/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Bun completions
[ -s "/home/wush/.bun/_bun" ] && source "/home/wush/.bun/_bun"

# Atuin (enhanced history)
eval "$(atuin init zsh)"

# Yazi (file manager) completions
# eval "$(yazi --completion zsh)"

# FZF (fuzzy finder) keybindings and completions
eval "$(fzf --zsh)"

# Zoxide (cd replacement)
eval "$(zoxide init zsh)"

# ============================================================
# Section 7: Aliases and Functions
# ============================================================
# Add your custom aliases here

# eza (modern ls replacement)
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'

# bat (modern cat replacement)
alias cat='bat --style=auto'

# ripgrep
alias grep='rg'

# lazygit
alias lg='lazygit'

# Supervisorctl monitoring & Diff checker
unalias sup 2>/dev/null
sup() {
  if [ "$1" = "diff" ]; then
    /home/wush/bri/script/diff-checker/main.py "${@:2}"
  else
    /home/wush/bri/script/supervisorctl/monitor_supervisorctl.py "$@"
  fi
}

# Bamboo scan alias
alias scan='/home/wush/bri/script/bamboo-scan.sh'

# Bamboo Simulator (uv isolated env — auto-installs PyYAML)
export BAMBOO_SIM_DIR="/home/wush/bri/script/bamboo-simulator"
alias bamboo-sim='uv run --project "$BAMBOO_SIM_DIR" "$BAMBOO_SIM_DIR/bamboo_simulator.py"'

# ============================================================
# Section 8: Local Configuration (Sensitive Data)
# ============================================================
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# opencode
export PATH=/home/wush/.opencode/bin:$PATH
