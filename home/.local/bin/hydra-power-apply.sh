#!/usr/bin/env bash
# valkyx-power-apply.sh — apply the saved CPU power profile at login.
set -euo pipefail
STATE_FILE="$HOME/.config/valkyx/power-profile"
if [ -f "$STATE_FILE" ]; then
    profile=$(cat "$STATE_FILE")
    case "$profile" in
        performance|balanced|power-saver) ~/.local/bin/valkyx-power set "$profile" ;;
        *) echo "valkyx-power: ignoring unknown saved profile '$profile'" ;;
    esac
fi
exit 0
