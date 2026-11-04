// SETTINGS: Mouse — sensitivity, accel profile.
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

        Comp.HydraSection { label: "MOUSE" }

        // ── Sensitivity ──
        Comp.HydraSection { label: "SENSITIVITY"; topPadding: 8 }

        Row {
            spacing: Core.HydraMetrics.m; height: 32
            Text { text: "Speed"; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(12 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter; width: 80 }
            Rectangle {
                width: parent.parent.width - 120; height: 10; radius: 5
                color: Core.HydraTheme.tint(Core.HydraTheme.muted, "26")
                anchors.verticalCenter: parent.verticalCenter
                property real sensValue: 0.0
                Rectangle {
                    width: Math.max(parent.height, parent.parent.width * ((sensSlider.sensValue + 1) / 2)); height: parent.height; radius: parent.radius
                    color: Core.HydraTheme.accent
                    Behavior on width {
                        NumberAnimation { duration: Core.HydraMotion.fast; easing.type: Easing.OutCubic }
                    }
                }
                MouseArea {
                    id: sensSlider
                    anchors.centerIn: parent
                    width: parent.width; height: 26
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor
                    property real sensValue: 0.0
                    onPositionChanged: (mouse) => {
                        sensValue = (mouse.x / parent.width) * 2 - 1
                    }
                    onClicked: (mouse) => {
                        sensValue = (mouse.x / parent.width) * 2 - 1
                    }
                }
            }
            Text { text: "+1.0"; color: Core.HydraTheme.muted; font.pixelSize: Math.round(10 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }

        // ── Acceleration ──
        Comp.HydraSection { label: "ACCELERATION PROFILE"; topPadding: 12 }

        Row {
            spacing: Core.HydraMetrics.s
            Repeater {
                model: [
                    { label: "Flat", value: "flat" },
                    { label: "Adaptive", value: "adaptive" }
                ]
                Rectangle {
                    required property var modelData
                    required property int index
                    width: 90; height: 36; radius: 8
                    color: "transparent"
                    border.color: index === 0 ? Core.HydraTheme.tint(Core.HydraTheme.muted, "33") : Core.HydraMaterials.border
                    border.width: 1
                    Text { anchors.centerIn: parent; text: modelData.label; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(11 * Core.HydraState.fontScale) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Core.HydraState.exec("hyprctl eval 'hl.config({input = {accel_profile = \"" + modelData.value + "\"}})'")
                    }
                }
            }
        }

        // ── Natural Scrolling ──
        Comp.HydraSection { label: "OPTIONS"; topPadding: 12 }

        Row {
            spacing: Core.HydraMetrics.m; height: 36
            Text { text: "Natural Scrolling"; color: Core.HydraTheme.text; font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(12 * Core.HydraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Comp.HydraToggle {
                checked: false
                anchors.verticalCenter: parent.verticalCenter
                onToggled: Core.HydraState.exec("hyprctl eval 'hl.config({input = {natural_scroll = " + (checked ? "true" : "false") + "}})'")
            }
        }

        // ── Cursor ──
        Comp.HydraSection { label: "CURSOR"; topPadding: 12 }

        Row {
            spacing: 10
            Repeater {
                model: Core.HydraTheme.themeNames
                Column {
                    required property string modelData
                    property string curTheme: Core.HydraState.themeToCursor[modelData]
                    property bool active: Core.HydraState.cursorTheme === curTheme
                    spacing: 3
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 26; height: 26; radius: 13
                        color: Core.HydraTheme.themeByName(modelData).accent
                        border.color: active ? Core.HydraTheme.text : "transparent"
                        border.width: active ? 2 : 1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Core.HydraState.setCursor(curTheme, Core.HydraState.cursorSize)
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData
                        color: active ? Core.HydraTheme.accent : Core.HydraTheme.muted
                        font.family: Core.HydraTheme.fontUI; font.pixelSize: Math.round(8 * Core.HydraState.fontScale)
                    }
                }
            }
        }
    }
}
