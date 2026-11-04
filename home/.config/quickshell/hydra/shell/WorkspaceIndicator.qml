// VALKYX WorkspaceIndicator — polished transition animation.
// Centered flash with context-aware color and smooth enter/exit.
import Quickshell
import QtQuick
import "../core"

PanelWindow {
    id: ind
    visible: shown
    anchors { top: true; left: true; right: true }
    margins { top: 44; left: 0; right: 0 }
    implicitWidth: flashRow.implicitWidth + 60
    implicitHeight: 44
    color: "transparent"
    exclusiveZone: -1

    property bool shown: false
    property string label: ""
    property real slideX: 0

    function show(name) {
        label = name.toUpperCase()
        shown = true
        slideX = -20
        slideAnim.start()
        hideTimer.restart()
    }

    Connections {
        target: ValkyxEvents
        function onWorkspaceChanged(name) { if (name) ind.show(name) }
    }

    Timer { id: hideTimer; interval: 900; onTriggered: { exitAnim.start() } }

    NumberAnimation {
        id: slideAnim
        target: ind; property: "slideX"
        from: -20; to: 0
        duration: ValkyxMotion.base
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: exitAnim
        target: ind; property: "slideX"
        from: 0; to: 20
        duration: ValkyxMotion.fast
            easing.type: ValkyxMotion.curveIn
        onFinished: ind.shown = false
    }

    Rectangle {
        anchors.fill: parent
        radius: ValkyxMetrics.rPanel
        color: ValkyxMaterials.osdGlass
        border.color: ValkyxMaterials.border
        border.width: 1

        opacity: ind.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: ValkyxMotion.fast } }

        transform: Translate { x: ind.slideX }

        Row {
            id: flashRow
            anchors.centerIn: parent
            spacing: ValkyxMetrics.m

            // workspace number — accent
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ind.label.split(" ")[0] || ""
                color: ValkyxTheme.accent
                font.family: ValkyxTheme.fontUI
                font.pixelSize: Math.round(16 * ValkyxState.fontScale)
                font.bold: true
            }

            // workspace name — muted text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ind.label.split(" ").slice(1).join(" ")
                color: ValkyxTheme.text
                font.family: ValkyxTheme.fontUI
                font.pixelSize: Math.round(12 * ValkyxState.fontScale)
                font.letterSpacing: 3
            }

            // context icon — shows when context is active
            Text {
                visible: ValkyxState.context !== "normal"
                anchors.verticalCenter: parent.verticalCenter
                text: ValkyxState.context === "gaming" ? "\uDB80\uDE96" :
                      ValkyxState.context === "creative" ? "\uDB81\uDD67" :
                      ValkyxState.context === "fullscreen" ? "\uDB81\uDD02" : ""
                color: ValkyxTheme.accent
                font.family: ValkyxTheme.fontMono
                font.pixelSize: Math.round(11 * ValkyxState.fontScale)
            }
        }
    }
}
