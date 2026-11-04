#!/usr/bin/env bash
#
# valkyx-gpu-ppwatch — watch power-profiles-daemon for profile changes and
# keep the NVIDIA on-demand policy intact. Logs to the user journal.
#
set -u

PROFILE_IFACE="net.hadess.PowerProfiles"

_log() {
    echo "[valkyx-gpu] $*"
}

apply_profile() {
    local profile saved
    profile=$(powerprofilesctl get 2>/dev/null || echo "unknown")
    _log "power profile changed -> ${profile}"
    # If power-profiles-daemon (or a UI widget) changed the profile and
    # overwrote our EPP/governor, re-apply the profile we actually saved so
    # valkyx-power remains authoritative.
    saved=$(cat "$HOME/.config/valkyx/power-profile" 2>/dev/null || echo "")
    case "$saved" in
        performance|balanced|power-saver)
            ~/.local/bin/valkyx-power set "$saved" >/dev/null 2>&1
            _log "re-applied saved profile -> ${saved}"
            ;;
        *) _log "no valid saved profile; leaving as-is" ;;
    esac
    ~/.local/bin/valkyx-gpu profile >/dev/null 2>&1 || _log "valkyx-gpu profile hook failed"
}

# Apply once at start
apply_profile

# React to D-Bus property changes on the power-profiles daemon (system bus).
dbus-monitor --system "sender='net.hadess.PowerProfiles',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/net/hadess/PowerProfiles'" 2>/dev/null | while read -r line; do
    case "$line" in
        *'ActiveProfile'*) apply_profile ;;
    esac
done
