// SETTINGS: Display — resolution, scale, night light.
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

        Comp.ValkyxSection { label: "DISPLAY" }

        // resolution info
        Row { spacing: Core.ValkyxMetrics.m; height: 32
            Text { text: "Resolution"; color: Core.ValkyxTheme.muted; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Text { text: Screen.width + " × " + Screen.height; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }

        Row { spacing: Core.ValkyxMetrics.m; height: 32
            Text { text: "Refresh Rate"; color: Core.ValkyxTheme.muted; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Text { text: "60 Hz"; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontMono; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }

        // ── Night Light ──
        Comp.ValkyxSection { label: "NIGHT LIGHT"; topPadding: 12 }

        Row {
            spacing: Core.ValkyxMetrics.m; height: 36
            Text { text: "Night Light (3500K)"; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Comp.ValkyxToggle {
                checked: Core.ValkyxState.isOn("night")
                anchors.verticalCenter: parent.verticalCenter
                onToggled: Core.ValkyxState.toggleKey("night")
            }
        }

        // ── Scale ──
        Comp.ValkyxSection { label: "SCALE"; topPadding: 12 }

        Row {
            spacing: Core.ValkyxMetrics.s
            Repeater {
                model: ["100%", "125%", "150%", "200%"]
                Rectangle {
                    required property string modelData
                    required property int index
                    width: 60; height: 32; radius: 6
                    color: "transparent"
                    border.color: index === 0 ? Core.ValkyxTheme.tint(Core.ValkyxTheme.muted, "33") : Core.ValkyxMaterials.border
                    border.width: 1
                    Text { anchors.centerIn: parent; text: modelData; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(11 * Core.ValkyxState.fontScale) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { /* wlr-randr scale */ }
                    }
                }
            }
        }
    }
}
