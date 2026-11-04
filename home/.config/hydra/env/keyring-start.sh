#!/usr/bin/env bash
# Start gnome-keyring and publish its sockets into the systemd user manager so
# GUI apps launched later (and NetworkManager agents) can actually find it.
# Not wired into PAM on this box, which is why the keyring kept "not working".
set -u
eval "$(gnome-keyring-daemon --start --components=secrets,ssh 2>/dev/null)"
if [ -n "${GNOME_KEYRING_CONTROL:-}" ]; then
  systemctl --user import-environment GNOME_KEYRING_CONTROL SSH_AUTH_SOCK
  mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"
  printf 'GNOME_KEYRING_CONTROL=%s\n' "$GNOME_KEYRING_CONTROL" \
    > "${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/gnome-keyring.conf"
  [ -n "${SSH_AUTH_SOCK:-}" ] && \
    printf 'SSH_AUTH_SOCK=%s\n' "$SSH_AUTH_SOCK" \
    >> "${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/gnome-keyring.conf"
  chmod 600 "${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/gnome-keyring.conf"
fi
