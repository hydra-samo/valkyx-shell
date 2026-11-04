// AxoraHoloNewsPopup — headlines list + reader sub-view + source rail.
// Live: GET /api/news?source=world|tech via AxoraAssistantApi._request,
// fetched on open and on rail switch. Tapping a headline shows link +
// published in the reader — no article-read endpoint exists server-side,
// so there is no "read full" fetch, only the link text. Panel
// state/message/status carry loading/empty/error/offline.
import QtQuick
import QtQuick.Shapes
import "../core"

AxoraHoloPanel {
    id: panel
    title: "NEWS"
    status: panel.newsState === "content" ? panel.headlineModel.count + " ITEMS" : ""
    state: panel.newsState
    message: panel.newsMessage

    property string newsState: "loading"
    property string newsMessage: ""
    property string feed: "arabic"
    property ListModel sourceModel: ListModel {
        ListElement { name: "arabic" }
        ListElement { name: "jazeera" }
        ListElement { name: "bbc-arabic" }
        ListElement { name: "france24-ar" }
    }
    property ListModel headlineModel: ListModel {}
    property var selected: null
    property Timer newsWatchdog: Timer {
        interval: 8000
        repeat: false
        running: false
        onTriggered: {
            if (panel.newsState === "loading") {
                panel.newsState = "error"
                panel.newsMessage = "NO RESPONSE AFTER 8S — API DOWN OR UNREACHABLE"
            }
        }
    }
    function fetchAgain() { fetchNews() }
    function fetchNews() {
        panel.selected = null
        panel.newsState = "loading"
        panel.newsMessage = ""
        panel.headlineModel.clear()
        panel.newsWatchdog.restart()
        if (!AxoraAssistantApi.online) {
            panel.newsWatchdog.stop()
            panel.newsState = "offline"
            panel.newsMessage = "API NOT REACHABLE — RETRY ONCE THE ASSISTANT SERVICE ANSWERS"
            return
        }
        AxoraAssistantApi._request("GET", "/api/news?source=" + panel.feed, null, (obj) => {
            panel.newsWatchdog.stop()
            const items = (obj && obj.items) || []
            panel.headlineModel.clear()
            if (items.length > 0 && items[0].error) {
                panel.newsState = "error"
                panel.newsMessage = String(items[0].error).toUpperCase()
                return
            }
            for (const it of items)
                panel.headlineModel.append({ title: it.title || "", link: it.link || "", published: it.published || "" })
            if (panel.headlineModel.count > 0) {
                panel.newsState = "content"
                panel.newsMessage = ""
            } else {
                panel.newsState = "empty"
                panel.newsMessage = "FEED RETURNED NO HEADLINES"
            }
        })
    }
        // Boot race: opened before the first poll answers, `online` is false
    // and the fetch instantly errors. Re-fetch on the false->true flip —
    // no retry counters, no fixed waits.
    Connections {
        target: AxoraAssistantApi
        function onOnlineChanged() { if (AxoraAssistantApi.online) fetchAgain() }
    }

Component.onCompleted: fetchNews()

    Row {
        anchors.fill: parent
        anchors.topMargin: 52
        anchors.bottomMargin: 36
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 14
        visible: panel.newsState === "content"

        // source rail
        Column {
            width: 120
            height: parent.height
            spacing: 8
            Text {
                text: "SOURCES"
                color: AxoraTheme.muted
                font.family: AxoraTheme.fontMono
                font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
                font.letterSpacing: 2
            }
            ListView {
                width: parent.width
                height: parent.height - 24 - 40
                clip: true
                spacing: 6
                model: panel.sourceModel
                delegate: Item {
                    required property string name
                    width: 120
                    height: 20
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: name
                        color: name === panel.feed ? AxoraHolo.primary : AxoraTheme.text
                        width: 120
                        elide: Text.ElideRight
                        font.family: AxoraTheme.fontMono
                        font.pixelSize: Math.round(AxoraHolo.fsTiny * AxoraState.fontScale)
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { if (panel.feed !== name) { panel.feed = name; panel.fetchNews() } }
                    }
                }
            }
        }

        Item {
            width: parent.width - 134
            height: parent.height

            // headlines list
            Item {
                anchors.fill: parent
                visible: panel.selected === null
                ListView {
                    id: headlineList
                    anchors.fill: parent
                    clip: true
                    spacing: 10
                    model: panel.headlineModel
                    delegate: Item {
                        required property string title
                        required property string link
                        required property string published
                        width: headlineList.width
                        height: headlineCol.implicitHeight
                        Column {
                            id: headlineCol
                            width: parent.width
                            spacing: 2
                            Text {
                                text: published !== "" ? published : panel.feed
                                color: AxoraTheme.muted
                                font.family: AxoraTheme.fontMono
                                font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
                                font.letterSpacing: 2
                            }
                            Text {
                                text: title
                                color: AxoraTheme.text
                                width: headlineCol.width
                                wrapMode: Text.WordWrap
                                font.family: AxoraTheme.fontUI
                                font.pixelSize: Math.round(AxoraHolo.fsBody * AxoraState.fontScale)
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: panel.selected = { title: title, link: link, published: published }
                        }
                    }
                }
            }

            // reader sub-view
            Column {
                anchors.fill: parent
                visible: panel.selected !== null
                spacing: 8
                Text {
                    text: "READER"
                    color: AxoraTheme.muted
                    font.family: AxoraTheme.fontMono
                    font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
                    font.letterSpacing: 2
                }
                Text {
                    text: panel.feed
                    color: AxoraHolo.primary
                    font.family: AxoraTheme.fontMono
                    font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
                    font.letterSpacing: 2
                }
                Text {
                    text: panel.selected ? panel.selected.title : ""
                    color: AxoraTheme.text
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.family: AxoraTheme.fontUI
                    font.pixelSize: Math.round(AxoraHolo.fsBody * AxoraState.fontScale)
                }
                Text {
                    text: panel.selected ? panel.selected.published : ""
                    color: AxoraTheme.muted
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.family: AxoraTheme.fontMono
                    font.pixelSize: Math.round(AxoraHolo.fsTiny * AxoraState.fontScale)
                }
                Text {
                    text: panel.selected ? panel.selected.link : ""
                    color: AxoraTheme.text
                    width: parent.width
                    wrapMode: Text.WrapAnywhere
                    font.family: AxoraTheme.fontMono
                    font.pixelSize: Math.round(AxoraHolo.fsTiny * AxoraState.fontScale)
                }
                Item {
                    width: 64; height: 30
                    Rectangle {
                        anchors.fill: parent
                        radius: 15
                        color: "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.22); border.width: 1
                    }
                    Shape {
                        width: 24; height: 24
                        scale: 0.67
                        anchors.centerIn: parent
                        antialiasing: true
                        ShapePath {
                            strokeColor: AxoraTheme.muted
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: AxoraHolo.iconPaths.arrowLeft }
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: panel.selected = null }
                }
            }
        }
    }
}
