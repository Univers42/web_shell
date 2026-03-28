#!/usr/bin/env bash
# ─────────────────────────────────────────────────
# Cloud Terminal — Shell Bootstrap
# Sourced automatically on session init
# ─────────────────────────────────────────────────

# ── History settings ──────────────────────────────
shopt -s histappend          # append instead of overwrite
shopt -s cmdhist             # multi-line cmds as one entry
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth       # no dupes, no leading spaces
export PROMPT_COMMAND="history -a; ${PROMPT_COMMAND:-}"

# ── Shell options ─────────────────────────────────
shopt -s checkwinsize        # update LINES/COLUMNS after each command
shopt -s globstar 2>/dev/null  # ** recursive glob (bash 4+)
shopt -s autocd 2>/dev/null    # type dir name to cd into it
shopt -s cdspell             # autocorrect minor cd typos

# ── Color support ─────────────────────────────────
export CLICOLOR=1
export TERM=xterm-256color

if command -v dircolors &>/dev/null; then
  eval "$(dircolors -b)"
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'

# ── Git prompt helper ─────────────────────────────
__git_branch() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    local dirty=""
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
      dirty="*"
    fi
    echo " ($branch$dirty)"
  fi
}

# ── Custom prompt ─────────────────────────────────
# Single-line prompt: red user@host, path, git branch
export PS1='\[\e[1;31m\]\u@inferno\[\e[0m\]:\[\e[1;33m\]\w\[\e[31m\]$(__git_branch)\[\e[0m\]\$ '

# ── Handy aliases ────────────────────────────────
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -pv'

# ── Welcome message ───────────────────────────────
echo -e "\033[1;31m"
echo "  ╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲"
echo -e "  \033[1;33m☠  INFERNO TERMINAL v2.0\033[1;31m"
echo "  ╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱"
echo -e "\033[0m"
