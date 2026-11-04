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
        spacing: Core.ValkyxMetrics.l

        Comp.ValkyxSection { label: "MOUSE" }

        // ── Sensitivity ──
        Comp.ValkyxSection { label: "SENSITIVITY"; topPadding: 8 }

        Row {
            spacing: Core.ValkyxMetrics.m; height: 32
            Text { text: "Speed"; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter; width: 80 }
            Rectangle {
                width: parent.parent.width - 120; height: 10; radius: 5
                color: Core.ValkyxTheme.tint(Core.ValkyxTheme.muted, "26")
                anchors.verticalCenter: parent.verticalCenter
                property real sensValue: 0.0
                Rectangle {
                    width: Math.max(parent.height, parent.parent.width * ((sensSlider.sensValue + 1) / 2)); height: parent.height; radius: parent.radius
                    color: Core.ValkyxTheme.accent
                    Behavior on width {
                        NumberAnimation { duration: Core.ValkyxMotion.fast; easing.type: Easing.OutCubic }
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
            Text { text: "+1.0"; color: Core.ValkyxTheme.muted; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }

        // ── Acceleration ──
        Comp.ValkyxSection { label: "ACCELERATION PROFILE"; topPadding: 12 }

        Row {
            spacing: Core.ValkyxMetrics.s
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
                    border.color: index === 0 ? Core.ValkyxTheme.tint(Core.ValkyxTheme.muted, "33") : Core.ValkyxMaterials.border
                    border.width: 1
                    Text { anchors.centerIn: parent; text: modelData.label; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(11 * Core.ValkyxState.fontScale) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Core.ValkyxState.exec("hyprctl eval 'hl.config({input = {accel_profile = \"" + modelData.value + "\"}})'")
                    }
                }
            }
        }

        // ── Natural Scrolling ──
        Comp.ValkyxSection { label: "OPTIONS"; topPadding: 12 }

        Row {
            spacing: Core.ValkyxMetrics.m; height: 36
            Text { text: "Natural Scrolling"; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Comp.ValkyxToggle {
                checked: false
                anchors.verticalCenter: parent.verticalCenter
                onToggled: Core.ValkyxState.exec("hyprctl eval 'hl.config({input = {natural_scroll = " + (checked ? "true" : "false") + "}})'")
            }
        }

        // ── Cursor ──
        Comp.ValkyxSection { label: "CURSOR"; topPadding: 12 }

        Row {
            spacing: 10
            Repeater {
                model: Core.ValkyxTheme.themeNames
                Column {
                    required property string modelData
                    property string curTheme: Core.ValkyxState.themeToCursor[modelData]
                    property bool active: Core.ValkyxState.cursorTheme === curTheme
                    spacing: 3
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 26; height: 26; radius: 13
                        color: Core.ValkyxTheme.themeByName(modelData).accent
                        border.color: active ? Core.ValkyxTheme.text : "transparent"
                        border.width: active ? 2 : 1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Core.ValkyxState.setCursor(curTheme, Core.ValkyxState.cursorSize)
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData
                        color: active ? Core.ValkyxTheme.accent : Core.ValkyxTheme.muted
                        font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * Core.ValkyxState.fontScale)
                    }
                }
            }
        }
    }
}
