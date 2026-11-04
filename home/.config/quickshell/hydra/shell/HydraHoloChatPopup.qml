// HydraHoloChatPopup — presence-face chat: live transcript + input row.
// Real backend: transcript reads HydraAssistantApi.historyModel (kind/body),
// send calls HydraAssistantApi.chat(). Mounted by HydraAssistantUi beside the
// center face (non-modal); close via the panel ×, Esc, or the Chat launcher.
import QtQuick
import QtQuick.Shapes
import "../core"

HydraHoloPanel {
    id: panel
    title: "CHAT"
    status: HydraAssistantApi.online ? HydraAssistantApi.historyModel.count + " TURNS · LIVE" : "OFFLINE"

    function send() {
        const t = chatInput.text.trim()
        if (t.length === 0) return
        HydraAssistantApi.chat(t)
        chatInput.text = ""
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 52
        anchors.bottomMargin: 36
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 10

        Item {
            width: parent.width
            height: parent.height - inputRow.height - 10

            ListView {
                id: chatList
                anchors.fill: parent
                clip: true
                spacing: 10
                model: HydraAssistantApi.historyModel
                onCountChanged: positionViewAtEnd()
                delegate: Column {
                    required property string kind
                    required property string body
                    width: chatList.width
                    spacing: 3
                    Text {
                        text: kind === "you" ? "YOU" : kind === "hydra" ? "HYDRA" : "TOOL"
                        color: kind === "you" ? HydraHolo.primary : HydraTheme.muted
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                        font.letterSpacing: 2
                    }
                    Rectangle {
                        width: kind === "tool" ? chatList.width : chatList.width * 0.86
                        height: bubbleText.implicitHeight + 20
                        radius: 10
                        anchors.right: kind === "you" ? parent.right : undefined
                        color: kind === "hydra" ? HydraMaterials.tileGlass : "transparent"
                        border.color: kind === "you" ? HydraHolo.primary : Qt.rgba(1, 1, 1, 0.22)
                        border.width: 1
                        Text {
                            id: bubbleText
                            x: 13; y: 10
                            width: parent.width - 26
                            wrapMode: Text.WordWrap
                            text: body
                            color: kind === "tool" ? HydraTheme.muted : HydraTheme.text
                            font.family: kind === "tool" ? HydraTheme.fontMono : HydraTheme.fontUI
                            font.pixelSize: Math.round((kind === "tool" ? HydraHolo.fsTiny : HydraHolo.fsBody) * HydraState.fontScale)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: HydraAssistantApi.historyModel.count === 0
                text: "No turns yet — type below or say hey hydra"
                color: HydraTheme.muted
                font.family: HydraTheme.fontUI
                font.pixelSize: Math.round(HydraHolo.fsBody * HydraState.fontScale)
            }
        }

        Row {
            id: inputRow
            width: parent.width
            height: 38
            spacing: 8
            Rectangle {
                width: parent.width - 46
                height: 38
                radius: 10
                color: HydraHolo.deep
                border.color: chatInput.activeFocus ? HydraHolo.primary : Qt.rgba(1, 1, 1, 0.22)
                border.width: 1
                TextInput {
                    id: chatInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    color: HydraTheme.text
                    font.family: HydraTheme.fontUI
                    font.pixelSize: Math.round(HydraHolo.fsBody * HydraState.fontScale)
                    clip: true
                    onAccepted: panel.send()
                    Keys.onEscapePressed: panel.closed()
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: chatInput.text.length === 0 && !chatInput.activeFocus
                    text: "Message Hydra…"
                    color: HydraTheme.muted
                    font: chatInput.font
                }
            }
            Item {
                width: 38; height: 38
                Rectangle {
                    anchors.fill: parent
                    radius: 19
                    color: "transparent"
                    border.color: HydraHolo.primary; border.width: 1
                }
                Shape {
                    width: 24; height: 24
                    scale: 0.67
                    anchors.centerIn: parent
                    antialiasing: true
                    ShapePath {
                        strokeColor: HydraHolo.primary
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: HydraHolo.iconPaths.arrowUp }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: panel.send() }
            }
        }
    }

    Component.onCompleted: chatInput.forceActiveFocus()
}
