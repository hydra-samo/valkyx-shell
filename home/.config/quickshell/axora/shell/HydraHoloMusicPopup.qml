// AxoraHoloMusicPopup — transport row + queue list.
// Live: GET /api/music via AxoraAssistantApi._request, fetched on open and
// every 5s while open, driving the now-playing line ({artist,title,status}
// or the honest {error} when no MPRIS player is active). Transport buttons
// keep the honest note — no transport endpoint exists server-side (control
// lives only in the music tool, not on HTTP), so nothing is posted and
// nothing is ever auto-launched. Panel state/message/status carry
// loading/empty/error/offline.
import QtQuick
import QtQuick.Shapes
import "../core"

AxoraHoloPanel {
    id: panel
    title: "MUSIC"
    status: panel.musicState === "content" ? "GET /api/music · " + panel.playerStatus.toUpperCase() : ""
    state: panel.musicState
    message: panel.musicMessage

    property string musicState: "loading"
    property string musicMessage: ""
    property string nowLine: ""
    property string playerStatus: ""
    property string transportNote: "Transport idle — no player connected"
    property ListModel queueModel: ListModel {}
    property Timer musicWatchdog: Timer {
        interval: 8000
        repeat: false
        running: false
        onTriggered: {
            if (panel.musicState === "loading") {
                panel.musicState = "error"
                panel.musicMessage = "NO RESPONSE AFTER 8S — API DOWN OR UNREACHABLE"
            }
        }
    }
    function fetchAgain() { fetchMusic() }
    function fetchMusic() {
        if (!AxoraAssistantApi.online) {
            panel.musicWatchdog.stop()
            panel.musicState = "offline"
            panel.musicMessage = "API NOT REACHABLE — RETRY ONCE THE ASSISTANT SERVICE ANSWERS"
            return
        }
        AxoraAssistantApi._request("GET", "/api/music", null, (obj) => {
            panel.musicWatchdog.stop()
            if (!obj) return
            if (obj.error) {
                panel.musicState = "empty"
                panel.musicMessage = String(obj.error).toUpperCase()
                return
            }
            const artist = String(obj.artist || "").trim()
            const title = String(obj.title || "").trim()
            panel.playerStatus = String(obj.status || "").trim()
            let line = artist !== "" && title !== "" ? artist + " — " + title : (title !== "" ? title : artist)
            if (line === "") line = "Now playing — metadata unavailable"
            panel.nowLine = line + (panel.playerStatus !== "" ? " [" + panel.playerStatus + "]" : "")
            panel.musicState = "content"
            panel.musicMessage = ""
        })
    }
        // Boot race: opened before the first poll answers, `online` is false
    // and the fetch instantly errors. Re-fetch on the false->true flip —
    // no retry counters, no fixed waits.
    Connections {
        target: AxoraAssistantApi
        function onOnlineChanged() { if (AxoraAssistantApi.online) fetchAgain() }
    }

Component.onCompleted: { panel.musicWatchdog.start(); panel.fetchMusic() }
    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: panel.fetchMusic()
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 52
        anchors.bottomMargin: 36
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12
        visible: panel.musicState === "content"

        Text {
            text: "NOW PLAYING"
            color: AxoraTheme.muted
            font.family: AxoraTheme.fontMono
            font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
            font.letterSpacing: 2
        }
        Text {
            text: panel.nowLine
            color: AxoraTheme.text
            width: parent.width
            wrapMode: Text.WordWrap
            font.family: AxoraTheme.fontUI
            font.pixelSize: Math.round(AxoraHolo.fsBody * AxoraState.fontScale)
        }

        Row {
            spacing: 10
            Repeater {
                model: ["play", "pause", "next"]
                delegate: Item {
                    required property string modelData
                    width: 64; height: 38
                    Rectangle {
                        anchors.fill: parent
                        radius: 19
                        color: "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.22); border.width: 1
                    }
                    Shape {
                        width: 24; height: 24
                        scale: 0.75
                        anchors.centerIn: parent
                        antialiasing: true
                        ShapePath {
                            strokeColor: AxoraTheme.muted
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: AxoraHolo.iconPaths[modelData] }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: panel.transportNote = modelData + " — not connected, no player backend"
                    }
                }
            }
        }
        Text {
            text: panel.transportNote
            color: AxoraTheme.muted
            width: parent.width
            wrapMode: Text.WordWrap
            font.family: AxoraTheme.fontMono
            font.pixelSize: Math.round(AxoraHolo.fsTiny * AxoraState.fontScale)
        }

        Text {
            text: "QUEUE"
            color: AxoraTheme.muted
            font.family: AxoraTheme.fontMono
            font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
            font.letterSpacing: 2
        }
        Item {
            width: parent.width
            height: 148
            ListView {
                id: queueList
                anchors.fill: parent
                clip: true
                spacing: 8
                model: panel.queueModel
                delegate: Column {
                    required property string title
                    required property string sub
                    width: queueList.width
                    spacing: 2
                    Text {
                        text: title
                        color: AxoraTheme.text
                        font.family: AxoraTheme.fontUI
                        font.pixelSize: Math.round(AxoraHolo.fsBody * AxoraState.fontScale)
                    }
                    Text {
                        text: sub
                        color: AxoraTheme.muted
                        font.family: AxoraTheme.fontMono
                        font.pixelSize: Math.round(AxoraHolo.fsTiny * AxoraState.fontScale)
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: panel.queueModel.count === 0
                text: "Queue empty — no player backend"
                color: AxoraTheme.muted
                font.family: AxoraTheme.fontUI
                font.pixelSize: Math.round(AxoraHolo.fsBody * AxoraState.fontScale)
            }
        }
    }
}
