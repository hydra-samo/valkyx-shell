// HydraAssistantIsland — dynamic island under the TopHud: the background
// assistant surface. Pops in while Hydra is live (listening/speaking/
// thinking/needs-approval, plus an 8s reply hold), hides to nothing when
// idle. Hosts the real HydraAssistantPresence (plexus + ring + dot), one
// state expression, and the latest reply — click opens the full window
// (hydra-holo-window, Super+D). Transparent strip passes clicks through —
// only the pill has a MouseArea. Focusable like the TopHud root (default):
// focusable:false takes ALL input in this build, which is why the pill
// clicked dead until this was removed (cf. HydraWelcomeGreeter). Polling keep-alive: the window drives setPolling from
// uiOpen, so without this the island's online flag would die with the window.
import Quickshell
import QtQuick
import QtQuick.Shapes
import "../core"

PanelWindow {
    id: island

    anchors { top: true; left: true; right: true }
    margins { top: 48; left: 0; right: 0 }
    implicitHeight: 64
    implicitWidth: Screen.width
    color: "transparent"
    exclusiveZone: 0
    aboveWindows: true

    readonly property bool voiceLive: HydraAssistantApi.stateName === "listening"
        || HydraAssistantApi.stateName === "speaking"
        || HydraAssistantApi.stateName === "thinking"
        || HydraAssistantApi.stateName === "needs-approval"
        || HydraAssistantApi.pendingModel.count > 0
    property bool holding: false
    property double holdUntil: 0
    readonly property bool shown: HydraContext.rule(HydraState.context, "hud")
        && (voiceLive || holding)
    readonly property bool isApproval: HydraAssistantApi.stateName === "needs-approval"
        || HydraAssistantApi.pendingModel.count > 0

    // the window owns polling via uiOpen; re-assert so closing the window
    // never starves the island's online flag (read-only 1Hz, cheap)
    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: HydraAssistantApi.setPolling(true)
    }
    Component.onCompleted: HydraAssistantApi.setPolling(true)

    // reply hold: stay up 8s after the last reply lands
    Connections {
        target: HydraAssistantApi
        function onReplyChanged() {
            island.holdUntil = Date.now() + 8000
            island.holding = true
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: island.holding
        onTriggered: island.holding = Date.now() < island.holdUntil
    }

    onVisibleChanged: if (!visible) holding = false
    visible: shown

    // pill — centered, slides down on show
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: island.shown ? 0 : -70
        opacity: island.shown ? 1 : 0
        width: Math.min(520, parent.width - 32)
        height: 48
        radius: 24
        color: HydraHolo.bg
        border.color: island.isApproval ? HydraHolo.warning : HydraHolo.primary
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: HydraMotion.fast } }
        Behavior on y { NumberAnimation { duration: HydraMotion.panel; easing.type: HydraMotion.curveSnap } }
        Behavior on opacity { NumberAnimation { duration: HydraMotion.fast; easing.type: HydraMotion.curveOut } }

        // exactly TWO opposite brackets (top-left + bottom-right)
        Repeater {
            model: 2
            delegate: Item {
                width: 12; height: 12
                x: (index % 2 === 0) ? 8 : pill.width - 20
                y: (index === 0) ? 8 : pill.height - 20
                Rectangle {
                    width: 12; height: 2
                    color: island.isApproval ? HydraHolo.warning : HydraHolo.primary
                    x: 0; y: (index === 0) ? 0 : 10
                }
                Rectangle {
                    width: 2; height: 12
                    color: island.isApproval ? HydraHolo.warning : HydraHolo.primary
                    x: (index % 2 === 0) ? 0 : 10; y: 0
                }
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            HydraAssistantPresence {
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34
                stateName: HydraAssistantApi.stateName
                level: HydraAssistantApi.level
                online: HydraAssistantApi.online
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34 - 26 - 20 - 36
                spacing: 1
                Text {
                    text: HydraAssistantApi.online
                        ? HydraAssistantApi.stateName.toUpperCase() : "OFFLINE"
                    color: island.isApproval ? HydraHolo.warning : HydraHolo.primary
                    font.family: HydraTheme.fontMono
                    font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                    font.letterSpacing: 2
                }
                Text {
                    width: parent.width
                    text: HydraAssistantApi.reply
                    color: HydraTheme.text
                    font.family: HydraTheme.fontUI
                    font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text !== ""
                }
            }

            // mic mute (nested above the pill opener — child MouseArea
            // wins, so this toggles without opening the window)
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 26; height: 26
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    border.color: HydraState.micMuted ? HydraHolo.error : "transparent"
                    border.width: 1
                }
                Shape {
                    width: 18; height: 18
                    anchors.centerIn: parent
                    antialiasing: true
                    ShapePath {
                        strokeColor: HydraState.micMuted ? HydraHolo.error
                            : (micHover.containsMouse ? HydraHolo.primary : HydraTheme.muted)
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: HydraHolo.iconPaths.mic }
                    }
                }
                MouseArea {
                    id: micHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: HydraState.toggleMic()
                }
            }

            Shape {
                anchors.verticalCenter: parent.verticalCenter
                width: 18; height: 18
                antialiasing: true
                ShapePath {
                    strokeColor: pillHover.containsMouse ? HydraHolo.primary : HydraTheme.muted
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: HydraHolo.iconPaths.apps }
                }
            }
        }

        MouseArea {
            id: pillHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: HydraState.exec("hydra-holo-window")
        }
    }
}
