// HYDRA Password Prompt — masked single-field dialog.
//
// This replaces `fuzzel -d --password` and `zenity --password`. The GTK dialog was
// the last foreign surface left in the session: correct behaviour, wrong language.
// A launcher cannot do this job either — a launcher is search-and-select, a WiFi
// password is one masked field — so this is its own small surface rather than a
// launcher section.
//
// Structure follows HydraPowerMenu exactly, because that file encodes every rule
// this compositor needs:
//   visible stays `true` forever (a `visible:false` layershell window gets ORPHANED
//   by Hyprland as `pid: -1` and keeps holding the seat input grab),
//   the content is one FocusScope gated on opacity AND enabled (Qt still delivers
//   pointer events to a merely-invisible mapped item),
//   PanelWindow has no `opacity` of its own, so the card is what fades.
import Quickshell
import Quickshell.Io
import QtQuick
import "../core" as Core

PanelWindow {
    id: pw

    visible: Core.HydraState.passwordOpen
    focusable: Core.HydraState.passwordOpen
    aboveWindows: true
    exclusiveZone: -1
    color: "transparent"

    property real winX: 0
    property real winY: 0
    property real panelW: 360
    property real panelH: 172

    function gear() {
        const sw = pw.screen ? pw.screen.width : 1366
        const sh = pw.screen ? pw.screen.height : 768
        winX = Math.max(4, Math.round((sw - panelW) / 2))
        winY = Math.max(4, Math.round(sh * 0.34))
    }
    onScreenChanged: gear()

    Connections {
        target: Core.HydraState
        function onPasswordOpenChanged() {
            if (Core.HydraState.passwordOpen) { pw.gear(); pw.focusTries = 0; pw.focusPoll.start() }
            else { pw.focusPoll.stop() }
        }
    }

    // Focus only lands once the surface is actually mapped, so poll briefly.
    // `field` is nested inside the gate, so it resolves by id, not as `pw.field`.
    // Bounded: a lost focus race must not leave this spinning forever.
    property int focusTries: 0
    property Timer focusPoll: Timer {
        interval: 120; repeat: true
        onTriggered: {
            field.forceActiveFocus()
            if (field.activeFocus || ++pw.focusTries > 25) stop()
        }
    }

    margins { left: pw.winX; top: pw.winY }
    implicitWidth: panelW
    implicitHeight: panelH

    // Write the result for the waiting script. `:` is the cancel sentinel, so the
    // caller returns immediately instead of blocking for its full timeout.
    //
    // The value goes through a helper's ARGV, never through a shell command line:
    // interpolating a password into `sh -c` would both break on quotes and expose
    // it in `ps` for as long as the process lived.
    Process {
        id: writer
        running: false
        command: [StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/hydra-pass-write", Core.HydraState.passwordTarget, pw.sent]
    }
    property string sent: ""

    function settle(value: string) {
        sent = value
        Core.HydraState.passwordOpen = false
        Core.HydraState.passwordText = ""
        writer.running = true
    }
    function submit() { settle(field.text) }
    function cancel() { settle(":") }

    FocusScope {
        id: body
        anchors.fill: parent
        focus: Core.HydraState.passwordOpen
        enabled: Core.HydraState.passwordOpen
        opacity: Core.HydraState.passwordOpen ? 1 : 0

        Keys.onEscapePressed: { pw.cancel(); event.accepted = true }
        Keys.onReturnPressed: { pw.submit(); event.accepted = true }
        Keys.onEnterPressed: { pw.submit(); event.accepted = true }

        Rectangle {
            anchors.fill: parent
            radius: Core.HydraMetrics.rPanel
            color: Core.HydraTheme.tint(Core.HydraTheme.surface, "mid")
            border.width: 1
            border.color: Core.HydraTheme.accent
        }

        Text {
            id: title
            x: Core.HydraMetrics.xl
            y: Core.HydraMetrics.l
            color: Core.HydraTheme.text
            font.family: Core.HydraTheme.fontUI
            font.pixelSize: Core.HydraMetrics.fsLg
            font.weight: Font.DemiBold
            text: Core.HydraState.passwordLabel.length > 0 ? Core.HydraState.passwordLabel : "Password"
        }

        // Masked field. `echoMode: TextInput.Password` is the whole reason this
        // surface exists — nothing in the launcher can express it.
        Rectangle {
            id: box
            x: Core.HydraMetrics.xl
            y: title.y + title.height + Core.HydraMetrics.l
            width: parent.width - Core.HydraMetrics.xl * 2
            height: 38
            radius: Core.HydraMetrics.rBtn
            color: Core.HydraTheme.tint(Core.HydraTheme.bg, "rest")
            border.width: 1
            border.color: field.activeFocus ? Core.HydraTheme.accent : Core.HydraTheme.line

            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: Core.HydraMetrics.l
                anchors.rightMargin: Core.HydraMetrics.l
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                passwordMaskDelay: 0
                color: Core.HydraTheme.text
                font.family: Core.HydraTheme.fontUI
                font.pixelSize: Core.HydraMetrics.fsMd
                selectByMouse: true
                clip: true
                onAccepted: pw.submit()
            }
        }

        Row {
            x: parent.width - Core.HydraMetrics.xl - cancel.width - Core.HydraMetrics.s - ok.width
            y: box.y + box.height + Core.HydraMetrics.l
            spacing: Core.HydraMetrics.s

            Rectangle {
                id: cancel
                width: 84; height: 30
                radius: Core.HydraMetrics.rBtn
                color: "transparent"
                border.width: 1
                border.color: Core.HydraTheme.line
                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Core.HydraTheme.muted
                    font.family: Core.HydraTheme.fontUI
                    font.pixelSize: Core.HydraMetrics.fsSm
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pw.cancel()
                }
            }

            Rectangle {
                id: ok
                width: 96; height: 30
                radius: Core.HydraMetrics.rBtn
                color: Core.HydraTheme.accent
                Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    color: Core.HydraTheme.bg
                    font.family: Core.HydraTheme.fontUI
                    font.pixelSize: Core.HydraMetrics.fsSm
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pw.submit()
                }
            }
        }
    }
}
