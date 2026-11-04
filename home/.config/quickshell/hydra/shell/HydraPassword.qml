// VALKYX Password Prompt — masked single-field dialog.
//
// This replaces `fuzzel -d --password` and `zenity --password`. The GTK dialog was
// the last foreign surface left in the session: correct behaviour, wrong language.
// A launcher cannot do this job either — a launcher is search-and-select, a WiFi
// password is one masked field — so this is its own small surface rather than a
// launcher section.
//
// Structure follows ValkyxPowerMenu exactly, because that file encodes every rule
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

    visible: Core.ValkyxState.passwordOpen
    focusable: Core.ValkyxState.passwordOpen
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
        target: Core.ValkyxState
        function onPasswordOpenChanged() {
            if (Core.ValkyxState.passwordOpen) { pw.gear(); pw.focusTries = 0; pw.focusPoll.start() }
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
        command: [StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-pass-write", Core.ValkyxState.passwordTarget, pw.sent]
    }
    property string sent: ""

    function settle(value: string) {
        sent = value
        Core.ValkyxState.passwordOpen = false
        Core.ValkyxState.passwordText = ""
        writer.running = true
    }
    function submit() { settle(field.text) }
    function cancel() { settle(":") }

    FocusScope {
        id: body
        anchors.fill: parent
        focus: Core.ValkyxState.passwordOpen
        enabled: Core.ValkyxState.passwordOpen
        opacity: Core.ValkyxState.passwordOpen ? 1 : 0

        Keys.onEscapePressed: { pw.cancel(); event.accepted = true }
        Keys.onReturnPressed: { pw.submit(); event.accepted = true }
        Keys.onEnterPressed: { pw.submit(); event.accepted = true }

        Rectangle {
            anchors.fill: parent
            radius: Core.ValkyxMetrics.rPanel
            color: Core.ValkyxTheme.tint(Core.ValkyxTheme.surface, "mid")
            border.width: 1
            border.color: Core.ValkyxTheme.accent
        }

        Text {
            id: title
            x: Core.ValkyxMetrics.xl
            y: Core.ValkyxMetrics.l
            color: Core.ValkyxTheme.text
            font.family: Core.ValkyxTheme.fontUI
            font.pixelSize: Core.ValkyxMetrics.fsLg
            font.weight: Font.DemiBold
            text: Core.ValkyxState.passwordLabel.length > 0 ? Core.ValkyxState.passwordLabel : "Password"
        }

        // Masked field. `echoMode: TextInput.Password` is the whole reason this
        // surface exists — nothing in the launcher can express it.
        Rectangle {
            id: box
            x: Core.ValkyxMetrics.xl
            y: title.y + title.height + Core.ValkyxMetrics.l
            width: parent.width - Core.ValkyxMetrics.xl * 2
            height: 38
            radius: Core.ValkyxMetrics.rBtn
            color: Core.ValkyxTheme.tint(Core.ValkyxTheme.bg, "rest")
            border.width: 1
            border.color: field.activeFocus ? Core.ValkyxTheme.accent : Core.ValkyxTheme.line

            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: Core.ValkyxMetrics.l
                anchors.rightMargin: Core.ValkyxMetrics.l
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                passwordMaskDelay: 0
                color: Core.ValkyxTheme.text
                font.family: Core.ValkyxTheme.fontUI
                font.pixelSize: Core.ValkyxMetrics.fsMd
                selectByMouse: true
                clip: true
                onAccepted: pw.submit()
            }
        }

        Row {
            x: parent.width - Core.ValkyxMetrics.xl - cancel.width - Core.ValkyxMetrics.s - ok.width
            y: box.y + box.height + Core.ValkyxMetrics.l
            spacing: Core.ValkyxMetrics.s

            Rectangle {
                id: cancel
                width: 84; height: 30
                radius: Core.ValkyxMetrics.rBtn
                color: "transparent"
                border.width: 1
                border.color: Core.ValkyxTheme.line
                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Core.ValkyxTheme.muted
                    font.family: Core.ValkyxTheme.fontUI
                    font.pixelSize: Core.ValkyxMetrics.fsSm
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
                radius: Core.ValkyxMetrics.rBtn
                color: Core.ValkyxTheme.accent
                Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    color: Core.ValkyxTheme.bg
                    font.family: Core.ValkyxTheme.fontUI
                    font.pixelSize: Core.ValkyxMetrics.fsSm
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
