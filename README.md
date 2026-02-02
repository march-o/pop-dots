# pop-setup

Bootstrap a Pop!_OS (Ubuntu-based) machine with one command.

## Quick start

```bash
git clone <repo>
cd pop-setup
./bootstrap.sh
./bootstrap.sh --no-sudo
```

```bash
# Use a remote repo directly (no local clone needed)
curl -fsSL <raw bootstrap.sh url> | bash -s -- <repo-url>
```

```bash
# Use a local path explicitly
./bootstrap.sh /path/to/local/repo
```

## Customize

- Package lists: `packages/apt.txt` and `packages/flatpak.txt`
- GNOME settings: `system/gsettings.sh`
- Optional dconf: create `system/gnome.dconf` (non-empty files are applied by default)
- Dotfiles live in `dotfiles/` (see `dotfiles/README.md`)

Notes:
- GNOME settings use `gsettings`. COSMIC uses its own config; `system/gsettings.sh` handles both.

## Safety

Do not store secrets in this repo. Use 1Password/Bitwarden or chezmoi templates for secrets and placeholders.
