#!/usr/bin/env bash
# hydra-power-apply.sh — apply the saved CPU power profile at login.
set -euo pipefail
STATE_FILE="$HOME/.config/hydra/power-profile"
if [ -f "$STATE_FILE" ]; then
    profile=$(cat "$STATE_FILE")
    case "$profile" in
        performance|balanced|power-saver) ~/.local/bin/hydra-power set "$profile" ;;
        *) echo "hydra-power: ignoring unknown saved profile '$profile'" ;;
    esac
fi
exit 0
