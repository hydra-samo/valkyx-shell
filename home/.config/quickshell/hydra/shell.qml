//@ pragma UseQApplication
// VALKYX DE — Composition root.
// Thin orchestrator: imports singletons + shell components.
// All UI lives in shell/*.qml, all logic in core/*.qml.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "core"
import "shell"  as Shell

ShellRoot {
    id: root

    // Top HUD strip
    Shell.TopHud {}

    // Left sidebar: wallpaper & media picker
    Shell.ValkyxLeftSidebar {}

    // Right sidebar: ActionCenter (quick toggles, sliders, media, system, power)
    Shell.ValkyxSidebar {}

    // Workspace transition indicator
    Shell.WorkspaceIndicator {}

    // Bottom dock
    Shell.ValkyxDock {}

    // Volume/brightness/mic/media OSD
    Shell.ValkyxOsd {}

    // Notification toast
    Shell.NotifToast {}

    // Settings window
    Shell.ValkyxSettings {}

    // The welcome panel (Super+Shift+W).
    Shell.ValkyxWelcomePanel {}

    // The greeting overlay. It is loaded THROUGH A LOADER, gated on
    // `active`, and that is the whole point — do not "simplify" this back into
    // a bare `Shell.ValkyxWelcomeGreeter {}`.
    //
    // A PanelWindow has `visible` pinned true: if it unmaps, Hyprland orphans it
    // and it keeps the input grab. So an always-instantiated greeter is a
    // fullscreen 1366x768 `aboveWindows` surface sitting over the desktop
    // forever, and it swallows every click, scroll and pointer event. I shipped
    // exactly that on Sep 28 and it killed the mouse: no scrolling, no
    // pointing. `enabled: false` on the inner gate does NOT help — that is
    // Qt-internal; the surface still eats compositor-level input while mapped.
    // Mounting it only for the greeting's ~5s means the input cost is bounded
    // to the moment the user is already looking at it.
    Loader {
        id: greetingLoader
        active: false
        sourceComponent: Shell.ValkyxWelcomeGreeter {}
        onLoaded: {
            if (greetingLoader.pendingHold > 0) item.holdMs = greetingLoader.pendingHold
            item.showOnce()
        }
        // set before active, so the item exists already holding the right time
        property int pendingHold: 5000
    }

    // Unmount as soon as the greeting is dismissed, so the fullscreen surface
    // goes away with it.
    Connections {
        target: ValkyxState
        function onWelcomeOpenChanged() {
            if (!ValkyxState.welcomeOpen) greetingLoader.active = false
        }
    }

    // Fire the greeting once, on boot, if the preference allows it.
    //
    // Deliberately NOT `active: ValkyxState.greetsOnBoot`: assigning to `active`
    // destroys the binding, and a surviving binding would re-mount the greeter
    // the instant the dismissal above sets it false — a greeting that can never
    // leave. One imperative trigger, no binding, no way to reopen.
    //
    // The user's on/off preference is read HERE and nowhere else, so the two
    // toggles (welcome window, settings) cannot disagree with each other or with
    // what actually happens. The session latch `greetsOnBoot` is not the
    // preference: the greeting consumes it to stop itself re-arming, which is
    // why persisting or toggling it would be wrong.
    //
    // Waits for `stateLoaded` rather than deciding from defaults. state.json is
    // read by a Process, so it arrives after this file's Component.onCompleted —
    // reading `greetedOnce` before then says "first run" on a machine that has
    // been greeting for months, and the late load would overwrite the flag back
    // to false, so the bug could never wear off.
    function tryGreeting() {
        if (greetedThisBoot) return
        if (!ValkyxState.stateLoaded) return
        greetedThisBoot = true
        if (!ValkyxState.greetingEnabled || !ValkyxState.greetsOnBoot) return
        // "Welcome" on the first login after install, "Welcome back" ever after.
        // Set before the mount and read once by the greeting line; never
        // persisted, because it describes this boot, not the machine.
        // `greetedOnce` IS the machine's, and is written only when a greeting is
        // really shown: starting with the toggle off must not quietly spend the
        // first run.
        ValkyxState.firstGreeting = !ValkyxState.greetedOnce
        ValkyxState.greetedOnce = true
        ValkyxState.savePersisted()
        greetingLoader.active = true
    }
    property bool greetedThisBoot: false

    Component.onCompleted: tryGreeting()

    // The late half of the same decision — see tryGreeting.
    Connections {
        target: ValkyxState
        function onStateLoadedChanged() {
            if (ValkyxState.stateLoaded) tryGreeting()
        }
    }

    // Shell-native launcher (accent-reactive, app icons, keyboard search)
    Shell.ValkyxLauncher { id: launcherWindow }

    // Floating power menu (on-screen popup, opened from the sidebar Power button)
    Shell.ValkyxPowerMenu { id: powerMenu }

    // Masked password prompt (WiFi join) — replaces fuzzel/zenity
    Shell.ValkyxPassword { id: passwordPrompt }

    // Approval popup: standalone card whenever the backend holds a pending
    // tool call (the window overlay only shows while the window is open).

    // Super+W wallpaper/media selector (iNiR-style skew deck + grid, awww/mpvpaper)
    Shell.ValkyxWallpaper { id: wallpaperWindow }

    // IPC: toggle launcher (open only — closing is Esc/Enter inside)
    IpcHandler {
        target: "launcher"
        function toggle(): string {
            // default toggle = full view; section pickers (open X) set section
            if (launcherWindow) launcherWindow.section = ""
            ValkyxState.launcherOpen = !ValkyxState.launcherOpen
            return ValkyxState.launcherOpen ? "open" : "close"
        }
        // open a pre-filtered section: game | clip | dir | app | cmd ...
        function open(section: string): string {
            if (launcherWindow) launcherWindow.openSection(section)
            return "section:" + section
        }
    }

    // IPC: toggle left sidebar
    IpcHandler {
        target: "panelLeft"
        function toggle(): string {
            ValkyxState.panelLeftOpen = !ValkyxState.panelLeftOpen
            return ValkyxState.panelLeftOpen ? "open" : "close"
        }
    }

    // IPC: toggle right sidebar (ActionCenter) — Super+S
    IpcHandler {
        target: "panel"
        function toggle(): string {
            ValkyxState.panelOpen = !ValkyxState.panelOpen
            return ValkyxState.panelOpen ? "open" : "close"
        }
        function open(): string {
            ValkyxState.panelOpen = true
            return "open"
        }
        function close(): string {
            ValkyxState.panelOpen = false
            return "close"
        }
    }

    // IPC: toggle power menu
    IpcHandler {
        target: "password"
        // "<label>|<target-file>". The path goes last because a tmpfs mktemp
        // path can never contain the separator, but an SSID could.
        function open(args: string): string {
            const i = args.indexOf("|")
            ValkyxState.passwordLabel = i < 0 ? "" : args.slice(0, i)
            ValkyxState.passwordTarget = i < 0 ? "" : args.slice(i + 1)
            if (ValkyxState.passwordTarget === "") return "no target"
            ValkyxState.passwordText = ""
            ValkyxState.passwordOpen = true
            return "prompted"
        }
        // cancel() and not a bare `passwordOpen = false`: only cancel() writes
        // the ":" sentinel, so flipping the state alone would leave a waiting
        // script polling for its full 90s.
        function close(): string {
            passwordPrompt.cancel()
            return "closed"
        }

        }

        // IPC: toggle power menu

        IpcHandler {

        target: "power"
        function toggle(): string {
            ValkyxState.powerOpen = !ValkyxState.powerOpen
            return ValkyxState.powerOpen ? "open" : "close"
        }
        // open/close as separate entry points: `toggle` is unusable from a
        // script (you cannot know the current state without reading the UI),
        // which makes the menu impossible to drive deterministically in a test.
        function open(): string {
            ValkyxState.powerOpen = true
            return "open"
        }
        function close(): string {
            ValkyxState.powerOpen = false
            return "close"
        }
        // Which action the menu WOULD run if Return/Enter were pressed right now.
        // Lets a harness assert on the action without performing it.
        function armedAction(): string {
            return powerMenu.armedAction()
        }
    }

    // IPC: toggle settings window
    IpcHandler {
        target: "settings"
        function toggle(): string {
            ValkyxState.settingsOpen = !ValkyxState.settingsOpen
            return ValkyxState.settingsOpen ? "open" : "close"
        }
        function openKeyboard(): string {
            ValkyxState.settingsPage = 2
            ValkyxState.settingsOpen = true
            return "keyboard"
        }
    }

    // IPC: cycle theme (Super+Shift+T). Routes through ValkyxState so accent,
    // matching cursor, and the settings pickers all stay in sync.
    IpcHandler {
        target: "theme"
        function cycle(): string {
            return ValkyxState.cycleTheme()
        }
        function apply(name: string): string {
            ValkyxState.applyTheme(name)
            return name
        }
    }

    // IPC: toggle wallpaper/media selector (Super+W)
    IpcHandler {
        target: "wallpaper"
        function toggle(): string {
            ValkyxState.wallpaperOpen = !ValkyxState.wallpaperOpen
            return ValkyxState.wallpaperOpen ? "open" : "close"
        }
        function close(): string {
            ValkyxState.wallpaperOpen = false
            return "close"
        }
        // CI probe: assert the picker deck has no duplicate cards. Mirrors the
        // deck's full-path dedupe key (WallpaperStore), so distinct === total
        // means every card renders uniquely. Usage:
        //   qs -c valkyx ipc call wallpaper uniqueCards
        function uniqueCards(): string {
            const total = WallpaperStore.mediaList.length
            const seen = new Set()
            let dupes = []
            for (const m of WallpaperStore.mediaList) {
                if (seen.has(m.path)) dupes.push(m.path)
                else seen.add(m.path)
            }
            return JSON.stringify({ total: total, distinct: seen.size, duplicates: dupes })
        }
    }

    // IPC: the welcome card (Super+Shift+W).
    IpcHandler {
        target: "welcome"
        function toggle(): string {
            ValkyxState.welcomePanelOpen = !ValkyxState.welcomePanelOpen
            return ValkyxState.welcomePanelOpen ? "open" : "close"
        }
        function open(): string {
            ValkyxState.welcomePanelOpen = true
            return "open"
        }
        function close(): string {
            ValkyxState.welcomePanelOpen = false
            return "close"
        }
    }

    // TEST HOOK (valkyx-ui-test): deterministic runtime verification surface.
    // Reads the ACTUAL rendered highlight (lv.currentIndex via selectedName),
    // not launcher.current — so a frozen highlight from binding-destruction is
    // caught even though launcher.current still moves. Harmless in production.
    IpcHandler {
          target: "_test"
          function launcherSelection(): string {
              return launcherWindow ? launcherWindow.selectedName() : "none"
          }
          // Probes for the harness. Durations are DERIVED from motionScale, so
          // reading the token back is how a test proves reduced motion actually
          // reached the animation layer rather than just flipping a bool.
          function motion(): string {
              return "scale=" + ValkyxMotion.motionScale
                  + " pref=" + ValkyxState.motionPref
                  + " reduced=" + ValkyxState.reducedMotion
                  + " instant=" + ValkyxMotion.instant
                  + " ambient=" + ValkyxMotion.ambient
          }
          function setMotion(on: bool): string {
              ValkyxState.setMotion(on)
              return motion()
          }
          // Show the greeting. An optional argument pins how long it stays up,
          // because a 3400ms timer is impossible to photograph reliably — a
          // capture that misses the window proves nothing either way. One
          // argument, not two: the IPC bridge rejects a call whose argument
          // count is below the function's declared parameters, and it cannot
          // parse a default value either ("Type annotations are not supported"),
          // so a second parameter would break the documented one-argument
          // form. parseInt stops at the first non-digit, so the mode simply
          // rides along in the same string: "4000" or "4000 first".
          function greet(spec: string): string {
              const hold = parseInt(spec)
              // Preview only: sets the flag, never `greetedOnce`, so looking at
              // (or recording) the first run does not actually spend it.
              ValkyxState.firstGreeting = spec.indexOf("first") !== -1
              greetingLoader.pendingHold = (!isNaN(hold) && hold > 0) ? hold : 5000
              greetingLoader.active = true
              return "greet hold=" + greetingLoader.pendingHold + " first=" + ValkyxState.firstGreeting
          }
    }

    // Propagate persisted accent to the visual theme
    Connections {
        target: ValkyxState
        function onAccentChanged() { ValkyxTheme.accent = ValkyxState.accent }
    }

    // Global ESC — close any open panel (sidebar/settings/wallpaper picker) from anywhere.
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: ValkyxState.settingsOpen || ValkyxState.panelLeftOpen || ValkyxState.panelOpen || ValkyxState.wallpaperOpen || ValkyxState.welcomePanelOpen || ValkyxState.welcomeOpen || ValkyxState.passwordOpen
        onActivated: {
            if (ValkyxState.settingsOpen) ValkyxState.settingsOpen = false
            else if (ValkyxState.panelLeftOpen) ValkyxState.panelLeftOpen = false
            else if (ValkyxState.panelOpen) ValkyxState.panelOpen = false
            else if (ValkyxState.wallpaperOpen) ValkyxState.wallpaperOpen = false
            else if (ValkyxState.welcomePanelOpen) ValkyxState.welcomePanelOpen = false
            else if (ValkyxState.welcomeOpen) ValkyxState.welcomeOpen = false
              else if (ValkyxState.passwordOpen) passwordPrompt.cancel()
        }
    }
}
