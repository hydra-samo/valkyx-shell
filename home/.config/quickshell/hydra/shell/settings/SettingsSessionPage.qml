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
        spacing: Core.HydraMetrics.l

        Text { text: "SESSION"; color: Core.HydraTheme.accent; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(10 * Core.HydraState.fontScale); font.letterSpacing: 1 }

        // ── System info ──
        Rectangle {
            width: parent.width; height: 80; radius: 10
            color: "transparent"
            border.color: Core.HydraMaterials.border; border.width: 1
            Column {
                anchors.fill: parent; anchors.margins: 12; spacing: 4
                Row { spacing: Core.HydraMetrics.m
                    Image { source: "file://StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/hydra/data/hydra-mark_v4_white.svg""; width: Math.round(40 * Core.HydraState.fontScale); height: Math.round(40 * Core.HydraState.fontScale); smooth: true; sourceSize: Qt.size(Math.round(40 * Core.HydraState.fontScale), Math.round(40 * Core.HydraState.fontScale)) }
                    Column {
                        Text { text: "HYDRA LABS"; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(14 * Core.HydraState.fontScale); font.bold: true }
                        Text { text: "Hyprland 0.56 · HYDRA-S"; color: Core.HydraTheme.muted; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(10 * Core.HydraState.fontScale) }
                    }
                }
                Row { spacing: Core.HydraMetrics.xl
                    Row { spacing: 4
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: batStatTxt.implicitHeight; height: batStatTxt.implicitHeight
                            Text { id: batStatTxt; anchors.centerIn: parent; rotation: 90; text: "\uDB80\uDC79"; color: Core.HydraTheme.muted; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(10 * Core.HydraState.fontScale) }
                        }
                        Text { text: Math.round(Core.HydraState.batteryPct) + "%"; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(10 * Core.HydraState.fontScale) }
                    }
                    Row { spacing: 4
                        Text { text: "\uDB81\uDDA9"; color: Core.HydraTheme.muted; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(10 * Core.HydraState.fontScale) }
                        Text { text: Core.HydraState.netLine; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(10 * Core.HydraState.fontScale) }
                    }
                }
            }
        }

        // ── Greeting ──
        // The same property the welcome window's switch writes, so the two
        // can never show opposite states. Which of them the user touches is
        // irrelevant; there is one flag and it persists.
        Text { text: "GREETING"; color: Core.HydraTheme.accent; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(10 * Core.HydraState.fontScale); font.letterSpacing: 1; topPadding: 8 }

        Rectangle {
            width: parent.width; height: 36; radius: 8
            color: "transparent"
            border.color: Core.HydraMaterials.border; border.width: 1
            // Anchored to the two edges, NOT a Row: a Row owns its children's
            // geometry and a toggle inside one cannot be pushed to the right
            // edge without a spacer hack (and `anchors.verticalCenter` inside a
            // positioner is itself a QML warning).
            Row {
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text {
                    text: "Greet me on startup"; color: Core.HydraTheme.text
                    font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(12 * Core.HydraState.fontScale)
                }
                Text {
                    // "first run" only means anything until it has happened once,
                    // and that fact is what picks the greeting's wording.
                    text: Core.HydraState.greetedOnce ? "hello, again" : "first run"
                    color: Core.HydraTheme.muted
                    font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(10 * Core.HydraState.fontScale)
                }
            }
            Comp.HydraToggle {
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                checked: Core.HydraState.greetingEnabled
                // Writes the state, not this switch's own `checked`, which would
                // break the binding above and leave it painted the wrong way.
                // onGreetingEnabledChanged persists it.
                onToggled: Core.HydraState.greetingEnabled = checked
            }
        }

        // ── Power buttons ──
        Text { text: "POWER"; color: Core.HydraTheme.accent; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(10 * Core.HydraState.fontScale); font.letterSpacing: 1 }

        Grid {
            columns: 2; spacing: 12; width: parent.width
            Repeater {
                model: [
                    { icon: "\uDB80\uDF3E", label: "Lock",    cmd: "hydra-lock",              color: Core.HydraTheme.muted },
                    { icon: "\uDB80\uDF43", label: "Logout",  cmd: "hydra-power-action logout", color: Core.HydraTheme.muted },
                    { icon: "\uDB81\uDF09", label: "Reboot",  cmd: "systemctl reboot",       color: Core.HydraTheme.muted },
                    { icon: "\uDB81\uDC25", label: "Shutdown", cmd: "systemctl poweroff",    color: Core.HydraTheme.danger }
                ]
                Rectangle {
                    required property var modelData
                    width: (col.width - 12) / 2; height: 64; radius: 12
                    color: "transparent"
                    border.color: Core.HydraMaterials.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Core.HydraMotion.fast } }

                    Row {
                        anchors.centerIn: parent; spacing: 10
                        Text { text: modelData.icon; color: pwrH.containsMouse ? modelData.color : Core.HydraTheme.muted; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(18 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.label; color: pwrH.containsMouse ? modelData.color : Core.HydraTheme.text; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(13 * Core.HydraState.fontScale); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }

                    MouseArea {
                        id: pwrH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Core.HydraState.exec(modelData.cmd)
                    }
                }
            }
        }

        // ── Battery ──
        Text { text: "BATTERY"; color: Core.HydraTheme.accent; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(10 * Core.HydraState.fontScale); font.letterSpacing: 1; topPadding: 8 }

        Rectangle {
            width: parent.width; height: 36; radius: 8
            color: "transparent"
            border.color: Core.HydraMaterials.border; border.width: 1
            Row {
                anchors.fill: parent; anchors.margins: 8; spacing: 8
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: batBarTxt.implicitHeight; height: batBarTxt.implicitHeight
                    Text { id: batBarTxt; anchors.centerIn: parent; rotation: 90; text: "\uDB80\uDC7E"; color: Core.HydraTheme.muted; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(14 * Core.HydraState.fontScale) }
                }
                Rectangle {
                    width: parent.parent.width - 92; height: 8; radius: 4
                    color: Core.HydraTheme.tint(Core.HydraTheme.muted, "26")
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, Core.HydraState.batteryPct / 100)); height: parent.height; radius: parent.radius
                        color: Core.HydraState.batteryPct < 20 ? Core.HydraTheme.danger : Core.HydraTheme.accent
                    }
                }
                Text { text: Math.round(Core.HydraState.batteryPct) + "%"; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(11 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
