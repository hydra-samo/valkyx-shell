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
        spacing: Core.HydraMetrics.l

        Comp.HydraSection { label: "DISPLAY" }

        // resolution info
        Row { spacing: Core.HydraMetrics.m; height: 32
            Text { text: "Resolution"; color: Core.HydraTheme.muted; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(12 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Text { text: Screen.width + " × " + Screen.height; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(12 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }

        Row { spacing: Core.HydraMetrics.m; height: 32
            Text { text: "Refresh Rate"; color: Core.HydraTheme.muted; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(12 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Text { text: "60 Hz"; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(12 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }

        // ── Night Light ──
        Comp.HydraSection { label: "NIGHT LIGHT"; topPadding: 12 }

        Row {
            spacing: Core.HydraMetrics.m; height: 36
            Text { text: "Night Light (3500K)"; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(12 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Comp.HydraToggle {
                checked: Core.HydraState.isOn("night")
                anchors.verticalCenter: parent.verticalCenter
                onToggled: Core.HydraState.toggleKey("night")
            }
        }

        // ── Scale ──
        Comp.HydraSection { label: "SCALE"; topPadding: 12 }

        Row {
            spacing: Core.HydraMetrics.s
            Repeater {
                model: ["100%", "125%", "150%", "200%"]
                Rectangle {
                    required property string modelData
                    required property int index
                    width: 60; height: 32; radius: 6
                    color: "transparent"
                    border.color: index === 0 ? Core.HydraTheme.tint(Core.HydraTheme.muted, "33") : Core.HydraMaterials.border
                    border.width: 1
                    Text { anchors.centerIn: parent; text: modelData; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(11 * Core.HydraState.fontScale) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { /* wlr-randr scale */ }
                    }
                }
            }
        }
    }
}
