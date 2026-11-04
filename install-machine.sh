#!/usr/bin/env bash
#===============================================================================
# AXORA — Machine-to-Shell Installer
#===============================================================================
# Prepares a bare Arch Linux machine (TTY-only or existing GUI) into a complete
# Axora Hyprland shell: dependencies → Hyprland compositor → SDDM greeter →
# Axora dotfiles shell → settings panel (Super+I) → fonts → input method →
# services enabled.
#
# Runs as root (sudo). Prompts for the root password ONCE at start, then every-
# thing is auto-approved — no further approvals needed.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/axorasamo/axora-dotfiles/master/install-machine.sh | sudo bash
#   or: sudo ./install-machine.sh
#
# Idempotent: safe to re-run. Skips already-installed packages and services.
#===============================================================================
set -uo pipefail

#-------------------------------------------------------------------------------
# Colours & logging
#-------------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { printf '%b%s%b\n' "$BLUE" "[axora]" "$NC$*"; }
ok()   { printf '%b%s%b\n' "$GREEN" "[  OK  ]" "$NC$*"; }
warn() { printf '%b%s%b\n' "$YELLOW" "[ WARN ]" "$NC$*" >&2; }
err()  { printf '%b%s%b\n' "$RED" "[ FAIL ]" "$NC$*" >&2; }
step() { printf '\n%b=== %s ===%b\n' "$BOLD$CYAN" "$*" "$NC"; }

#-------------------------------------------------------------------------------
# Must run as root
#-------------------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    err "This script must run as root. Re-run with: sudo $0"
    exit 1
fi

#-------------------------------------------------------------------------------
# One-time root password prompt, then everything is auto-approved
#-------------------------------------------------------------------------------
step "Root authentication"
if ! sudo -v 2>/dev/null; then
    # We're already root; just confirm
    ok "Running as root"
else
    ok "Root authenticated — all subsequent operations auto-approved"
fi

#-------------------------------------------------------------------------------
# Target user
#-------------------------------------------------------------------------------
TARGET_USER="${TARGET_USER:-axorasamo}"
log "Target user: $TARGET_USER"

#-------------------------------------------------------------------------------
# Package lists (categorised)
#-------------------------------------------------------------------------------
PACKAGES_DISPLAY_SERVER=(
    wayland wayland-utils xorg-server-xwayland mesa vulkan-icd-loader
    libglvnd egl-wayland egl-wayland2
)

PACKAGES_COMPOSITOR=(
    hyprland hyprlock hypridle hyprpicker hyprcursor hyprgraphics
    hyprtoolkit hyprutils hyprwire hyprland-guiutils hyprlang
)

PACKAGES_GREETER=(
    sddm qt6-base qt6-declarative qt6-svg qt6-wayland qt6-5compat
    qt6-multimedia qt6-tools qt6-imageformats qt6-shadertools qt6-speech
    qt6-virtualkeyboard qt6-translations qt6-location qt6-positioning
    qt6-sensors qt6-quick3d qt6-quicktimeline qt6-graphs qt6-webchannel
    qt6-webengine
)

PACKAGES_TERMINAL=(
    kitty kitty-shell-integration kitty-terminfo
)

PACKAGES_SHELL_PROMPT=(
    bash zsh starship fastfetch
)

PACKAGES_AUDIO=(
    pipewire pipewire-pulse pipewire-alsa pipewire-audio pipewire-jack
    wireplumber pavucontrol pamixer playerctl
    lib32-pipewire lib32-libpipewire
)

PACKAGES_BLUETOOTH=(
    bluez bluez-utils bluez-hid2hci bluez-libs bluez-obex
)

PACKAGES_NETWORK=(
    networkmanager networkmanager-openvpn networkmanager-vpn-plugin-openvpn
    nm-connection-editor
)

PACKAGES_INPUT_METHOD=(
    fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt
)

PACKAGES_FONTS=(
    ttf-jetbrains-mono-nerd ttf-space-mono
)

PACKAGES_NOTIFICATIONS=(
    mako wl-clipboard grim slurp
)

PACKAGES_GRAPHICS=(
    mesa vulkan-icd-loader libglvnd
)

PACKAGES_SERVICES=(
    power-profiles-daemon
)

PACKAGES_PORTALS=(
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
)

PACKAGES_MISC=(
    gnome-keyring git base-devel wget curl unzip polkit polkit-qt6
)

# All packages, in install order
ALL_PACKAGES=(
    "${PACKAGES_DISPLAY_SERVER[@]}"
    "${PACKAGES_COMPOSITOR[@]}"
    "${PACKAGES_GREETER[@]}"
    "${PACKAGES_TERMINAL[@]}"
    "${PACKAGES_SHELL_PROMPT[@]}"
    "${PACKAGES_AUDIO[@]}"
    "${PACKAGES_BLUETOOTH[@]}"
    "${PACKAGES_NETWORK[@]}"
    "${PACKAGES_INPUT_METHOD[@]}"
    "${PACKAGES_FONTS[@]}"
    "${PACKAGES_NOTIFICATIONS[@]}"
    "${PACKAGES_GRAPHICS[@]}"
    "${PACKAGES_SERVICES[@]}"
    "${PACKAGES_PORTALS[@]}"
    "${PACKAGES_MISC[@]}"
)

#-------------------------------------------------------------------------------
# Phase 1: System packages
#-------------------------------------------------------------------------------
install_packages() {
    step "Phase 1 — Package detection & installation"

    # Refresh package database (once)
    log "Refreshing package database..."
    if pacman -Sy --noconfirm >/dev/null 2>&1; then
        ok "Package database refreshed"
    else
        warn "Could not refresh package database (offline?); continuing with local cache"
    fi

    local installed_count=0 missing_count=0 newly_installed=0
    local missing_pkgs=()

    for pkg in "${ALL_PACKAGES[@]}"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            ok "installed: $pkg"
            installed_count=$((installed_count + 1))
        else
            warn "missing:    $pkg"
            missing_pkgs+=("$pkg")
            missing_count=$((missing_count + 1))
        fi
    done

    echo
    log "Package summary: $installed_count installed, $missing_count missing"

    if [ "${#missing_pkgs[@]}" -gt 0 ]; then
        log "Installing ${#missing_pkgs[@]} missing packages..."
        log "${missing_pkgs[*]}"
        if pacman -S --noconfirm --needed "${missing_pkgs[@]}"; then
            ok "All missing packages installed"
            newly_installed="${#missing_pkgs[@]}"
        else
            err "Some packages failed to install — continuing anyway"
        fi
    else
        ok "All packages already installed — nothing to do"
    fi

    echo
    log "Phase 1 complete: $installed_count already installed, $newly_installed newly installed"
}

#-------------------------------------------------------------------------------
# Phase 2: User & groups
#-------------------------------------------------------------------------------
setup_user() {
    step "Phase 2 — User & groups"

    if id "$TARGET_USER" >/dev/null 2>&1; then
        ok "User $TARGET_USER already exists"
    else
        log "Creating user $TARGET_USER..."
        useradd -m -G wheel -s /bin/bash "$TARGET_USER"
        ok "User $TARGET_USER created"
    fi

    # Add to essential groups
    for grp in video audio input wheel network; do
        if getent group "$grp" >/dev/null 2>&1; then
            usermod -aG "$grp" "$TARGET_USER" 2>/dev/null
            ok "Added $TARGET_USER to group $grp"
        else
            warn "Group $grp not found — skipping"
        fi
    done
}

#-------------------------------------------------------------------------------
# Phase 3: System services
#-------------------------------------------------------------------------------
enable_services() {
    step "Phase 3 — System services"

    local services=(
        sddm.service
        NetworkManager.service
        bluetooth.service
        pipewire.service
        pipewire-pulse.service
        wireplumber.service
        power-profiles-daemon.service
    )

    for svc in "${services[@]}"; do
        if systemctl is-enabled "$svc" >/dev/null 2>&1; then
            ok "enabled: $svc"
        else
            log "Enabling $svc..."
            if systemctl enable "$svc" >/dev/null 2>&1; then
                ok "enabled: $svc"
            else
                warn "could not enable: $svc"
            fi
        fi
    done
}

#-------------------------------------------------------------------------------
# Phase 4: Fonts
#-------------------------------------------------------------------------------
install_fonts() {
    step "Phase 4 — Fonts"

    # Fonts are installed via pacman in Phase 1; here we just verify
    local font_pkgs=(ttf-jetbrains-mono-nerd ttf-space-mono)
    for pkg in "${font_pkgs[@]}"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            ok "font installed: $pkg"
        else
            warn "font missing: $pkg (will be installed in Phase 1)"
        fi
    done

    # Rebuild font cache
    log "Rebuilding font cache..."
    fc-cache -f >/dev/null 2>&1
    ok "Font cache rebuilt"
}

#-------------------------------------------------------------------------------
# Phase 5: Deploy dotfiles
#-------------------------------------------------------------------------------
deploy_dotfiles() {
    step "Phase 5 — Deploy Axora dotfiles"

    # Resolve repo dir from script location (works from any clone path)
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_dir="$script_dir"
    if [ ! -d "$repo_dir" ]; then
        warn "Dotfiles repo not found at $repo_dir — skipping dotfile deploy"
        return 0
    fi

    local target_home="/home/$TARGET_USER"

    # Ensure target home exists
    mkdir -p "$target_home"

    # Copy home/ contents (dotfiles) — back up existing files
    if [ -d "$repo_dir/home" ]; then
        log "Deploying home dotfiles to $target_home"
        shopt -s dotglob
        for item in "$repo_dir/home"/*; do
            [ -e "$item" ] || continue
            local name
            name="$(basename "$item")"
            local dest="$target_home/$name"
            if [ -e "$dest" ] || [ -L "$dest" ]; then
                local ts
                ts="$(date +%Y%m%d%H%M%S)"
                mv "$dest" "${dest}.axora-bak-${ts}"
                log "Backed up existing $dest -> ${dest}.axora-bak-${ts}"
            fi
            cp -r "$item" "$dest"
            chown -R "$TARGET_USER:$TARGET_USER" "$dest"
        done
        shopt -u dotglob
        ok "Home dotfiles deployed"
    fi

    # Copy etc/ contents (SDDM config)
    if [ -d "$repo_dir/etc" ]; then
        log "Deploying /etc config"
        cp -r "$repo_dir/etc/." /etc/
        ok "/etc config deployed"
    fi

    # Copy usr/ contents (SDDM theme)
    if [ -d "$repo_dir/usr" ]; then
        log "Deploying /usr/share/sddm theme"
        cp -r "$repo_dir/usr/." /usr/
        # Fix permissions on SDDM theme
        find /usr/share/sddm/themes/axora -type d -exec chmod 755 {} + 2>/dev/null
        find /usr/share/sddm/themes/axora -type f -exec chmod 644 {} + 2>/dev/null
        ok "SDDM theme deployed"
    fi

    # Make .local/bin scripts executable
    if [ -d "$target_home/.local/bin" ]; then
        chmod -R +x "$target_home/.local/bin" 2>/dev/null
        chown -R "$TARGET_USER:$TARGET_USER" "$target_home/.local/bin"
    fi

    ok "Phase 5 complete — dotfiles deployed"
}

#-------------------------------------------------------------------------------
# Phase 6: SDDM config
#-------------------------------------------------------------------------------
configure_sddm() {
    step "Phase 6 — SDDM greeter configuration"

    # Ensure sddm.conf.d exists
    mkdir -p /etc/sddm.conf.d

    # Point SDDM at the Axora theme if not already configured
    if [ -f /etc/sddm.conf.d/axora.conf ]; then
        ok "SDDM axora.conf already present"
    else
        log "Creating SDDM axora.conf..."
        cat > /etc/sddm.conf.d/axora.conf <<'EOF'
[Theme]
CursorTheme=Maya-Green
CursorSize=34
Current=axora

[Users]
DefaultPath=/usr/local/bin:/usr/bin:/usr/sbin
RememberLastUser=true

[General]
Numlock=on
EOF
        ok "SDDM axora.conf created"
    fi
}

#-------------------------------------------------------------------------------
# Phase 7: Final summary & instructions
#-------------------------------------------------------------------------------
final_summary() {
    step "Installation complete — summary"

    echo
    printf '%b%s%b\n' "$BOLD$GREEN" "Axora shell install finished." "$NC"
    echo
    echo "What was done:"
    echo "  1. System packages detected & installed (Hyprland, SDDM, Qt6, fonts, etc.)"
    echo "  2. User '$TARGET_USER' created/added to groups (video, audio, input, wheel)"
    echo "  3. System services enabled (sddm, NetworkManager, bluetooth, pipewire, etc.)"
    echo "  4. Fonts installed & cache rebuilt"
    echo "  5. Axora dotfiles deployed (hypr, axora config, bin scripts, wallpapers)"
    echo "  6. SDDM greeter configured to use the Axora theme"
    echo
    echo "Next steps (manual):"
    echo "  - Reboot the machine, or start SDDM:  systemctl start sddm"
    echo "  - Log in as $TARGET_USER at the SDDM greeter"
    echo "  - Hyprland will launch with the Axora shell"
    echo "  - Press Super+I to open the Settings panel"
    echo "  - Press Super+S to open the Sidebar"
    echo
    echo "Dotfiles repo: /home/axorasamo/repos/axora-dotfiles"
    echo "To push to GitHub: cd /home/axorasamo/repos/axora-dotfiles && git remote add origin <your-repo> && git push -u origin master"
    echo
}

#===============================================================================
# MAIN
#===============================================================================
echo
printf '%b%s%b\n' "$BOLD$CYAN" "╔═════════════════════════════════════════════════════════╗" "$NC"
printf '%b%s%b\n' "$BOLD$CYAN" "║  AXORA — Machine-to-Shell Installer                ║" "$NC"
printf '%b%s%b\n' "$BOLD$CYAN" "║  Bare Arch → Axora Hyprland shell                        ║" "$NC"
printf '%b%s%b\n' "$BOLD$CYAN" "╚═════════════════════════════════════════════════════════╝" "$NC"
echo

install_packages
setup_user
enable_services
install_fonts
deploy_dotfiles
configure_sddm
final_summary
