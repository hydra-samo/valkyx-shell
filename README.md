# Hydra Samo Labs — Hyprland Dotfiles

Single source of truth for the Hydra Hyprland shell, in the style of
[ilyamiro/serpentium](https://github.com/ilyamiro/serpentium) and
[caelestia](https://github.com/ilyamiro/caelestia). The repo is maintained;
the install script deploys it to any machine (this host or the `machy` VM).
Nothing on the host is deleted — overwritten files are backed up with a
`.hydra-bak-<timestamp>` suffix.

## Layout (mirrors install targets)

| Repo path | Installs to |
|-----------|-------------|
| `home/.config/hypr/` | `$HOME/.config/hypr/` |
| `home/.config/hydra/` | `$HOME/.config/hydra/` |
| `home/.local/bin/` | `$HOME/.local/bin/` |
| `home/.local/share/` | `$HOME/.local/share/` |
| `home/Pictures/Wallpapers/` | `$HOME/Pictures/Wallpapers/` |
| `home/.bashrc .zshrc .profile` | `$HOME/` |
| `etc/sddm.conf.d/hydra.conf` | `/etc/sddm.conf.d/hydra.conf` (sudo) |
| `usr/share/sddm/themes/hydra/` | `/usr/share/sddm/themes/hydra/` (sudo) |

## Install

```bash
./install.sh
```

Run as a normal user — the script uses `sudo` internally for `/etc` and
`/usr/share` locations. It does **not** run as root.

## What's excluded

- `hydra-assistant` and `hydra-automata` — kept on the host, not in this repo
- Giant AppImage/binaries in `$HOME/.local/bin` (e.g. `hydra.AppImage`, `llama`,
  `LM-Studio`) — not part of the shell config; install separately if needed
- TTS model binaries (`.piper`) — kept on the host; `hydra-assistant` needs them
- systemd unit files — not part of the portable dotfiles deploy

## Notes

- All paths use `$HOME` — nothing is hardcoded to `/home/hydrasamo`, so it works
  on any user/machine (including root on `machy`, after adjusting `$HOME`).
- Shell rc files (`.bashrc`, `.zshrc`, `.profile`) have `/home/hydrasamo`
  replaced with `$HOME` for portability.
- `usr/share/sddm/themes/hydra/` and `/etc/sddm.conf.d/` require `sudo`.
