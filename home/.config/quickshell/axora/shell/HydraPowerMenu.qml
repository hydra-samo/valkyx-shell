// AXORA Power Menu — floating row of 5 solid tiles, no wrapping plate.
// Built on the launcher's proven data path: ListView + ListModel + required
// roles. NOT Repeater (JS-array or otherwise) — this Qt build silently fails
// to create Repeater delegates, leaving the window transparent.
import Quickshell
import QtQuick
import "../core"

PanelWindow {
    id: power
    // `visible` follows the state, so a CLOSED menu has no surface at all.
    //
    // This line used to be `visible: true`, under a comment claiming that hiding
    // a layershell PanelWindow orphans its surface (`pid: -1`) and that it keeps
    // the seat's input grab. The orphan was real, but it came from SIGTERM:
    // killing `qs` with a bare `pkill` tore the surface down without tearing the
    // client down. `qs kill --pid` leaves 0 orphans, and that is what
    // `axora-shell-reload` uses. The conclusion drawn from it was wrong, and it
    // cost a dead input area across the whole shell.
    //
    // A mapped layershell surface KEEPS the pointer. Hyprland routes the event to
    // the topmost surface under the cursor and Qt drops it when no enabled item
    // wants it, so the click never reaches the client underneath. Fading the
    // content to 0 does not help: it is invisible but still mapped, and still
    // eats input. This panel sat mapped over the middle of the screen for the
    // whole session, which is why clicks and wheel events died in a 688x152
    // block dead centre. The `enabled`/`opacity` gate only ever made it inert
    // INSIDE Qt; it never got the surface out of the way.
    //
    // Six panels in this shell already work this way (launcher, settings, dock,
    // sidebar, osd, toast), as does the greeter via its Loader, all with 0
    // orphans. Follow the majority.
    // (PanelWindow has no `opacity` property — it is a QsQuick type, not a QML
    // Window — so the content Item is what gets faded.)
    visible: AxoraState.powerOpen
    focusable: AxoraState.powerOpen
    aboveWindows: true
    exclusiveZone: -1
    color: "transparent"

    property real winX: 0
    property real winY: 0
    property real panelW: 0
    property real panelH: 0

    // content-sized card: 5 tiles (120) + 4 gaps (12) + 2×20 padding
    function gear() {
        const sw = power.screen ? power.screen.width : 1366
        const sh = power.screen ? power.screen.height : 768
        panelW = 5 * 120 + 4 * 12 + 2 * 20
        panelH = 112 + 2 * 20
        winX = Math.max(4, Math.round((sw - panelW) / 2))
        winY = Math.max(4, Math.round(sh * 0.14))
    }
    onScreenChanged: gear()

    // gate on powerOpen, not on `visible` — visible is now permanently true.
    // An external property needs Connections; `onPowerOpenChanged:` is not a
    // valid handler on the PanelWindow itself.
    Connections {
        target: AxoraState
        function onPowerOpenChanged() {
            if (AxoraState.powerOpen) { power.gear(); power.focusPoll.start() }
            else { power.focusPoll.stop() }
        }
    }

    property Timer focusPoll: Timer {
        interval: 120; repeat: true
        onTriggered: {
            powerBody.forceActiveFocus()
            if (powerBody.activeFocus) stop()
        }
    }

    margins { left: power.winX; top: power.winY }
    implicitWidth: panelW
    implicitHeight: panelH

    // Read-only view of what Return/Enter would fire if the menu were open. The
    // harness asserts on this instead of pressing Return, which would suspend or
    // log the user out mid-test.
    function armedAction(): string {
        return powerBody.armedAction()
    }

    FocusScope {
        id: powerBody
        anchors.fill: parent
        // never hold focus while closed, or the Keys.* handlers below keep
        // swallowing Escape/arrows meant for whatever is underneath
        focus: AxoraState.powerOpen
        // `enabled` is not optional alongside opacity: Qt still delivers pointer
        // events to a mapped layershell item that is only invisible.
        enabled: AxoraState.powerOpen
        opacity: AxoraState.powerOpen ? 1 : 0

        Keys.onEscapePressed: AxoraState.powerOpen = false
        Keys.onLeftPressed: { move(-1); event.accepted = true }
        Keys.onRightPressed: { move(1); event.accepted = true }
        Keys.onReturnPressed: { activate(); event.accepted = true }
        Keys.onEnterPressed: { activate(); event.accepted = true }

        ListModel { id: powerBasicModel }

        Component.onCompleted: {
            powerBasicModel.append({ label: "Lock",     icon: "\uDB80\uDF3E", fn: "lock" })
            powerBasicModel.append({ label: "Logout",   icon: "\uDB80\uDF43", fn: "logout" })
            powerBasicModel.append({ label: "Suspend",  icon: "\uDB82\uDD04", fn: "suspend" })
            powerBasicModel.append({ label: "Reboot",   icon: "\uDB81\uDF09", fn: "reboot" })
            powerBasicModel.append({ label: "Shutdown", icon: "\uDB81\uDC25", fn: "shutdown" })
        }

        property int current: 0

        function move(dir: int) {
            current = (current + dir + powerBasicModel.count) % powerBasicModel.count
        }

        // ONE dispatch for the whole menu. It used to be duplicated verbatim in
        // activate() and in the delegate's onClicked, so every action had to be
        // fixed in two places — and `axora-logout` was missing from both, which
        // is why Logout did nothing. axora-power-action logs every attempt.
        //
        // Absolute path, NOT a barename: AxoraState.exec runs through
        // `sh -c` inheriting Hyprland's PATH (/usr/local/bin:/usr/bin), which
        // has no ~/.local/bin — a bare name is "not found" and the tile is
        // then a silent no-op again.
        function run(fn: string) {
            AxoraState.powerOpen = false
            AxoraState.exec(StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/axora-power-action " + fn)
        }

        function activate() {
            run(powerBasicModel.get(current).fn)
        }

        // Read-only view of what Return would fire. The harness asserts on this
        // instead of pressing Return, which would suspend or log the user out.
        function armedAction(): string {
            return powerBasicModel.count ? powerBasicModel.get(current).fn : "none"
        }

        ListView {
            id: powerList
            anchors.fill: parent
            orientation: Qt.Horizontal
            model: powerBasicModel
            interactive: false
            focus: AxoraState.powerOpen
            // an opacity-0 layershell surface still receives pointer events —
            // without this the closed menu would sit over the desktop eating
            // every click in its 688x152 rect
            enabled: AxoraState.powerOpen
            currentIndex: powerBody.current
            highlightFollowsCurrentItem: true

            delegate: Item {
                required property int index
                required property string label
                required property string icon
                required property string fn
                property bool hov: false
                readonly property bool activeCur: powerBody.current === index
                width: 120
                height: 112

                Rectangle {
                    anchors.fill: parent
                    radius: AxoraMetrics.rBtn
                    color: AxoraMaterials.surface2
                    border.color: (hov || activeCur) ? AxoraMaterials.borderActive : AxoraMaterials.borderFaint
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: icon
                            color: (hov || activeCur) ? AxoraTheme.accent : AxoraTheme.text
                            font.family: AxoraTheme.fontMono
                            font.pixelSize: Math.round(30 * AxoraState.fontScale)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: label
                            color: AxoraTheme.text
                            font.family: AxoraTheme.fontUI
                            font.pixelSize: Math.round(12 * AxoraState.fontScale)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: hov = true
                    onExited: hov = false
                    onClicked: powerBody.run(fn)
                }
            }
        }
    }
}