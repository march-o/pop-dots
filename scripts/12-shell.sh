#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes"

SUDO="${SUDO:-sudo -n}"

if ! command -v zsh >/dev/null 2>&1; then
  log "zsh not available; skipping shell setup."
  exit 0
fi

ZSH_ROOT="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_TEMPLATE="$ZSH_ROOT/templates/zshrc.zsh-template"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_ROOT/custom}"
ZSH_THEME_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
ZSH_PLUGINS_DIR="$ZSH_CUSTOM/plugins"

if [[ ! -d "$ZSH_ROOT" ]]; then
  if command -v git >/dev/null 2>&1; then
    log "Installing oh-my-zsh into $ZSH_ROOT"
    git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_ROOT"
  else
    log "git not available; skipping oh-my-zsh install."
  fi
fi

if [[ -f "$ZSH_TEMPLATE" && ! -f "$HOME/.zshrc" ]]; then
  log "Creating ~/.zshrc from template"
  cp "$ZSH_TEMPLATE" "$HOME/.zshrc"
fi

if [[ ! -d "$ZSH_THEME_DIR" ]]; then
  if command -v git >/dev/null 2>&1; then
    log "Installing powerlevel10k theme"
    git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$ZSH_THEME_DIR"
  else
    log "git not available; skipping powerlevel10k install."
  fi
fi

install_plugin() {
  local name="$1"
  local repo="$2"
  local dst="$ZSH_PLUGINS_DIR/$name"

  if [[ ! -d "$dst" ]]; then
    if command -v git >/dev/null 2>&1; then
      log "Installing zsh plugin $name"
      git clone --depth 1 "$repo" "$dst"
    else
      log "git not available; skipping plugin $name."
    fi
  fi
}

mkdir -p "$ZSH_PLUGINS_DIR"
install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
install_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab.git"
install_plugin "zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete.git"

log "Skipping ~/.zshrc and ~/.bashrc edits (managed by chezmoi)."

ZSH_PATH="$(command -v zsh)"
if [[ -n "$ZSH_PATH" && "${SHELL:-}" != "$ZSH_PATH" ]]; then
  log "Setting default shell to $ZSH_PATH"
  if [[ "${NO_SUDO:-0}" -eq 0 ]]; then
    if ! $SUDO chsh -s "$ZSH_PATH" "$USER"; then
      log "Failed to set default shell via sudo chsh."
    fi
  else
    log "No-sudo mode: skipping chsh."
  fi
fi
