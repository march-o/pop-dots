# Codex Agent Notes (pop-setup)

## Purpose

Bootstrap a Pop!_OS (Ubuntu-based) machine with one entrypoint and an idempotent, maintainable structure. Uses chezmoi for dotfiles + templates and separates packages/GNOME/COSMIC settings into scripts.

## Environment

- Target OS/DE: Pop!_OS on COSMIC.
- Default shell: zsh (installed + set via scripts).

## Entrypoint

- `./bootstrap.sh [--no-sudo] [<repo-or-local-path>]`
  - Default repo/path: the directory containing `bootstrap.sh`.
  - Local path => `chezmoi init --apply --source <path>`.
  - Remote URL => `chezmoi init --apply <repo>`.
  - Runs scripts in order from the repo source directory.
  - `--no-sudo` skips all sudo/apt changes but still applies chezmoi + UI settings.

## Repo Layout

- `bootstrap.sh` — installs prerequisites, installs chezmoi, initializes repo, runs scripts in order.
- `packages/apt.txt` — apt packages, one per line.
- `packages/flatpak.txt` — Flatpak IDs, one per line; allow comments with `#`.
- `scripts/00-core.sh` — apt update, install apt packages, ensure flatpak + flathub.
- `scripts/10-dev.sh` — docker + compose, docker group, git defaults (only if no ~/.gitconfig).
- `scripts/15-node.sh` — nvm install, Node LTS, Codex CLI.
- `scripts/20-ui.sh` — GNOME/COSMIC settings + optional dconf + flatpaks.
- `scripts/90-cleanup.sh` — apt autoremove + reminder about docker group.
- `system/gsettings.sh` — GNOME gsettings + COSMIC touchpad config.
- `system/gnome.dconf` — optional dconf dump (applied if file is non-empty).
- `dotfiles/README.md` — explains chezmoi dotfile layout and apply.

## Settings behavior

- GNOME settings use `gsettings`.
- COSMIC uses its own config file; `system/gsettings.sh` writes `~/.config/cosmic/com.system76.CosmicComp/v1/input_touchpad` with `natural_scroll:Some(true)` when on COSMIC.
- dconf load is **default-on** when `system/gnome.dconf` is non-empty.

## Idempotency rules

- Scripts use `apt-get install -y` and `flatpak install -y` which are safe to re-run.
- `10-dev.sh` only sets git defaults if `~/.gitconfig` does not exist.
- Docker group add only if user isn’t already in group.

## No secrets

- Never store secrets in this repo. Use chezmoi templates and external secret managers.
- `.gitignore` covers common secret patterns.

## Adding new stuff

- Add apt packages to `packages/apt.txt` (one per line).
- Add Flatpaks to `packages/flatpak.txt` (one per line).
- Add npm globals to `packages/npm.txt` (one per line).
- Add new scripts in `scripts/` and run them from `bootstrap.sh` in desired order.
- Make new scripts executable (`chmod +x scripts/<name>.sh`).
- When adding shell init snippets, update both `~/.zshrc` and `~/.bashrc` (zsh is default but bash may still be used).
- When editing shell config with `sed`, avoid `/` delimiters if the replacement contains `/`; use `|` or escape carefully. When updating block inserts, use start/end markers to avoid duplicate blocks.
- Extend `system/gsettings.sh` for GNOME/COSMIC settings changes.
- Add dotfiles under `dotfiles/` using chezmoi naming conventions.

## Package list guidance

When you ask me to add a package (or I need to add one), use these rules for this repo’s lists:
- Use `packages/apt.txt` for CLI tools, dev libraries, system services, and OS‑integrated components.
- Use `packages/flatpak.txt` for GUI/desktop apps where sandboxing and newer app versions are preferred.

## Testing

- Run `./bootstrap.sh --no-sudo` to validate non-root flow.
- Run `./bootstrap.sh` for full system changes (needs sudo).

## Codex execution note

- When you ask me to run the main script, I should use `./bootstrap.sh --no-sudo` by default because sudo prompts are not available in this environment.
- Chezmoi applies should be non-interactive and prefer repo defaults; use `chezmoi apply --force` so local changes are overwritten without prompts.
