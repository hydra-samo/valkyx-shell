#!/usr/bin/env bash
# Axora dotfiles installer — caelestia/serpentium style.
#
# Single source of truth lives in this repo. This script deploys repo files to
# their system locations. It never deletes anything on the host; existing files
# are backed up with a .axora-bak-<timestamp> suffix before being overwritten.
#
#   ./install.sh          # user part ($HOME) + asks for sudo for system parts
#   sudo ./install.sh     # ERROR: do not run as root (uses sudo internally)
#
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR: Do not run this script with sudo. Run it normally." >&2
  echo "The script uses sudo internally for system locations (/etc, /usr/share)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$SCRIPT_DIR"

info()  { printf '[axora-dotfiles] %s\n' "$*"; }
warn()  { printf '[axora-dotfiles] warn: %s\n' "$*" >&2; }

# Back up an existing file/dir/symlink before overwriting, so the host stays intact.
backup() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local ts
    ts="$(date +%Y%m%d%H%M%S)"
    mv "$target" "${target}.axora-bak-${ts}"
    info "backed up existing $target -> ${target}.axora-bak-${ts}"
  fi
}

need_sudo() {
  if [ "$EUID" -ne 0 ]; then
    warn "this step needs sudo (system location) — you'll be prompted"
    return 1
  fi
  return 0
}

# ============================================================
# 1. HOME dotfiles -> $HOME  (no sudo, portable via $HOME)
# ============================================================
info "deploying home dotfiles to $HOME"
shopt -s dotglob
for item in "$REPO/home"/*; do
  [ -e "$item" ] || continue
  name="$(basename "$item")"
  backup "$HOME/$name"
  cp -r "$item" "$HOME/$name"
done
shopt -u dotglob
info "home dotfiles deployed"

# ============================================================
# 2. SDDM theme -> /usr/share/sddm/themes/axora  (sudo)
# ============================================================
info "installing SDDM theme to /usr/share/sddm/themes/axora"
if need_sudo; then
  sudo mkdir -p /usr/share/sddm/themes/axora
  # clear previous install then copy fresh
  sudo rm -rf /usr/share/sddm/themes/axora
  sudo cp -r "$REPO/usr/share/sddm/themes/axora/." /usr/share/sddm/themes/axora/
  sudo find /usr/share/sddm/themes/axora -type d -exec chmod 755 {} +
  sudo find /usr/share/sddm/themes/axora -type f -exec chmod 644 {} +
  info "SDDM theme installed"
fi

# ============================================================
# 3. SDDM greeter config -> /etc/sddm.conf.d/axora.conf  (sudo)
# ============================================================
info "installing SDDM config to /etc/sddm.conf.d/axora.conf"
if need_sudo; then
  sudo mkdir -p /etc/sddm.conf.d
  backup_sudo() {
    if [ -e "/etc/sddm.conf.d/axora.conf" ] || [ -L "/etc/sddm.conf.d/axora.conf" ]; then
      local ts
      ts="$(date +%Y%m%d%H%M%S)"
      sudo mv "/etc/sddm.conf.d/axora.conf" "/etc/sddm.conf.d/axora.conf.axora-bak-${ts}"
    fi
  }
  backup_sudo
  sudo cp "$REPO/etc/sddm.conf.d/axora.conf" /etc/sddm.conf.d/axora.conf
  sudo chmod 644 /etc/sddm.conf.d/axora.conf
  info "SDDM config installed"
fi

# ============================================================
# 4. Done
# ============================================================
info "installation complete"
echo
echo "Next steps:"
echo "  - Restart Hyprland / log out and back in for shell changes to apply."
echo "  - For SDDM: select the 'Axora' greeter in sddm.conf.d, then restart sddm."

echo "  - The script did not delete anything on your host; overwritten files are"
echo "    saved with a .axora-bak-<timestamp> suffix."
