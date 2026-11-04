-- ============================================================
-- HYDRA WORKSPACE — Hyprland Lua config (united single file)
-- CachyOS · Hyprland 0.57 · brand accent #00A86B
-- ============================================================

-- KEYBOARD
-- Two xkb layouts, so the *compositor* owns the input language: every app
-- follows, native + XWayland. hydra-im toggles this by re-applying kb_layout
-- (hyprctl rebuilds every keymap live) — fcitx's own hotkeys never fire here.
hl.config({ input = { kb_layout = "us,ara", kb_variant = "", kb_model = "", kb_options = "", kb_rules = "" } })

-- ENVIRONMENT
-- GDM sessions don't source shell profiles — export the user bin PATH
-- explicitly or every exec <script> bind into ~/.local/bin silently fails.
hl.env("PATH", "$HOME/.local/bin:/usr/local/bin:/usr/bin")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XCURSOR_THEME", "Maya-Green")
hl.env("XCURSOR_SIZE", "34")
-- input method (fcitx5, see hydra-im.service) — without these Qt/GTK apps
-- never create an fcitx input context, so no Arabic, no candidate window
hl.env("QT_IM_MODULE", "fcitx")
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
-- ============================================================
-- SECTION: INPUT
-- ============================================================

-- INPUT (60% keyboard + laptop touchpad)
hl.config({
    input = {
        -- kb_layout is deliberately NOT set here: the KEYBOARD block above
        -- declares "us,ara". A second hl.config with kb_layout overwrote the
        -- list with a single "us", so the second layout only ever existed
        -- because of `hydra-im restore`. Do not re-add it.
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },
    gestures = {
        ["workspace_swipe_distance"] = 300,
        ["workspace_swipe_cancel_ratio"] = 0.5,
        ["workspace_swipe_min_speed_to_force"] = 30,
        ["workspace_swipe_forever"] = false,
        ["workspace_swipe_create_new"] = true,
        ["workspace_swipe_invert"] = true,
    },
})

-- ydotool virtual device: flat accel so synthetic REL moves are 1:1
hl.device({
    name          = "ydotoold-virtual-device-1",
    accel_profile = "flat",
    sensitivity   = 0,
})
-- ============================================================
-- SECTION: KEYBINDS
-- ============================================================

-- KEYBINDS — designed for a 60% keyboard
-- No function row, no arrows, no nav cluster, no media keys.
-- Layers: NORMAL (here) · CREATIVE (Super+V) · SYSTEM (Super+X)

local mod = "SUPER"

-- swallow BARE Super presses so they never forward to the focused Waydroid
-- window (GTV opens its Apps window on META). SUPER+combos still work because
-- modifier state is tracked independently of these catches.
hl.bind("SUPER_L", hl.dsp.submap("reset"))
hl.bind("SUPER_R", hl.dsp.submap("reset"))

-- ---- apps (launch-or-focus: focus if open, else launch) ----
-- Return is the exception: a terminal is not a single-window app. Pressing it
-- always spawns, because raising the terminal you are already sitting in is
-- never what you meant. Super+Shift+Return keeps the launch-or-focus
-- behaviour for when you do want to jump back to the existing one.
hl.bind(mod .. " + Return",         hl.dsp.exec_cmd("setsid -f kitty"))
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("hydra-focus kitty kitty"))
hl.bind(mod .. " + B",           hl.dsp.exec_cmd("hydra-focus chrome helium-browser"))
hl.bind(mod .. " + E",           hl.dsp.exec_cmd("hydra-focus thunar thunar"))
hl.bind(mod .. " + C",           hl.dsp.exec_cmd("hydra-focus code-oss code-oss"))
hl.bind(mod .. " + Space",       hl.dsp.exec_cmd("qs -c hydra ipc call launcher toggle"))
hl.bind(mod .. " + S",           hl.dsp.exec_cmd("qs -c hydra ipc call panel toggle"))
hl.bind(mod .. " + A",           hl.dsp.exec_cmd("qs -c hydra ipc call panelLeft toggle"))
hl.bind(mod .. " + I",           hl.dsp.exec_cmd("qs -c hydra ipc call settings toggle"))
hl.bind(mod .. " + D",           hl.dsp.exec_cmd("$HOME/.local/bin/hydra-holo-window"))
hl.bind(mod .. " + CTRL + D",     hl.dsp.exec_cmd("$HOME/.local/bin/hydra-holo-window"))
-- input language (xkb layout, via hydra-im). Two paths, both on keys a 60%
-- board actually has. Scroll_Lock is the primary: one dead key repurposed, no
-- chord, one tap — nothing to hold in the right order. Ctrl+Space is the
-- universal OS/IME standard (Windows/Android/every DE) for muscle memory.
-- The old Super+SHIFT+Space was removed: it trained mashing, and mashing is
-- what the pre-flock race turned into 1000 presses per switch.
hl.bind("Scroll_Lock",      hl.dsp.exec_cmd("hydra-im toggle"))
hl.bind("CTRL + Space",     hl.dsp.exec_cmd("hydra-im toggle"))

-- push-to-talk for Hydra Assistant (modifier-only binds never fire; needs a key)
hl.bind("SUPER + CTRL + SPACE", hl.dsp.exec_cmd("hydra-assistant ptt"))

-- ---- window control ----
hl.bind(mod .. " + Q",           hl.dsp.window.close())
hl.bind("ALT + F4",              hl.dsp.window.close())
hl.bind(mod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mod .. " + T",           hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + G",           hl.dsp.layout("togglesplit"))

-- ---- window groups (tabs) ----
hl.bind(mod .. " + ALT + G",            hl.dsp.group.toggle())
hl.bind(mod .. " + ALT + SHIFT + G",    hl.dsp.window.move({ out_of_group = true }))
hl.bind(mod .. " + ALT + H",            hl.dsp.window.move({ into_group = "l" }))
hl.bind(mod .. " + ALT + J",            hl.dsp.window.move({ into_group = "d" }))
hl.bind(mod .. " + ALT + K",            hl.dsp.window.move({ into_group = "u" }))
hl.bind(mod .. " + ALT + L",            hl.dsp.window.move({ into_group = "r" }))
hl.bind(mod .. " + ALT + Tab",          hl.dsp.exec_cmd("hydra-alt-tab next"),  { repeating = true })
hl.bind(mod .. " + ALT + SHIFT + Tab",  hl.dsp.exec_cmd("hydra-alt-tab prev"), { repeating = true })

-- ---- focus (vim home row) ----
hl.bind(mod .. " + H",           hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + J",           hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K",           hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + L",           hl.dsp.focus({ direction = "right" }))

-- ---- move window ----
hl.bind(mod .. " + SHIFT + H",   hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + J",   hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K",   hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + L",   hl.dsp.window.move({ direction = "right" }))

-- ---- 100% keyboard secondary binds (classic, keep 60% ones above) ----
-- Focus/move mirror HJKL on arrows; resize is CTRL+arrows (relative delta,
-- same dispatcher shape as the pin block below). ALT+arrows join a group.
hl.bind(mod .. " + Left",         hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + Down",         hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + Up",           hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + Right",        hl.dsp.focus({ direction = "right" }))

hl.bind(mod .. " + SHIFT + Left",   hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + Down",   hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + Up",     hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + Right",  hl.dsp.window.move({ direction = "right" }))

hl.bind(mod .. " + CTRL + Left",  hl.dsp.window.resize({ x = -40, y = 0 }),   { repeating = true })
hl.bind(mod .. " + CTRL + Down",  hl.dsp.window.resize({ x = 0, y = 40 }),    { repeating = true })
hl.bind(mod .. " + CTRL + Up",    hl.dsp.window.resize({ x = 0, y = -40 }),   { repeating = true })
hl.bind(mod .. " + CTRL + Right", hl.dsp.window.resize({ x = 40, y = 0 }),    { repeating = true })

hl.bind(mod .. " + ALT + Left",   hl.dsp.window.move({ into_group = "l" }))
hl.bind(mod .. " + ALT + Down",   hl.dsp.window.move({ into_group = "d" }))
hl.bind(mod .. " + ALT + Up",     hl.dsp.window.move({ into_group = "u" }))
hl.bind(mod .. " + ALT + Right",  hl.dsp.window.move({ into_group = "r" }))

-- ---- semantic workspaces ----
local ws = {
    { key = "1", name = "name:01 studio" },
    { key = "2", name = "name:02 create" },
    { key = "3", name = "name:03 code" },
    { key = "4", name = "name:04 research" },
    { key = "5", name = "name:05 personal" },
    { key = "6", name = "name:06 game" },
}

for _, w in ipairs(ws) do
    hl.bind(mod .. " + " .. w.key,          hl.dsp.focus({ workspace = w.name }))
    hl.bind(mod .. " + SHIFT + " .. w.key,  hl.dsp.window.move({ workspace = w.name }))
end

-- Shift changes keysyms (! @ # $ % ^) — alias so move-to-ws works on real keyboards
local shift_aliases = {
    { key = "exclam",        name = "name:01 studio" },
    { key = "at",            name = "name:02 create" },
    { key = "numbersign",    name = "name:03 code" },
    { key = "dollar",        name = "name:04 research" },
    { key = "percent",       name = "name:05 personal" },
    { key = "asciicircum",   name = "name:06 game" },
}

for _, a in ipairs(shift_aliases) do
    hl.bind(mod .. " + SHIFT + " .. a.key, hl.dsp.window.move({ workspace = a.name }))
end

-- prev / next workspace (comma / period) — Ctrl variant carries the window
hl.bind(mod .. " + comma",        hl.dsp.exec_cmd("hydra-ws prev"),     { repeating = true })
hl.bind(mod .. " + period",       hl.dsp.exec_cmd("hydra-ws next"),     { repeating = true })
hl.bind(mod .. " + CTRL + comma", hl.dsp.exec_cmd("hydra-ws prev move"))
hl.bind(mod .. " + CTRL + period",hl.dsp.exec_cmd("hydra-ws next move"))
hl.bind("SUPER + Prior", hl.dsp.exec_cmd("hydra-ws prev"))
hl.bind("SUPER + Next",  hl.dsp.exec_cmd("hydra-ws next"))

-- ---- alt-tab: most-recent window cycle ----
-- Was two hl.bind on the same key (cyclenext + bringactivetotop) to fake a
-- chain, which Hyprland does not do. bringactivetotop has no Lua API and is
-- a no-op now anyway — focusing raises the window. One bind each, repeating so
-- holding Alt+Tab walks the stack like every other DE.
hl.bind("ALT + Tab",         hl.dsp.exec_cmd("hydra-alt-tab next"),  { repeating = true })
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("hydra-alt-tab prev"), { repeating = true })

-- ---- volume (U/D/M = up/down/mute) ----
hl.bind(mod .. " + SHIFT + U", hl.dsp.exec_cmd("pamixer -i 5"),  { repeating = true })
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("pamixer -d 5"),  { repeating = true })
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("pamixer -t"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pamixer -t"))

-- ---- brightness (60% keyboard has no brightness keys) ----
-- A/S mirror U/D for volume; the XF86 keys are bound too in case the row
-- does have them.
hl.bind(mod .. " + SHIFT + A", hl.dsp.exec_cmd("brightnessctl -q s +5%"), { repeating = true })
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("brightnessctl -q s 5%-"),  { repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q s +5%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 5%-"), { repeating = true })

-- ---- media (comma/period family with Alt = media navigation) ----
hl.bind(mod .. " + ALT + comma",  hl.dsp.exec_cmd("playerctl previous"))
hl.bind(mod .. " + ALT + space",  hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind(mod .. " + ALT + period", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86AudioPlay",     hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPause",    hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext",     hl.dsp.exec_cmd("playerctl next"))

-- ---- screenshots (no Print key on 60%) ----
hl.bind(mod .. " + CTRL + P",                hl.dsp.exec_cmd("hydra-screenshot region"))
hl.bind(mod .. " + CTRL + SHIFT + P",        hl.dsp.exec_cmd("hydra-screenshot full"))
hl.bind("Print",                             hl.dsp.exec_cmd("hydra-screenshot full"))
hl.bind(mod .. " + Print",                   hl.dsp.exec_cmd("hydra-screenshot region"))

-- ---- screen recording (toggle) ----
hl.bind(mod .. " + SHIFT + R",               hl.dsp.exec_cmd("hydra-record"))

-- ---- game mode (toggle) ----
hl.bind(mod .. " + SHIFT + G",               hl.dsp.exec_cmd("hydra-gamemode"))

-- ---- game picker (launcher games section) ----
hl.bind(mod .. " + CTRL + G",                hl.dsp.exec_cmd("qs -c hydra ipc call launcher open game"))

-- ---- emoji picker ----
hl.bind(mod .. " + SHIFT + E",               hl.dsp.exec_cmd("hydra-emoji"))

-- ---- color picker ----
hl.bind(mod .. " + SHIFT + C",               hl.dsp.exec_cmd("hydra-color"))

-- ---- picture-in-picture (toggle) ----
-- pin / center / picture-in-picture.
-- These were shell scripts (hydra-pin / hydra-center / hydra-pip) that read
-- window state with `hyprctl activewindow -j` — which works — and then called
-- `hyprctl dispatch` to act on it, which is broken in 0.56.2 and did nothing
-- while reporting success. The state-reading part was fine; the writing part
-- was dead. A bind's hl.dsp.* object runs in the compositor and does work, so
-- the whole script was unnecessary: the dispatch is now inline.
-- Float is toggled unconditionally because the config Lua cannot read window
-- state (hl.getprop is nil here), so the scripts' "only float if not already
-- floating" branch cannot be reproduced. Toggling off an already-floating
-- window and re-floating it lands in the same place.
hl.bind(mod .. " + SHIFT + P", function()
    hl.dsp.window.float({ action = "toggle" })
    hl.dsp.window.resize({ x = 400, y = 225 })
    hl.dsp.window.move({ x = 946, y = 523 })
    hl.dsp.window.pin()
end)

-- ---- float + center active window ----
hl.bind(mod .. " + SHIFT + F", function()
    hl.dsp.window.float({ action = "toggle" })
    hl.dsp.window.center()
end)

-- ---- pin active window to all workspaces (toggle) ----
hl.bind(mod .. " + SHIFT + O", hl.dsp.window.pin())

-- ---- invoke default action on latest notification ----
hl.bind(mod .. " + SHIFT + N",               hl.dsp.exec_cmd("makoctl invoke"))

-- ---- cycle accent color (theme switcher) ----
hl.bind(mod .. " + SHIFT + T",               hl.dsp.exec_cmd("qs -c hydra ipc call theme cycle"))

-- ---- lock ----
hl.bind(mod .. " + CTRL + ALT + L",          hl.dsp.exec_cmd("hydra-lock"))

-- ---- power menu (Super+X direct, and the physical power key) ----
hl.bind(mod .. " + X",              hl.dsp.exec_cmd("qs -c hydra ipc call power toggle"))
hl.bind("XF86PowerOff",             hl.dsp.exec_cmd("qs -c hydra ipc call power toggle"))

-- ---- keybinds reference (Super+Shift+K; K itself = focus up) ----
hl.bind(mod .. " + SHIFT + K", hl.dsp.exec_cmd("qs -c hydra ipc call settings openKeyboard"))

-- ---- network editor (was SYSTEM submap N) ----
hl.bind(mod .. " + N",     hl.dsp.exec_cmd("nm-connection-editor"))

-- ---- project picker ----
hl.bind(mod .. " + P",                       hl.dsp.exec_cmd("hydra-project"))

-- ---- clipboard manager ----
hl.bind(mod .. " + SHIFT + V",   hl.dsp.exec_cmd("hydra-clipboard"))

-- ---- Quake scratchpad console (dropdown terminal) ----
hl.bind(mod .. " + grave",              hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mod .. " + SHIFT + grave",      hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- ---- wallpaper/media selector (skew deck + grid) ----
hl.bind(mod .. " + W",           hl.dsp.exec_cmd("qs -c hydra ipc call wallpaper toggle"))

-- ---- welcome panel: keybinds, theme, language, on/off switches ----
hl.bind(mod .. " + SHIFT + W",   hl.dsp.exec_cmd("qs -c hydra ipc call welcome toggle"))

-- ---- mouse: SUPER+RMB drag = resize window ----
hl.bind("SUPER + mouse:272", function()
    hl.dsp.window.resize()
end)

-- ---- backup HYDRA configs ----
hl.bind(mod .. " + SHIFT + B",               hl.dsp.exec_cmd("hydra-backup"))

-- ============================================================
-- SUBMAPS
-- ============================================================

-- CREATIVE submap: Super+V enter, Esc exit
hl.define_submap("creative", function()
    hl.bind("B",  hl.dsp.exec_cmd("blender"))
    hl.bind("R",  hl.dsp.exec_cmd("davinci-resolve"))
    hl.bind("D",  hl.dsp.exec_cmd("inkscape"))
    hl.bind("A",  hl.dsp.exec_cmd("easyeffects"))
    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- submap entry
hl.bind(mod .. " + V",           hl.dsp.submap("creative"))

-- SYSTEM submap removed (Sep 6): Super+X now opens the power menu directly.
-- Its keys were re-homed: power→Super+X, keybinds→Super+Shift+K, terminal→Super+Return
-- (always spawns; Super+Shift+Return focuses the open one),
-- screenshots→Super+Ctrl+P/Shift+P, lock→Super+Ctrl+Alt+L, network→Super+N.
-- ============================================================
-- SECTION: MONITOR + WORKSPACES
-- ============================================================

-- MONITOR + WORKSPACES
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Keep all six semantic workspaces alive so Mod+1..6 always land somewhere
-- real (avoids a stray numeric "1" that apps open onto at boot being a
-- different workspace than the named "01 studio" the keybind targets).
-- Waydroid opens on the active workspace (see 60-rules.lua) — no hidden TV ws.
for _, ws in ipairs({ "01 studio", "02 create", "03 code", "04 research", "05 personal", "06 game" }) do
    hl.workspace_rule({ workspace = "name:" .. ws, persistent = true })
end
-- ============================================================
-- SECTION: LOOK & BEHAVIOR
-- ============================================================

-- LOOK & BEHAVIOR — quiet creative workstation
-- Palette derived from hydra-samo-wallpaper (#0a1210 base).
-- #00A86B appears ONLY here (focused border) and in UI accents.
hl.config({
    general = {
        gaps_in          = 8,
        gaps_out         = 16,
        border_size      = 2,
        col = {
            active_border   = { colors = { "rgba(00a86bee)", "rgba(7c4dffee)" }, angle = 45 },
            inactive_border = "rgba(00a86b44)",
        },
        layout           = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding         = 20,
        active_opacity   = 0.93,
        inactive_opacity = 0.86,
        shadow = { enabled = false },
        blur = {
            enabled            = true,
            size               = 5,
            passes             = 3,
            noise              = 0.02,
            contrast           = 1.1,
            brightness         = 0.9,
            vibrancy           = 0.2,
            vibrancy_darkness  = 0.5,
            new_optimizations  = true,
            xray              = false,
        },
    },

    xwayland = {
        force_zero_scaling = true,
    },

    cursor = {
        no_hardware_cursors = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        key_press_enables_dpms  = true,
        mouse_move_enables_dpms = true,
        focus_on_activate       = true,
    },

    debug = {
        vfr = true,
    },
})
-- ============================================================
-- SECTION: ANIMATIONS
-- ============================================================

-- ANIMATIONS — cinematic but instant
-- Brand easing token (same curve as the PORTFOLIO site).
hl.curve("hydraOut", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })

hl.animation({ leaf = "windows",       enabled = true,  speed = 2, bezier = "hydraOut", style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 2, bezier = "hydraOut", style = "slide" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1, bezier = "hydraOut" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1, bezier = "hydraOut" })
hl.animation({ leaf = "fadeSwitch",    enabled = true,  speed = 1, bezier = "hydraOut" })
hl.animation({ leaf = "fadeDim",       enabled = true,  speed = 1, bezier = "hydraOut" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 3, bezier = "hydraOut", style = "slide" })
hl.animation({ leaf = "border",        enabled = true,  speed = 1, bezier = "default" })
hl.animation({ leaf = "borderangle",   enabled = false })
hl.animation({ leaf = "layers",        enabled = false })
-- ============================================================
-- SECTION: WINDOW + LAYER RULES
-- ============================================================

-- WINDOW + LAYER RULES

-- Hydra Studio → STUDIO workspace
hl.window_rule({
    name      = "hydra-studio",
    match     = { class = "^(HYDRAStudioSite|HYDRAStudioDash)$" },
    workspace = "name:01 studio",
})

-- Gaming → GAME workspace
hl.window_rule({
    name      = "gaming",
    match     = { class = "^(net%.lutris%.Lutris|lutris|gamescope|MangoHud)$" },
    workspace = "06 game",
})

-- Dialogs float
hl.window_rule({
    name  = "float-dialogs",
    match = { class = "^(pavucontrol|nm-connection-editor|blueman-manager)$" },
    float = true,
})

-- HYDRA assistant window mode (`hydra-holo-window`): a real resizable
-- toplevel, so it floats centered instead of tiling fullscreen.
-- Class-only match: the shell creates no other toplevel windows.
hl.window_rule({
    name  = "hydra-holo-window",
    match = { class = "^(org%.quickshell)$" },
    float = true,
    center = true,
    size  = "1200 690",
})

hl.window_rule({
    name  = "size-nm-editor",
    match = { class = "^(nm-connection-editor)$" },
    size  = "900 600",
})

-- Settings floats (HydraSettings panel)
hl.window_rule({
    name  = "float-settings",
    match = { class = "^(HydraSettings)$" },
    float = true,
})

hl.window_rule({
    name = "size-settings",
    match = { class = "^(HydraSettings)$" },
    size  = "960 640",
})

-- HYDRA GAMES floats at a fixed size (it is a tool, not a tiled doc window)
hl.window_rule({
    name  = "float-hydra-games",
    match = { class = "hydra-games" },
    float = true,
})
hl.window_rule({
    name = "size-hydra-games",
    match = { class = "hydra-games" },
    size  = "1120 680",
})

-- System app glassmorphism
hl.window_rule({
    name     = "glass-apps",
    match    = { class = "^(thunar|kitty|helium-browser|antigravity)$" },
    opacity  = "0.86 override 0.78 override",
})

-- Quickshell glassmorphism
hl.layer_rule({
    name  = "quickshell-blur",
    match = { namespace = "^quickshell$" },
    blur  = true,
})

hl.layer_rule({
    name           = "quickshell-ignore-alpha",
    match          = { namespace = "^quickshell$" },
    ignore_alpha   = 0.1,
})
-- ============================================================
-- SECTION: QUAKE CONSOLE (scratchpad)
-- ============================================================

-- Quake dropdown console on special:scratchpad (ports Omarchy's qconsole.lua).
-- Super+grave drops a console from the top; Super+Shift+grave moves a window
-- into it. One tiled window = centered panel, boxed min(tall*2, width) wide;
-- a second window turns it into a full-width workspace.

local SCRATCHPAD = "special:scratchpad"
local seed = "[workspace special:scratchpad silent] kitty"

hl.config({
    decoration = {
        dim_special = 0.6,
    },
})

local beside, below = nil, nil

local function cover(side, bottom)
    if beside == side and below == bottom then
        return false
    end
    beside, below = side, bottom

    hl.workspace_rule({
        workspace = SCRATCHPAD,
        gaps_in   = 0,
        gaps_out  = { top = 0, right = side, bottom = bottom, left = side },
        no_border = true,
    })
    return true
end

local function alone()
    local tiled = 0
    for _, window in ipairs(hl.get_workspace_windows(SCRATCHPAD)) do
        if not window.floating then
            tiled = tiled + 1
        end
    end
    return tiled <= 1
end

local function fit(monitor)
    if not monitor or not monitor.scale or monitor.scale <= 0 then
        return false
    end

    local width, height = monitor.width, monitor.height
    if monitor.transform and monitor.transform % 2 == 1 then
        width, height = height, width
    end

    local reserved = monitor.reserved or { top = 0, right = 0, bottom = 0, left = 0 }
    height = height / monitor.scale - (reserved.top or 0) - (reserved.bottom or 0)
    width  = width / monitor.scale - (reserved.left or 0) - (reserved.right or 0)

    local tall = math.floor(height * 0.5)
    local wide = width
    if alone() then
        wide = math.min(width, tall * 2)
    end

    return cover(math.floor((width - wide) / 2), math.floor(height - tall))
end

local function console_monitor()
    local ws  = hl.get_workspace(SCRATCHPAD)
    local mon = ws and ws.visible and ws.monitor

    if mon and mon.scale and mon.scale > 0 then
        return mon
    end

    return hl.get_active_monitor()
end

local function refit(monitor)
    if fit(monitor or console_monitor()) then
        hl.exec_scheduled_prop_refresh_immediately()
    end
end

cover(0, 0)
fit(console_monitor())

-- on_created_empty is deprecated in 0.57: seed the console from the
-- workspace.created event instead, guarded by the same "was it empty" test.
hl.on("workspace.created", function(ws)
    if ws and ws.name == SCRATCHPAD and ws.is_empty then
        hl.exec_cmd(seed)
    end
end)

hl.on("monitor.layout_changed", function() refit() end)
hl.on("monitor.focused",        function() refit() end)
hl.on("workspace.special_active", function(ws, mon)
    if ws and ws.name == SCRATCHPAD then refit(mon) end
end)
hl.on("workspace.move_to_monitor", function(ws, mon)
    if ws and ws.name == SCRATCHPAD then refit(mon) end
end)

local function recount()
    local ws = hl.get_workspace(SCRATCHPAD)
    if ws and ws.visible then
        refit()
    end
end

hl.on("window.open",             recount)
hl.on("window.destroy",          recount)
hl.on("window.move_to_workspace", recount)
hl.on("window.update_rules",     recount)

hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 3, bezier = "hydraOut", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "hydraOut", style = "slide bottom" })
-- ============================================================
-- SECTION: AUTOSTART
-- ============================================================

-- AUTOSTART — session-scoped, nothing spawns into GNOME
hl.on("hyprland.start", function()
    -- start on the first semantic workspace so apps opened at boot land in
    -- "01 studio" (matching Mod+1) instead of on a stray numeric "1"
    hl.dispatch(hl.dsp.focus({ workspace = "name:01 studio" }))

    -- wallpaper (kind-dispatch: image → awww still instant; gif/video → mpvpaper over a
    -- blanked awww so the previous still never peeks under the video or flashes back)
    -- ~/.cache/hydra-wallpaper.{kind,path} written by HydraState.setWallpaper.
    hl.exec_cmd("sleep 0.4 && sh -c 'K=$(cat ~/.cache/hydra-wallpaper.kind 2>/dev/null || echo image); P=$(cat ~/.cache/hydra-wallpaper.path 2>/dev/null); if [ \"$K\" = image ]; then awww img --transition-type none \"${P:-$HOME/.local/share/backgrounds/hydra-samo-wallpaper.png}\"; else awww clear 2>/dev/null; [ -n \"$P\" ] && mpvpaper -o \"loop=inf no-audio no-osc\" eDP-1 \"$P\" >/dev/null 2>&1 & fi'")

    -- shell chrome
    hl.exec_cmd("qs -c hydra")
    hl.exec_cmd("mako")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    -- nm-applet removed: shell owns wifi UI (nmcli) + connection toast; its GTK
    -- tooltip/notification showed the un-themed staircase signal icon.

    -- idle + clipboard history
    -- hypridle now managed by hypridle.service (Restart=always)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
-- Re-apply the last chosen input language: a config (re)load rebuilds every
-- keymap from input.kb_layout above, which would snap the layout back to "us".
hl.exec_cmd("$HOME/.local/bin/hydra-im restore")
