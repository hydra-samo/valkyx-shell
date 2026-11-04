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
        spacing: Core.AxoraMetrics.l

        Comp.AxoraSection { label: "DISPLAY" }

        // resolution info
        Row { spacing: Core.AxoraMetrics.m; height: 32
            Text { text: "Resolution"; color: Core.AxoraTheme.muted; font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(12 * Core.AxoraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Text { text: Screen.width + " × " + Screen.height; color: Core.AxoraTheme.text; font.family: Core.AxoraTheme.fontMono; font.pixelSize: Math.round(12 * Core.AxoraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }

        Row { spacing: Core.AxoraMetrics.m; height: 32
            Text { text: "Refresh Rate"; color: Core.AxoraTheme.muted; font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(12 * Core.AxoraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Text { text: "60 Hz"; color: Core.AxoraTheme.text; font.family: Core.AxoraTheme.fontMono; font.pixelSize: Math.round(12 * Core.AxoraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }

        // ── Night Light ──
        Comp.AxoraSection { label: "NIGHT LIGHT"; topPadding: 12 }

        Row {
            spacing: Core.AxoraMetrics.m; height: 36
            Text { text: "Night Light (3500K)"; color: Core.AxoraTheme.text; font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(12 * Core.AxoraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Comp.AxoraToggle {
                checked: Core.AxoraState.isOn("night")
                anchors.verticalCenter: parent.verticalCenter
                onToggled: Core.AxoraState.toggleKey("night")
            }
        }

        // ── Scale ──
        Comp.AxoraSection { label: "SCALE"; topPadding: 12 }

        Row {
            spacing: Core.AxoraMetrics.s
            Repeater {
                model: ["100%", "125%", "150%", "200%"]
                Rectangle {
                    required property string modelData
                    required property int index
                    width: 60; height: 32; radius: 6
                    color: "transparent"
                    border.color: index === 0 ? Core.AxoraTheme.tint(Core.AxoraTheme.muted, "33") : Core.AxoraMaterials.border
                    border.width: 1
                    Text { anchors.centerIn: parent; text: modelData; color: Core.AxoraTheme.text; font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(11 * Core.AxoraState.fontScale) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { /* wlr-randr scale */ }
                    }
                }
            }
        }
    }
}
