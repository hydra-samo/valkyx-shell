//@ pragma UseQApplication
// hydra-holo — REAL resizable assistant window as a second Quickshell config.
// Run: qs -p ~/.config/quickshell/hydra-holo  (or qs -c hydra-holo).
// Shares UI + singletons with the main shell via symlinks:
//   hydra-holo/shell -> ../hydra/shell, hydra-holo/core -> ../hydra/core
// so HoloShell.HydraAssistantUi's own `import "../core"` resolves to hydra/core
// (via hydra-holo/core) with zero copies. Do NOT copy files here — the symlinks
// ARE the mechanism.
// NOTE: when both this window and the main shell are up, two Api pollers run
// (1Hz + 250ms each). Acceptable; the endpoint is read-only and cheap.
import QtQuick
import QtQuick.Window
import "./core"
import "./shell" as HoloShell

Window {
    id: win
    visible: true
    // Boots fullscreen (tapes' hologram wall); the chrome toggle drops to a
    // normal floating window and back. Hyprland rules still float it.
    visibility: Window.FullScreen
    width: 1200
    height: 690
    minimumWidth: 800
    minimumHeight: 500
    title: "HYDRA Assistant"
    // Dialog flag: Hyprland floats dialogs by default, so the window opens as
    // a real centered floating window instead of tiling fullscreen. Still a
    // normal resizable toplevel (min/max/close from compositor).
    flags: Qt.Dialog
    color: "transparent" // glass draws its own bg; window chrome from compositor
    HoloShell.HydraAssistantUi {
        anchors.fill: parent
        // In window mode the window IS the open state; closing quits the process.
        uiOpen: true
        isFullscreen: win.visibility === Window.FullScreen
        onCloseRequested: Qt.quit()
        onWindowModeRequested: win.visibility = win.visibility === Window.FullScreen
            ? Window.Windowed : Window.FullScreen
    }

    // Cross-process theme/font/motion sync: this window is a second process
    // with its own singletons, so a theme picked in the main shell would
    // otherwise never arrive here. Re-read the persisted state (read-only,
    // cheap cat) — restore path applies theme + surfaces, never writes.
    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: HydraState.loadPersisted()
    }
}
