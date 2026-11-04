#!/usr/bin/env bash
# axora-power-apply.sh — apply the saved CPU power profile at login.
set -euo pipefail
STATE_FILE="$HOME/.config/axora/power-profile"
if [ -f "$STATE_FILE" ]; then
    profile=$(cat "$STATE_FILE")
    case "$profile" in
        performance|balanced|power-saver) ~/.local/bin/axora-power set "$profile" ;;
        *) echo "axora-power: ignoring unknown saved profile '$profile'" ;;
    esac
fi
exit 0
