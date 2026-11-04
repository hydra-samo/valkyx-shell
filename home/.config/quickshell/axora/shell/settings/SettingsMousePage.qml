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
        spacing: Core.AxoraMetrics.l

        Comp.AxoraSection { label: "MOUSE" }

        // ── Sensitivity ──
        Comp.AxoraSection { label: "SENSITIVITY"; topPadding: 8 }

        Row {
            spacing: Core.AxoraMetrics.m; height: 32
            Text { text: "Speed"; color: Core.AxoraTheme.text; font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(12 * Core.AxoraState.fontScale); anchors.verticalCenter: parent.verticalCenter; width: 80 }
            Rectangle {
                width: parent.parent.width - 120; height: 10; radius: 5
                color: Core.AxoraTheme.tint(Core.AxoraTheme.muted, "26")
                anchors.verticalCenter: parent.verticalCenter
                property real sensValue: 0.0
                Rectangle {
                    width: Math.max(parent.height, parent.parent.width * ((sensSlider.sensValue + 1) / 2)); height: parent.height; radius: parent.radius
                    color: Core.AxoraTheme.accent
                    Behavior on width {
                        NumberAnimation { duration: Core.AxoraMotion.fast; easing.type: Easing.OutCubic }
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
            Text { text: "+1.0"; color: Core.AxoraTheme.muted; font.pixelSize: Math.round(10 * Core.AxoraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }

        // ── Acceleration ──
        Comp.AxoraSection { label: "ACCELERATION PROFILE"; topPadding: 12 }

        Row {
            spacing: Core.AxoraMetrics.s
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
                    border.color: index === 0 ? Core.AxoraTheme.tint(Core.AxoraTheme.muted, "33") : Core.AxoraMaterials.border
                    border.width: 1
                    Text { anchors.centerIn: parent; text: modelData.label; color: Core.AxoraTheme.text; font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(11 * Core.AxoraState.fontScale) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Core.AxoraState.exec("hyprctl eval 'hl.config({input = {accel_profile = \"" + modelData.value + "\"}})'")
                    }
                }
            }
        }

        // ── Natural Scrolling ──
        Comp.AxoraSection { label: "OPTIONS"; topPadding: 12 }

        Row {
            spacing: Core.AxoraMetrics.m; height: 36
            Text { text: "Natural Scrolling"; color: Core.AxoraTheme.text; font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(12 * Core.AxoraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Comp.AxoraToggle {
                checked: false
                anchors.verticalCenter: parent.verticalCenter
                onToggled: Core.AxoraState.exec("hyprctl eval 'hl.config({input = {natural_scroll = " + (checked ? "true" : "false") + "}})'")
            }
        }

        // ── Cursor ──
        Comp.AxoraSection { label: "CURSOR"; topPadding: 12 }

        Row {
            spacing: 10
            Repeater {
                model: Core.AxoraTheme.themeNames
                Column {
                    required property string modelData
                    property string curTheme: Core.AxoraState.themeToCursor[modelData]
                    property bool active: Core.AxoraState.cursorTheme === curTheme
                    spacing: 3
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 26; height: 26; radius: 13
                        color: Core.AxoraTheme.themeByName(modelData).accent
                        border.color: active ? Core.AxoraTheme.text : "transparent"
                        border.width: active ? 2 : 1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Core.AxoraState.setCursor(curTheme, Core.AxoraState.cursorSize)
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData
                        color: active ? Core.AxoraTheme.accent : Core.AxoraTheme.muted
                        font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(8 * Core.AxoraState.fontScale)
                    }
                }
            }
        }
    }
}
