// SETTINGS: Session — power buttons (rounded rect tiles).
import QtQuick
import "../../core" as Core
import "../../core/components" as Comp

Flickable {
    contentHeight: col.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        width: parent.width
        spacing: Core.ValkyxMetrics.l

        Text { text: "SESSION"; color: Core.ValkyxTheme.accent; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale); font.letterSpacing: 1 }

        // ── System info ──
        Rectangle {
            width: parent.width; height: 80; radius: 10
            color: "transparent"
            border.color: Core.ValkyxMaterials.border; border.width: 1
            Column {
                anchors.fill: parent; anchors.margins: 12; spacing: 4
                Row { spacing: Core.ValkyxMetrics.m
                    Image { source: "file://StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/valkyx/data/valkyx-mark_v4_white.svg""; width: Math.round(40 * Core.ValkyxState.fontScale); height: Math.round(40 * Core.ValkyxState.fontScale); smooth: true; sourceSize: Qt.size(Math.round(40 * Core.ValkyxState.fontScale), Math.round(40 * Core.ValkyxState.fontScale)) }
                    Column {
                        Text { text: "VALKYX LABS"; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(14 * Core.ValkyxState.fontScale); font.bold: true }
                        Text { text: "Hyprland 0.56 · VALKYX-S"; color: Core.ValkyxTheme.muted; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale) }
                    }
                }
                Row { spacing: Core.ValkyxMetrics.xl
                    Row { spacing: 4
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: batStatTxt.implicitHeight; height: batStatTxt.implicitHeight
                            Text { id: batStatTxt; anchors.centerIn: parent; rotation: 90; text: "\uDB80\uDC79"; color: Core.ValkyxTheme.muted; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale) }
                        }
                        Text { text: Math.round(Core.ValkyxState.batteryPct) + "%"; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale) }
                    }
                    Row { spacing: 4
                        Text { text: "\uDB81\uDDA9"; color: Core.ValkyxTheme.muted; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale) }
                        Text { text: Core.ValkyxState.netLine; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale) }
                    }
                }
            }
        }

        // ── Greeting ──
        // The same property the welcome window's switch writes, so the two
        // can never show opposite states. Which of them the user touches is
        // irrelevant; there is one flag and it persists.
        Text { text: "GREETING"; color: Core.ValkyxTheme.accent; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale); font.letterSpacing: 1; topPadding: 8 }

        Rectangle {
            width: parent.width; height: 36; radius: 8
            color: "transparent"
            border.color: Core.ValkyxMaterials.border; border.width: 1
            // Anchored to the two edges, NOT a Row: a Row owns its children's
            // geometry and a toggle inside one cannot be pushed to the right
            // edge without a spacer hack (and `anchors.verticalCenter` inside a
            // positioner is itself a QML warning).
            Row {
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text {
                    text: "Greet me on startup"; color: Core.ValkyxTheme.text
                    font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale)
                }
                Text {
                    // "first run" only means anything until it has happened once,
                    // and that fact is what picks the greeting's wording.
                    text: Core.ValkyxState.greetedOnce ? "hello, again" : "first run"
                    color: Core.ValkyxTheme.muted
                    font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale)
                }
            }
            Comp.ValkyxToggle {
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                checked: Core.ValkyxState.greetingEnabled
                // Writes the state, not this switch's own `checked`, which would
                // break the binding above and leave it painted the wrong way.
                // onGreetingEnabledChanged persists it.
                onToggled: Core.ValkyxState.greetingEnabled = checked
            }
        }

        // ── Power buttons ──
        Text { text: "POWER"; color: Core.ValkyxTheme.accent; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale); font.letterSpacing: 1 }

        Grid {
            columns: 2; spacing: 12; width: parent.width
            Repeater {
                model: [
                    { icon: "\uDB80\uDF3E", label: "Lock",    cmd: "valkyx-lock",              color: Core.ValkyxTheme.muted },
                    { icon: "\uDB80\uDF43", label: "Logout",  cmd: "valkyx-power-action logout", color: Core.ValkyxTheme.muted },
                    { icon: "\uDB81\uDF09", label: "Reboot",  cmd: "systemctl reboot",       color: Core.ValkyxTheme.muted },
                    { icon: "\uDB81\uDC25", label: "Shutdown", cmd: "systemctl poweroff",    color: Core.ValkyxTheme.danger }
                ]
                Rectangle {
                    required property var modelData
                    width: (col.width - 12) / 2; height: 64; radius: 12
                    color: "transparent"
                    border.color: Core.ValkyxMaterials.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Core.ValkyxMotion.fast } }

                    Row {
                        anchors.centerIn: parent; spacing: 10
                        Text { text: modelData.icon; color: pwrH.containsMouse ? modelData.color : Core.ValkyxTheme.muted; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(18 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.label; color: pwrH.containsMouse ? modelData.color : Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(13 * Core.ValkyxState.fontScale); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }

                    MouseArea {
                        id: pwrH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Core.ValkyxState.exec(modelData.cmd)
                    }
                }
            }
        }

        // ── Battery ──
        Text { text: "BATTERY"; color: Core.ValkyxTheme.accent; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale); font.letterSpacing: 1; topPadding: 8 }

        Rectangle {
            width: parent.width; height: 36; radius: 8
            color: "transparent"
            border.color: Core.ValkyxMaterials.border; border.width: 1
            Row {
                anchors.fill: parent; anchors.margins: 8; spacing: 8
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: batBarTxt.implicitHeight; height: batBarTxt.implicitHeight
                    Text { id: batBarTxt; anchors.centerIn: parent; rotation: 90; text: "\uDB80\uDC7E"; color: Core.ValkyxTheme.muted; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(14 * Core.ValkyxState.fontScale) }
                }
                Rectangle {
                    width: parent.parent.width - 92; height: 8; radius: 4
                    color: Core.ValkyxTheme.tint(Core.ValkyxTheme.muted, "26")
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, Core.ValkyxState.batteryPct / 100)); height: parent.height; radius: parent.radius
                        color: Core.ValkyxState.batteryPct < 20 ? Core.ValkyxTheme.danger : Core.ValkyxTheme.accent
                    }
                }
                Text { text: Math.round(Core.ValkyxState.batteryPct) + "%"; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(11 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
