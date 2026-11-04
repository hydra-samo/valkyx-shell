# HYDRA SHELL — IMAGE & SETTINGS CATALOG

This document catalogs the Hydra Hyprland shell as it exists on this host,
including the **Super+I settings panel** (5 pages), the sidebar control center,
SDDM greeter, lock screen, and every shell component. Image paths are placeholders
— screenshots or AI-generated images can be dropped in at the listed locations.

---

## A. SYSTEM INVENTORY — what's already installed on this host

Host: Arch Linux, user `hydrasamo`, 1,859 total pacman packages.

### Display server & graphics
| Package | Version | Status | Role |
|---------|---------|--------|------|
| wayland | installed | ✅ | Display server protocol |
| wayland-utils | installed | ✅ | Wayland utilities |
| xorg-server-xwayland | installed | ✅ | X11 app compatibility |
| mesa | installed | ✅ | OpenGL graphics drivers |
| vulkan-icd-loader | installed | ✅ | Vulkan loader |
| libglvnd | installed | ✅ | GL vendor dispatch |
| egl-wayland / egl-wayland2 | installed | ✅ | EGL on Wayland |

### Compositor & lock
| Package | Version | Status | Role |
|---------|---------|--------|------|
| hyprland | 0.57.0-3.1 | ✅ | Wayland compositor |
| hyprlock | 0.9.7-2.1 | ✅ | Screen locker |
| hypridle | 0.1.8-2.1 | ✅ | Idle daemon |
| hyprpicker | 0.4.8-1.1 | ✅ | Colour picker |
| hyprcursor | 0.1.13-7.1 | ✅ | Cursor management |
| hyprgraphics | 0.6.0-1.1 | ✅ | Graphics effects |
| hyprtoolkit | 0.6.0-3.1 | ✅ | Toolkit |
| hyprutils | 0.14.3-5.1 | ✅ | Utilities |
| hyprwire | 0.3.1-3.1 | ✅ | Hyprland IPC |
| hyprland-guiutils | 0.2.2-6.1 | ✅ | GUI utils |
| hyprlang | 0.6.8-5.1 | ✅ | Config language |

### Display manager
| Package | Version | Status | Role |
|---------|---------|--------|------|
| sddm | 0.21.0-8 | ✅ | Display manager (Hydra theme) |
| qt6-base / qt6-declarative / qt6-svg / qt6-wayland | installed | ✅ | SDDM QML greeter runtime |
| qt6-5compat / qt6-multimedia / qt6-tools | installed | ✅ | Qt6 compat & multimedia |
| qt6-imageformats / qt6-shadertools / qt6-speech | installed | ✅ | Qt6 image/shader/speech |
| qt6-virtualkeyboard / qt6-translations | installed | ✅ | Qt6 virtual keyboard |

### Terminal
| Package | Version | Status | Role |
|---------|---------|--------|------|
| kitty | 0.49.2-1.1 | ✅ | GPU terminal emulator |
| kitty-shell-integration | installed | ✅ | Shell integration |
| kitty-terminfo | installed | ✅ | Terminfo |

### Shell & prompt
| Package | Version | Status | Role |
|---------|---------|--------|------|
| bash | installed | ✅ | Shell |
| zsh | installed | ✅ | Shell (default for hydrasamo) |
| starship | installed | ✅ | Cross-shell prompt |
| fastfetch | 2.70.0-1.1 | ✅ | System info tool (used by hydra-fetch) |

### Audio
| Package | Version | Status | Role |
|---------|---------|--------|------|
| pipewire / pipewire-pulse / pipewire-alsa / pipewire-audio / pipewire-jack | installed | ✅ | Audio server |
| wireplumber | installed | ✅ | Audio session manager |
| pavucontrol | installed | ✅ | Volume control GUI |
| pamixer | installed | ✅ | CLI volume control |
| playerctl | installed | ✅ | Media player control |
| lib32-pipewire / lib32-libpipewire | installed | ✅ | 32-bit audio |

### Bluetooth
| Package | Version | Status | Role |
|---------|---------|--------|------|
| bluez | 5.87-2.1 | ✅ | Bluetooth stack |
| bluez-utils | installed | ✅ | Bluetooth utilities |
| bluez-hid2hci | installed | ✅ | HID to HCI |
| bluez-libs | installed | ✅ | Bluetooth libraries |
| bluez-obex | installed | ✅ | OBEX profile |

### Network
| Package | Version | Status | Role |
|---------|---------|--------|------|
| networkmanager | 1.58.1-3 | ✅ | Network management |
| networkmanager-openvpn | installed | ✅ | OpenVPN plugin |
| networkmanager-vpn-plugin-openvpn | installed | ✅ | VPN plugin |
| nm-connection-editor | installed | ✅ | Network GUI editor (Super+N) |

### Input method
| Package | Version | Status | Role |
|---------|---------|--------|------|
| fcitx5 | 5.1.23-1.1 | ✅ | Input method framework (Arabic) |
| fcitx5-configtool | 5.1.16-3.1 | ✅ | fcitx5 config GUI |
| fcitx5-gtk | 5.1.7-1.1 | ✅ | GTK module |
| fcitx5-qt | 5.1.16-2.1 | ✅ | Qt module |

### Fonts (config-referenced)
| Package | Version | Status | Role |
|---------|---------|--------|------|
| ttf-jetbrains-mono-nerd | installed | ✅ | Hyprlock/Settings mono font |
| ttf-space-mono | MISSING | ❌ | Space Grotesk-ish accent font |
| space-grotesk-font | MISSING | ❌ | Brand accent font |

### Notifications, clipboard, screenshots
| Package | Version | Status | Role |
|---------|---------|--------|------|
| mako | installed | ✅ | Notification daemon |
| makoctl | MISSING | ❌ | mako CLI (mod+Shift+N) |
| wl-clipboard | installed | ✅ | Wayland clipboard |
| grim | 1.5.0-2.1 | ✅ | Screenshot tool |
| slurp | installed | ✅ | Region selector |

### Power, portals, polkit, misc
| Package | Version | Status | Role |
|---------|---------|--------|------|
| power-profiles-daemon | 0.30-3 | ✅ | CPU power profiles |
| xdg-desktop-portal-hyprland | installed | ✅ | Hyprland desktop portal |
| xdg-desktop-portal-gtk | installed | ✅ | GTK desktop portal |
| polkit | installed | ✅ | PolicyKit |
| polkit-qt6 | installed | ✅ | Qt6 polkit |
| gnome-keyring | installed | ✅ | Keyring (keyring-start.sh) |
| git / base-devel / wget / curl / unzip | installed | ✅ | Build & download tools |
| btop | 1.4.7-1.1 | ✅ | System monitor |

---

## B. SETTINGS PANEL CATALOG — Super+I keybind

The settings panel opens with `Super+I` → `qs -c hydra ipc call settings toggle`.

**Window:** Floating glass panel, 960×640 px, centered on screen, draggable title bar,
Esc to close, exclusive zone −1 (floats above windows).

**Title bar:** "⭐ SETTINGS" (U+E808 U+E809), draggable, close button (⍰ U+E856).

**Nav rail** (5 icons, left side):
| Page | Icon | Unicode | Label |
|------|------|---------|-------|
| 0 | 🎨 | U+E913 | Appearance |
| 1 | 🖥️ | U+E902 | Display |
| 2 | ⌨️ | U+E80C | Keyboard |
| 3 | 🖱️ | U+E87D | Mouse |
| 4 | ⚡ | U+E825 | Session |

Version "v0.9" shown at bottom of nav rail.

---

### B.1. Appearance (page 0) — 🎨

**File:** `SettingsAppearancePage.qml`

**Controls:**
- **Wallpaper** — full-width blurred hero (blurMax 48, saturation 0.15, dark scrim 0.45, vignette) of the active wallpaper; click opens full skew/grid selector (Super+W). Online Wallhaven (SFW) search with thumb grid + "Load more".
- **Theme** — 6 Hydra accent swatches (Amber, Cyan, Ember, Hydra, Ocean, Violet) applied live via `applyTheme()`.
- **Effects** — Blur toggle (HydraState.blurEnabled).
- **Motion** — Reduced motion toggle (HydraState.reducedMotion).
- **Font scale** — slider 0.8× → 1.5× (HydraState.fontScale), persists via `savePersisted()`.

```
┌─────────────────────────────────────────────────────────┐
│ ⭐ SETTINGS                        [⍰]                  │
├──────────┬──────────────────────────────────────────────┤
│ 🎨       │  WALLPAPER                                   │
│          │  ┌─────────────[ blurred hero image ]─────┐  │
│          │  │   🌄  Browse wallpapers                 │  │
│          │  └────────────────────────────────────────┘  │
│          │  ONLINE   [ Search wallpapers... ][ Search ]│
│          │  🖼️ 🖼️ 🖼️ 🖼️ 🖼️ 🖼️ 🖼️ 🖼️ 🖼️ 🖼️  [Load more] │
│          │                                               │
│          │  THEME    ● ● ● ● ● ●  (accent swatches)    │
│          │  EFFECTS  Blur [○]                            │
│          │  MOTION   Reduced motion [○]                  │
│          │  FONT SCALE 0.8× ───●──── 1.5×                │
│          │                                               │
│          │                    v0.9                       │
└──────────┴──────────────────────────────────────────────┘
```

Image placeholder: `catalog/images/settings-appearance.png`

---

### B.2. Display (page 1) — 🖥️

**File:** `SettingsDisplayPage.qml`

**Controls:**
- Resolution info (`Screen.width × Screen.height`)
- Refresh rate ("60 Hz")
- **Night Light** — toggle (3500K), `HydraState.isOn("night")`
- **Scale** — 100% / 125% / 150% / 200% chips (wlr-randr scale, placeholder handler)

```
┌─────────────────────────────────────────────────────────┐
│ ⭐ SETTINGS                        [⍰]                  │
├──────────┬──────────────────────────────────────────────┤
│ 🖥️       │  DISPLAY                                     │
│          │  Resolution   1920 × 1080                    │
│          │  Refresh Rate 60 Hz                          │
│          │                                               │
│          │  NIGHT LIGHT                                 │
│          │  Night Light (3500K) [○]                     │
│          │                                               │
│          │  SCALE                                        │
│          │  [100%] [125%] [150%] [200%]                 │
│          │                                               │
│          │                    v0.9                       │
└──────────┴──────────────────────────────────────────────┘
```

Image placeholder: `catalog/images/settings-display.png`

---

### B.3. Keyboard (page 2) — ⌨️

**File:** `SettingsKeyboardPage.qml`

**Controls:** Full keybind reference, grouped by category:
- Session: Super+Return (Terminal), Super+B (Browser), Super+E (Files), Super+C (Editor), Super+Space (Launcher), Super+S (Sidebar), Super+I (Settings), Super+N (Network), Super+X (Power menu), Super+P (Projects)
- Windows: Super+Q (Close), Super+F (Fullscreen), Super+T (Float), Super+G (Toggle split)
- Navigation: Super+H/J/K/L (Move focus), Super+Shift+H/J/K/L (Move window), Alt+Tab (Cycle windows)
- Workspaces: Super+1-6 (Switch), Super+Shift+1-6 (Move to), Super+,. / . (Prev/Next)
- Volume: Super+Shift+U (Up), Super+Shift+D (Down), Super+Shift+M (Mute)
- Media: Super+Alt+Space (Play/Pause), Super+Alt+, / . (Prev/Next track)
- Capture: Super+Ctrl+P (Screenshot region), Super+Ctrl+Shift+P (Screenshot full)
- System: Super+Ctrl+Alt+L (Lock screen), Super+X (Power menu)
- Submaps: Super+V (Creative mode), Super+Shift+K (Keybinds reference)

```
┌─────────────────────────────────────────────────────────┐
│ ⭐ SETTINGS                        [⍰]                  │
├──────────┬──────────────────────────────────────────────┤
│ ⌨️       │  KEYBOARD SHORTCUTS                          │
│          │  ┌── Session ──┐                              │
│          │  │ Terminal    [Super+Return]                │
│          │  │ Browser     [Super+B]                     │
│          │  │ ...                                     │
│          │  ┌── Windows ──┐                             │
│          │  │ Close       [Super+Q]                     │
│          │  │ Fullscreen  [Super+F]                     │
│          │  ...                                       │
│          │                    v0.9                       │
└──────────┴──────────────────────────────────────────────┘
```

Image placeholder: `catalog/images/settings-keyboard.png`

---

### B.4. Mouse (page 3) — 🖱️

**File:** `SettingsMousePage.qml`

**Controls:**
- **Sensitivity** — slider −1.0 → +1.0 (`hyprctl eval 'hl.config({input = {sensitivity = ...}})'`)
- **Acceleration profile** — Flat / Adaptive chips
- **Natural scrolling** — toggle
- **Cursor** — theme swatches from `HydraTheme.themeNames` with cursor preview (`setCursor()`)

```
┌─────────────────────────────────────────────────────────┐
│ ⭐ SETTINGS                        [⍰]                  │
├──────────┬──────────────────────────────────────────────┤
│ 🖱️       │  MOUSE                                       │
│          │  SENSITIVITY                                 │
│          │  Speed   −1.0 ───●──── +1.0                  │
│          │                                               │
│          │  ACCELERATION PROFILE                        │
│          │  [Flat] [Adaptive]                           │
│          │                                               │
│          │  OPTIONS                                     │
│          │  Natural Scrolling [○]                       │
│          │                                               │
│          │  CURSOR                                      │
│          │  ● ● ● ● ● ●  (cursor theme swatches)        │
│          │                    v0.9                       │
└──────────┴──────────────────────────────────────────────┘
```

Image placeholder: `catalog/images/settings-mouse.png`

---

### B.5. Session (page 4) — ⚡

**File:** `SettingsSessionPage.qml`

**Controls:**
- **System info** — HYDRA LABS branding, Hyprland version, battery %, network status
- **Greeting** — "Greet me on startup" toggle (`greetingEnabled`), shows "hello, again" / "first run"
- **Power** — 4 buttons: Lock (`hydra-lock`), Logout (`hydra-power-action logout`), Reboot (`systemctl reboot`), Shutdown (`systemctl poweroff`, danger color)
- **Battery** — battery percentage bar with low (<20%) danger color

```
┌─────────────────────────────────────────────────────────┐
│ ⭐ SETTINGS                        [⍰]                  │
├──────────┬──────────────────────────────────────────────┤
│ ⚡       │  SESSION                                     │
│          │  ┌─────────────────────────────────────┐    │
│          │  │ ⭐ HYDRA LABS                   │    │
│          │  │ Hyprland 0.56 · HYDRA-S   🔋 78%    │    │
│          │  │                 🌐 connected          │    │
│          │  └─────────────────────────────────────┘    │
│          │                                               │
│          │  GREETING                                     │
│          │  Greet me on startup     [○]  hello, again   │
│          │                                               │
│          │  POWER                                        │
│          │  🔒 Lock     🚪 Logout     🔄 Reboot   ⏻ Shutdown│
│          │                                               │
│          │  BATTERY                                      │
│          │  🔋 ───████████████████████░░░░──── 78%      │
│          │                    v0.9                       │
└──────────┴──────────────────────────────────────────────┘
```

Image placeholder: `catalog/images/settings-session.png`

---

## C. IMAGE CATALOG — placeholder image paths

Create `catalog/images/` and populate with screenshots or AI-generated images:

| Image path | Description |
|------------|-------------|
| `catalog/images/settings-appearance.png` | Appearance settings page (Super+I → 🎨) |
| `catalog/images/settings-display.png` | Display settings page (Super+I → 🖥️) |
| `catalog/images/settings-keyboard.png` | Keyboard shortcuts page (Super+I → ⌨️) |
| `catalog/images/settings-mouse.png` | Mouse settings page (Super+I → 🖱️) |
| `catalog/images/settings-session.png` | Session/power page (Super+I → ⚡) |
| `catalog/images/settings-panel-overview.png` | Full settings window with nav rail |
| `catalog/images/sidebar-panel.png` | Sidebar control center (Super+S) |
| `catalog/images/sddm-greeter.png` | SDDM Hydra greeter login screen |
| `catalog/images/hyprlock-screen.png` | Hyprlock lock screen |
| `catalog/images/hyprland-workspace.png` | Hyprland workspace overview |
| `catalog/images/welcome-panel.png` | Hydra welcome panel (Super+Shift+W) |
| `catalog/images/power-menu.png` | Hydra power menu |

---

## D. SHELL COMPONENTS INVENTORY

### Scripts in `$HOME/.local/bin/` (92 hydra scripts)
hydra, hydra-ai, hydra-alt-tab, hydra-audio, hydra-auto-prime, hydra-awww-daemon,
hydra-backup, hydra-caffeine, hydra-cap, hydra-class-icon, hydra-clipboard,
hydra-color, hydra-console, hydra-copy, hydra-cursor, hydra-dash, hydra-diagnose,
hydra-dispatch, hydra-doctor, hydra-ds4-bt-test, hydra-ds4-pegasus, hydra-ds4-tv,
hydra-emoji, hydra-env, hydra-fetch, hydra-figlet, hydra-fix, hydra-focus,
hydra-gamemode, hydra-gamesession, hydra-gamesession-recover, hydra-gen-icons,
hydra-gen-theme, hydra-gpu, hydra-gpu-ppwatch.sh, hydra-gta-crashlog,
hydra-gtk-icons, hydra-hub-check, hydra-im,
hydra-jobs, hydra-launch, hydra-live-wallpaper, hydra-local-brain, hydra-lock,
hydra-lock-chip-sys, hydra-lock-chip-weather, hydra-lock-supervise, hydra-logout,
hydra-logout-watchdog, hydra-memory, hydra-mic-gain, hydra-notify,
hydra-obsidian-ai, hydra-opencode-ttyd, hydra-palette, hydra-pass-write,
hydra-pegasus-theme, hydra-pointer, hydra-power, hydra-power-action,
hydra-power-apply.sh, hydra-power-menu, hydra-project, hydra-record, hydra-remote,
hydra-remote-tv, hydra-remote-web, hydra-remote-web-wrap, hydra-reveal,
hydra-screenshot, hydra-shell-dev, hydra-shell-live, hydra-shell-reload,
hydra-shell-sync, hydra-shell-toggle, hydra-tailscale-status, hydra-ui-test,
hydra-update, hydra-vid2edit, hydra-wallfavs, hydra-wallhues, hydra-wallpaper,
hydra-weather, hydra-welcome, hydra-wifi-connect, hydra-ws, hydra-ws-windows

### Desktop files (`$HOME/.local/share/applications/`)
hydra-cam-tune, hydra-console, hydra-dashboard, hydra-doctor, hydra-games,
hydra-reveal, hydra-site, hydra-update, hydra-welcome-report, hydra-welcome

### Keybinds reference (mod = Super)
| Keybind | Action |
|---------|--------|
| Super+Return | Terminal (kitty) |
| Super+Shift+Return | Focus kitty |
| Super+B | Browser |
| Super+E | Files |
| Super+C | Editor |
| Super+Space | Launcher |
| Super+S | Sidebar |
| Super+I | **Settings** |
| Super+N | Network |
| Super+X | Power menu |
| Super+P | Projects |
| Super+Q | Close window |
| Super+F | Fullscreen |
| Super+T | Float |
| Super+G | Toggle split |
| Super+H/J/K/L | Move focus |
| Super+Shift+H/J/K/L | Move window |
| Alt+Tab | Cycle windows |
| Super+1-6 | Switch workspace |
| Super+Shift+1-6 | Move to workspace |
| Super+,. / . | Prev / Next workspace |
| Super+Shift+U/D/M | Volume up/down/mute |
| Super+Alt+, / . | Prev / Next track |
| Super+Ctrl+P / Shift+P | Screenshot region / full |
| Super+Print / Shift+Print | Screenshot full / region |
| Super+Shift+R | Record |
| Super+Shift+G | Gamemode |
| Super+Shift+E | Emoji |
| Super+Shift+C | Colour picker |
| Super+Shift+V | Clipboard |
| Super+Shift+N | Notifications |
| Super+Shift+T | Theme cycle |
| Super+Shift+K | Keybinds reference |
| Super+Shift+W | Welcome panel |
| Super+Shift+B | Backup |
| Super+Ctrl+Alt+L | Lock screen |
| Scroll_Lock / Ctrl+Space | Input method toggle |

### Quickshell shell components
- `HydraSettings.qml` — settings panel (Super+I)
- `HydraSidebar.qml` — sidebar control center (Super+S)
- `HydraWelcomePanel.qml` — welcome panel (Super+Shift+W)
- `HydraPowerMenu.qml` — power menu (Super+X)
- `HydraLauncher.qml` — app launcher (Super+Space)
- `HydraDock.qml` — dock
- `HydraHoloPanel.qml` — holo panel
- `HydraReactor.qml` — reactor
- `TopHud.qml` — top HUD

### Dotfiles repo structure (`/home/hydrasamo/repos/hydra-dotfiles`)
```
home/.config/hypr/          hyprland.lua, hyprlock.conf, hypridle.conf, assets/
home/.config/hydra/         power-profile, state.json, theming/, env/
home/.local/bin/            92 hydra scripts
home/.local/share/          desktop files, backgrounds, icons, emoji
home/Pictures/Wallpapers/   35 wallpapers
home/.bashrc .zshrc .profile| shell rc files ($HOME-portable)
etc/sddm.conf.d/hydra.conf  | SDDM greeter config
usr/share/sddm/themes/hydra/| SDDM QML theme (Main.qml, assets)
install.sh                  | dotfiles deploy script
install-machine.sh          | full machine preparer (this script)
README.md                   | documentation
```

---

## E. INSTALLER

`install-machine.sh` — prepares any Arch machine (bare TTY or existing GUI) into the
complete Hydra shell. Runs as root, prompts for password once, detects missing
packages, installs them, enables services, deploys dotfiles.

Run: `sudo ./install-machine.sh`

---

*Generated from the live Hydra host. Image placeholders await screenshots or AI generation.*