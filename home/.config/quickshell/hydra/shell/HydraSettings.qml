// HYDRA SETTINGS — floating window, centered via top+left anchors.
// Fixed: was too tall for 768p (750/768 = 98% — Hyprland fought it).
// Now 640px tall, exclusiveZone -1, Esc to close.
import Quickshell
import Quickshell.Io
import QtQuick
import "../core" as Core
import "settings" as Pages

PanelWindow {
    id: settings
    visible: Core.HydraState.settingsOpen

    implicitWidth: 960; implicitHeight: 640
    anchors { top: true; left: true }
    // Draggable floating window — position tracked in winX/winY, drag the title bar to move.
    // Centering computed from the window's OWN screen (not global Screen, which is
    // stale/wrong at load time) and re-applied once the window lands on a screen.
    property real winX: 0
    property real winY: 0
    property bool dragging: false
    function recenter() {
        const sw = settings.screen ? settings.screen.width : 1366
        const sh = settings.screen ? settings.screen.height : 768
        settings.winX = Math.max(0, Math.round((sw - settings.width) / 2))
        settings.winY = Math.max(0, Math.round((sh - settings.height) / 2))
    }
    onScreenChanged: if (!dragging) recenter()
    onVisibleChanged: if (visible && !dragging) recenter()
    onWidthChanged: if (visible && !dragging) recenter()
    onHeightChanged: if (visible && !dragging) recenter()
    Component.onCompleted: recenter()
    margins {
        top: settings.winY
        left: settings.winX
    }
    exclusiveZone: -1
    focusable: true
    aboveWindows: true

    color: "transparent"

    // Esc to close — Keys needs an Item, not PanelWindow
    Item {
        id: panelRoot
        anchors.fill: parent
        opacity: Core.HydraState.settingsOpen ? 1 : 0
        enabled: Core.HydraState.settingsOpen
        focus: Core.HydraState.settingsOpen
        Keys.onEscapePressed: Core.HydraState.settingsOpen = false

        // glass background
        Rectangle {
            anchors.fill: parent
            color: Core.HydraMaterials.panelGlass
            radius: Core.HydraMetrics.rPanel
            border.color: Core.HydraMaterials.border
            border.width: 1
        }

        // ── Title bar (draggable) ──
        Item {
            id: titleBar
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: 40
            anchors.margins: 1

            // drag handle — moves the whole bar
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor
                property real px: 0
                property real py: 0
                property real ox0: 0
                property real oy0: 0
                onPressed: (m) => {
                    px = m.x; py = m.y
                    ox0 = settings.winX; oy0 = settings.winY
                    settings.dragging = true
                }
                onPositionChanged: (m) => {
                    // Exact identity, no feedback loop. m.x shifts by the window's own
                    // movement, so cancel that: absolute_from_press = (m.x-px_press)
                    // + window_moved_since_press. Anchored to the press time, so no
                    // accumulation and no dependence on committed-surface timestamps.
                    const sx = (m.x - px) + (settings.winX - ox0)
                    const sy = (m.y - py) + (settings.winY - oy0)
                    const sw = settings.screen ? settings.screen.width : 1366
                    const sh = settings.screen ? settings.screen.height : 768
                    settings.winX = Math.round(Math.max(0, Math.min(sw - settings.width, ox0 + sx)))
                    settings.winY = Math.round(Math.max(0, Math.min(sh - settings.height, oy0 + sy)))
                }
                onReleased: () => { settings.dragging = false }
            }

            // title text
            Text {
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "\uDB80\uDED9  SETTINGS"; color: Core.HydraTheme.accent
                font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(11 * Core.HydraState.fontScale); font.letterSpacing: 2
            }

            // close button (on top of drag area)
            Rectangle {
                width: 26; height: 26; radius: 6
                anchors.right: parent.right; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                Text { anchors.centerIn: parent; text: "\uDB80\uDD56"; color: closeH.containsMouse ? Core.HydraTheme.danger : Core.HydraTheme.muted; font.pixelSize: Math.round(11 * Core.HydraState.fontScale) }
                MouseArea { id: closeH; anchors.fill: parent; hoverEnabled: true; onClicked: Core.HydraState.settingsOpen = false; cursorShape: Qt.PointingHandCursor }
            }
        }

        // ── Nav rail ──
        Column {
            id: navRail
            anchors.top: titleBar.bottom; anchors.bottom: parent.bottom
            anchors.left: parent.left; anchors.leftMargin: 1
            width: 48
            anchors.topMargin: 6

            Repeater {
                model: [
                    { icon: "\uDB81\uDC93", tip: "Appearance", page: 0 },
                    { icon: "\uDB81\uDD02", tip: "Display",    page: 1 },
                    { icon: "\uDB80\uDF0C", tip: "Keyboard",   page: 2 },
                    { icon: "\uDB80\uDF7D", tip: "Mouse",     page: 3 },
                    { icon: "\uDB81\uDC25", tip: "Session",    page: 4 }
                ]
                Rectangle {
                    required property int index
                    required property var modelData
                    width: 36; height: 36; radius: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    border.color: settings.currentPage === modelData.page ? Core.HydraTheme.accent : "transparent"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        color: settings.currentPage === modelData.page ? Core.HydraTheme.accent : Core.HydraTheme.muted
                        font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(14 * Core.HydraState.fontScale)
                    }
                    MouseArea {
                        id: navH; anchors.fill: parent; hoverEnabled: true
                        onClicked: Core.HydraState.settingsPage = modelData.page
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            Item { height: parent.height - 5 * 44; width: 1 }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "v0.9"; color: Core.HydraTheme.tint(Core.HydraTheme.muted, "44")
                font.family: Core.HydraTheme.fontMono; font.pixelSize: Math.round(8 * Core.HydraState.fontScale)
            }
        }

        // ── Divider ──
        Rectangle {
            anchors.top: titleBar.bottom; anchors.bottom: parent.bottom
            anchors.left: navRail.right; anchors.leftMargin: 8
            width: 1; color: Core.HydraMaterials.border
            anchors.topMargin: 6; anchors.bottomMargin: 12
        }

        // ── Content area ──
        Item {
            anchors.top: titleBar.bottom; anchors.bottom: parent.bottom
            anchors.left: navRail.right; anchors.leftMargin: 16
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.topMargin: 6; anchors.bottomMargin: 12

            Pages.SettingsAppearancePage { anchors.fill: parent; visible: settings.currentPage === 0 }
            Pages.SettingsDisplayPage { anchors.fill: parent; visible: settings.currentPage === 1 }
            Pages.SettingsKeyboardPage { anchors.fill: parent; visible: settings.currentPage === 2 }
            Pages.SettingsMousePage { anchors.fill: parent; visible: settings.currentPage === 3 }
            Pages.SettingsSessionPage { anchors.fill: parent; visible: settings.currentPage === 4 }
        }

    }
    property int currentPage: Core.HydraState.settingsPage
}
