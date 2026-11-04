// SETTINGS: Keyboard — keybind reference + editable.
import QtQuick
import "../../core" as Core

Flickable {
    contentHeight: col.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        width: parent.width
        spacing: Core.AxoraMetrics.m

        Text { text: "KEYBOARD SHORTCUTS"; color: Core.AxoraTheme.accent; font.family: Core.AxoraTheme.fontMono; font.pixelSize: Math.round(10 * Core.AxoraState.fontScale); font.letterSpacing: 1; bottomPadding: 4 }

        Repeater {
            model: [
                { header: true, cat: "Session" },
                { key: "Super+Return", desc: "Terminal" },
                { key: "Super+B", desc: "Browser" },
                { key: "Super+E", desc: "Files" },
                { key: "Super+C", desc: "Editor" },
                { key: "Super+Space", desc: "Launcher" },
                { key: "Super+S", desc: "Sidebar" },
                { key: "Super+I", desc: "Settings" },
                { key: "Super+N", desc: "Network" },
                { key: "Super+X", desc: "Power menu" },
                { key: "Super+P", desc: "Projects" },
                { header: true, cat: "Windows" },
                { key: "Super+Q", desc: "Close" },
                { key: "Super+F", desc: "Fullscreen" },
                { key: "Super+T", desc: "Float" },
                { key: "Super+G", desc: "Toggle split" },
                { header: true, cat: "Navigation" },
                { key: "Super+H/J/K/L", desc: "Move focus" },
                { key: "Super+Shift+H/J/K/L", desc: "Move window" },
                { key: "Alt+Tab", desc: "Cycle windows" },
                { header: true, cat: "Workspaces" },
                { key: "Super+1-6", desc: "Switch workspace" },
                { key: "Super+Shift+1-6", desc: "Move to workspace" },
                { key: "Super+,  /  .", desc: "Prev / Next ws" },
                { header: true, cat: "Volume" },
                { key: "Super+Shift+U", desc: "Volume up" },
                { key: "Super+Shift+D", desc: "Volume down" },
                { key: "Super+Shift+M", desc: "Mute toggle" },
                { header: true, cat: "Media" },
                { key: "Super+Alt+Space", desc: "Play / Pause" },
                { key: "Super+Alt+,  /  .", desc: "Prev / Next track" },
                { header: true, cat: "Capture" },
                { key: "Super+Ctrl+P", desc: "Screenshot region" },
                { key: "Super+Ctrl+Shift+P", desc: "Screenshot full" },
                { header: true, cat: "System" },
                { key: "Super+Ctrl+Alt+L", desc: "Lock screen" },
                { key: "Super+X", desc: "Power menu" },
                { header: true, cat: "Submaps" },
                { key: "Super+V", desc: "Creative mode" },
                { key: "Super+Shift+K", desc: "Keybinds reference" }
            ]

            Column {
                required property var modelData
                width: parent.width

                // category header
                Rectangle {
                    visible: modelData.header === true
                    width: parent.width; height: 24; radius: 4
                    color: "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                        text: modelData.cat || ""; color: Core.AxoraTheme.accent
                        font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(9 * Core.AxoraState.fontScale); font.letterSpacing: 1
                    }
                }

                // keybind row
                Row {
                    visible: modelData.header !== true
                    width: parent.width; height: 26
                    spacing: Core.AxoraMetrics.s

                    Text {
                        id: kbText
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.desc || ""; color: Core.AxoraTheme.text
                        font.family: Core.AxoraTheme.fontUI; font.pixelSize: Math.round(11 * Core.AxoraState.fontScale)
                    }

                    Item { width: parent.width - kbText.implicitWidth - keyLabel.implicitWidth - 12 - 2 * Core.AxoraMetrics.s; height: 1 }

                    Rectangle {
                        id: kbKey
                        anchors.verticalCenter: parent.verticalCenter
                        width: keyLabel.implicitWidth + 12; height: 20; radius: 4
                        color: Core.AxoraTheme.surfaceFill
                        border.color: Core.AxoraTheme.tint(Core.AxoraTheme.muted, "33"); border.width: 1
                        Text {
                            id: keyLabel
                            anchors.centerIn: parent
                            text: modelData.key || ""; color: Core.AxoraTheme.muted
                            font.family: Core.AxoraTheme.fontMono; font.pixelSize: Math.round(9 * Core.AxoraState.fontScale)
                        }
                    }
                }
            }
        }
    }
}
