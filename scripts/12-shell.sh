#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

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

ensure_block() {
  local target="$1"
  local start_marker="$2"
  local end_marker="$3"
  local legacy_marker="$4"
  local content="$5"

  if [[ -f "$target" ]]; then
    if rg -q "$start_marker" "$target"; then
      log "Refreshing block in $target"
      awk -v start="$start_marker" -v end="$end_marker" -v body="$content" '
        $0 ~ start {print start; print body; print end; skip=1; next}
        $0 ~ end {skip=0; next}
        skip!=1 {print}
      ' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
    elif rg -q "$legacy_marker" "$target"; then
      log "Upgrading legacy block in $target"
      awk -v legacy="$legacy_marker" -v start="$start_marker" -v end="$end_marker" -v body="$content" '
        $0 ~ legacy {print start; print body; print end; skip=1; next}
        skip!=1 {print}
      ' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
    else
      log "Appending block to $target"
      {
        echo ""
        echo "$start_marker"
        echo "$content"
        echo "$end_marker"
      } >> "$target"
    fi
  fi
}

ZSH_EXTRAS_START="# pop-setup: zsh extras (start)"
ZSH_EXTRAS_END="# pop-setup: zsh extras (end)"
ZSH_EXTRAS_LEGACY="# pop-setup: zsh extras"
ZSH_EXTRAS_CONTENT='if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  alias bat=batcat
fi

if command -v rg >/dev/null 2>&1; then
  alias grep=rg
fi

if command -v fd >/dev/null 2>&1; then
  alias find=fd
fi


if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi'

BASH_EXTRAS_START="# pop-setup: bash extras (start)"
BASH_EXTRAS_END="# pop-setup: bash extras (end)"
BASH_EXTRAS_LEGACY="# pop-setup: bash extras"
BASH_EXTRAS_CONTENT='if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi

if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  alias bat=batcat
fi

if command -v rg >/dev/null 2>&1; then
  alias grep=rg
fi

if command -v fd >/dev/null 2>&1; then
  alias find=fd
fi


if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi
if [[ -f /usr/share/doc/fzf/examples/completion.bash ]]; then
  source /usr/share/doc/fzf/examples/completion.bash
fi'

ensure_block "$HOME/.zshrc" "$ZSH_EXTRAS_START" "$ZSH_EXTRAS_END" "$ZSH_EXTRAS_LEGACY" "$ZSH_EXTRAS_CONTENT"
ensure_block "$HOME/.bashrc" "$BASH_EXTRAS_START" "$BASH_EXTRAS_END" "$BASH_EXTRAS_LEGACY" "$BASH_EXTRAS_CONTENT"

ensure_zsh_plugins() {
  local target="$1"
  local desired_plugins="git fzf zoxide direnv zsh-autosuggestions zsh-syntax-highlighting fzf-tab"

  if [[ -f "$target" ]]; then
    if rg -q "^[[:space:]]*plugins=\\(" "$target"; then
      log "Ensuring oh-my-zsh plugins in $target"
      local current
      current="$(rg -m1 "^[[:space:]]*plugins=\\(" "$target")"
      local existing
      existing="$(echo "$current" | tr '()=' ' ' | tr -cs 'A-Za-z0-9_-' ' ' | xargs)"
      local merged=""
      local token
      for token in $existing; do
        if [[ "$token" != "plugins" ]]; then
          if ! echo " $merged " | grep -q " $token "; then
            merged="$merged $token"
          fi
        fi
      done
      for p in $desired_plugins; do
        if ! echo " $merged " | grep -q " $p "; then
          merged="$merged $p"
        fi
      done
      merged="$(echo "$merged" | xargs)"
      sed -E -i "s/^[[:space:]]*plugins=\\([^)]*\\)/plugins=($merged)/" "$target"
    fi
  fi
}

ensure_zsh_plugins "$HOME/.zshrc"

ensure_zsh_theme() {
  local target="$1"
  if [[ -f "$target" ]]; then
    if rg -q "^[[:space:]]*ZSH_THEME=" "$target"; then
      log "Setting ZSH_THEME to powerlevel10k"
      sed -E -i 's|^[[:space:]]*ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$target"
    fi
  fi
}

ensure_zsh_theme "$HOME/.zshrc"

ensure_p10k_source() {
  local target="$1"
  local line='[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh'
  if [[ -f "$target" ]]; then
    if ! rg -q "\\.p10k\\.zsh" "$target"; then
      log "Adding powerlevel10k config source to $target"
      echo "" >> "$target"
      echo "$line" >> "$target"
    fi
  fi
}

ensure_p10k_source "$HOME/.zshrc"

ZSH_PATH="$(command -v zsh)"
if [[ -n "$ZSH_PATH" && "${SHELL:-}" != "$ZSH_PATH" ]]; then
  log "Setting default shell to $ZSH_PATH"
  if [[ "${NO_SUDO:-0}" -eq 0 ]]; then
    if ! sudo chsh -s "$ZSH_PATH" "$USER"; then
      log "Failed to set default shell via sudo chsh."
    fi
  else
    log "No-sudo mode: skipping chsh."
  fi
fi
