# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Bootstrap a Pop!_OS (Ubuntu-based) machine with one entrypoint and an idempotent, maintainable structure. Uses chezmoi for dotfiles and separates packages, GNOME/COSMIC settings into modular scripts.

## Running / Testing

```bash
./bootstrap.sh --no-sudo          # Validate non-root flow (no sudo/apt changes; still applies dotfiles + UI)
./bootstrap.sh                    # Full system changes (requires sudo cached via sudo -v)
./bootstrap.sh /path/to/local     # Use explicit local repo path
curl -fsSL <url> | bash -s -- <repo-url>  # Bootstrap from remote
```

- Local path → `chezmoi init --apply --source <path>`
- Remote URL → `chezmoi init --apply <repo>`

All scripts must be non-interactive. Use `sudo -n` and fail fast if credentials aren't cached. Default to `--no-sudo` when sudo prompts are unavailable.

## Architecture

**Entrypoint:** `bootstrap.sh` — installs prerequisites (chezmoi), applies dotfiles, then runs `scripts/` in numbered order.

**Execution order:**
- `scripts/00-core.sh` — apt update + install from `packages/apt.txt`, flatpak + flathub
- `scripts/10-dev.sh` — Docker + compose, docker group, git defaults (skipped if `~/.gitconfig` exists)
- `scripts/12-shell.sh` — Oh-My-Zsh, Powerlevel10k, zsh plugins (does NOT edit shell rc files)
- `scripts/13-kitty.sh` — Kitty terminal via official binary installer
- `scripts/14-python.sh` — uv Python manager, pipx packages from `packages/pipx.txt`
- `scripts/15-node.sh` — nvm, Node LTS, npm globals from `packages/npm.txt`
- `scripts/20-ui.sh` — GNOME/COSMIC settings, dconf, flatpak apps from `packages/flatpak.txt`
- `scripts/25-keyd.sh` — keyd install + config (always runs; targets internal keyboard only via `0001:0001`)
- `scripts/90-cleanup.sh` — apt autoremove + docker group reminder

**Shell config** is managed exclusively by chezmoi. Edit `dotfiles/dot_zshrc` / `dotfiles/dot_bashrc` instead of `~/.zshrc` / `~/.bashrc`.

**GNOME/COSMIC settings** live in `system/gsettings.sh`. GNOME uses `gsettings`; COSMIC writes `~/.config/cosmic/com.system76.CosmicComp/v1/input_touchpad` directly. dconf is applied automatically when `system/gnome.dconf` is non-empty.

## Adding New Stuff

- **APT packages** → `packages/apt.txt` (CLI tools, dev libs, system services, OS-integrated)
- **Flatpak apps** → `packages/flatpak.txt` (GUI apps where sandboxing/newer versions preferred)
- **npm globals** → `packages/npm.txt`
- **pipx tools** → `packages/pipx.txt`
- **New scripts** → add to `scripts/`, make executable (`chmod +x`), wire into `bootstrap.sh`
- **GNOME/COSMIC settings** → extend `system/gsettings.sh`
- **Dotfiles** → add under `dotfiles/` using chezmoi naming conventions (`dot_` prefix)

When editing shell config with `sed`, avoid `/` delimiters if the replacement contains `/`; use `|` instead. Use start/end markers for block inserts to avoid duplicates on re-runs.

## Idempotency

Scripts are designed to be safely re-run:
- `apt-get install -y` and `flatpak install -y` are safe to re-run
- Git defaults only applied if `~/.gitconfig` does not exist
- Docker group add only if user is not already a member
- Plugin/theme installs check for existing directories before cloning
- Chezmoi uses `--force` to overwrite local changes without prompts

## No Secrets

Never store secrets in this repo. Use chezmoi templates and external secret managers (1Password, Bitwarden). `.gitignore` covers common secret patterns.
