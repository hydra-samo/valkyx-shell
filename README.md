# Valkyx — Hyprland Dotfiles

Single source of truth for the Valkyx Hyprland shell, in the style of
[ilyamiro/serpentium](https://github.com/ilyamiro/serpentium) and
[caelestia](https://github.com/ilyamiro/caelestia). The repo is maintained;
the install script deploys it to any machine (this host or the `machy` VM).
Nothing on the host is deleted — overwritten files are backed up with a
`.valkyx-bak-<timestamp>` suffix.

## Layout (mirrors install targets)

| Repo path | Installs to |
|-----------|-------------|
| `home/.config/hypr/` | `$HOME/.config/hypr/` |
| `home/.config/valkyx/` | `$HOME/.config/valkyx/` |
| `home/.local/bin/` | `$HOME/.local/bin/` |
| `home/.local/share/` | `$HOME/.local/share/` |
| `home/Pictures/Wallpapers/` | `$HOME/Pictures/Wallpapers/` |
| `home/.bashrc .zshrc .profile` | `$HOME/` |
| `etc/sddm.conf.d/valkyx.conf` | `/etc/sddm.conf.d/valkyx.conf` (sudo) |
| `usr/share/sddm/themes/valkyx/` | `/usr/share/sddm/themes/valkyx/` (sudo) |

## Install

### Option 1 — Dotfiles deploy only (this host / machy VM)
```bash
./install.sh
```
Run as a normal user. Deploys dotfiles to `$HOME` and `/etc`/`/usr/share` (via
`sudo` internally). Backs up existing files with `.valkyx-bak-<timestamp>`.

### Option 2 — Full machine preparation (bare Arch → Valkyx shell)
```bash
sudo ./install-machine.sh
```
Run as root. Prompts for the root password ONCE, then everything is
auto-approved. Detects installed vs missing packages, installs what's needed,
creates the user, enables services, installs fonts, deploys dotfiles, and
configures SDDM. Idempotent — safe to re-run.

## Privacy & security

The repo contains **only brand and config data — no personal data**.

| Excluded | Reason |
|----------|--------|
| `avatar-circle.png` | Your personal profile photo — replaced with `avatar-placeholder.svg` |
| `valkyx-wallpaper.png` | Your personal wallpaper — replaced with `valkyx-wallpaper.svg` placeholder |
| `state.json`, `state.dev.json` | Personal usage state (greetOnce, fontScale, etc.) |
| `power-profile` | Your saved CPU power profile |
| `remote.json` | Personal remote connection config |
| `.env*`, `*secret*`, `*token*`, `*credential*` | Secrets and API keys — never committed |
| `valkyx-assistant`, `valkyx-automata` | Kept on the host, not in this repo |

### Avatar (Super+I settings panel / greetings)

The settings panel avatar falls back to `avatar-placeholder.svg` if you don't
provide your own. To use your profile picture:

```bash
cp your-photo.png ~/.config/valkyx/avatar-circle.png
```

### Wallpaper

The lock screen and shell fall back to `valkyx-wallpaper.svg` placeholder.
To use your own wallpaper:

```bash
cp your-wallpaper.png ~/.local/share/backgrounds/valkyx-wallpaper.png
```

## What's excluded

- `valkyx-assistant` and `valkyx-automata` — kept on the host, not in this repo
- Giant AppImage/binaries in `$HOME/.local/bin` (e.g. `valkyx.AppImage`, `llama`,
  `LM-Studio`) — not part of the shell config; install separately if needed
- TTS model binaries (`.piper`) — kept on the host; `valkyx-assistant` needs them
- systemd unit files — not part of the portable dotfiles deploy
- Personal data (see Privacy & security above)

## Notes

- All paths use `$HOME` — nothing is hardcoded to `/home/valkyxsamo`, so it works
  on any user/machine (including root on `machy`, after adjusting `$HOME`).
- Shell rc files (`.bashrc`, `.zshrc`, `.profile`) have `/home/valkyxsamo`
  replaced with `$HOME` for portability.
- QML files use `StandardPaths.writableLocation(StandardPaths.HomeLocation)`
  instead of hardcoded paths.
- `usr/share/sddm/themes/valkyx/` and `/etc/sddm.conf.d/` require `sudo`.
