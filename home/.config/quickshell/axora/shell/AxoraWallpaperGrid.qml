// AXORA Wallpaper Grid — flat tile grid, per-type hover + accent selection ring.
import QtQuick
import "../core"

Item {
    id: grid

    property var entries: []
    property int currentIndex: 0
    property string activePath: ""
    signal pick(var entry)
    signal selected(int index)

    readonly property real cell: 150

    function rebuild(list) {
        entries = list
        if (currentIndex >= list.length) currentIndex = Math.max(0, list.length - 1)
    }

    GridView {
        id: view
        anchors.fill: parent
        clip: true
        cellWidth: cell + 12
        cellHeight: cell * 0.72 + 34
        cacheBuffer: 800
        focus: false

        model: grid.entries
        currentIndex: grid.currentIndex
        onCurrentIndexChanged: if (currentIndex !== grid.currentIndex) grid.currentIndex = currentIndex

        delegate: Item {
            required property int index

            readonly property var entry: index >= 0 && index < grid.entries.length ? grid.entries[index] : null
            readonly property var path: entry ? entry.path : ""
            readonly property string kind: entry ? String(entry.kind) : "image"
            readonly property bool online: entry ? Boolean(entry.online) : false
            readonly property string poster: entry && entry.poster ? String(entry.poster) : ""

            readonly property bool isCurrent: view.currentIndex === index
            readonly property bool isActive: !online && path === grid.activePath
            readonly property bool isMedia: kind === "video" || kind === "gif"

            property bool hover: false

            width: view.cellWidth; height: view.cellHeight

            Rectangle {
                id: card
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: parent.height - 30
                radius: AxoraMetrics.radiusMd
                color: AxoraMaterials.surface2
                border.color: isCurrent ? AxoraTheme.accent : (isActive ? AxoraTheme.tint(AxoraTheme.accent, "88") : AxoraMaterials.borderFaint)
                border.width: isCurrent ? 2 : 1
                clip: true

                Image {
                    anchors.fill: parent
                    source: poster
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(300, 300)
                }

                // hue dots
                Row {
                    visible: (entry?.colors ?? []).length > 0
                    anchors.bottom: parent.bottom; anchors.left: parent.left
                    anchors.bottomMargin: 6; anchors.leftMargin: 6
                    spacing: 3
                    Repeater {
                        model: (entry?.colors ?? []).slice(0, 3)
                        Rectangle {
                            required property string modelData
                            width: 8; height: 8; radius: 4
                            color: modelData
                            border.color: "white"; border.width: 1
                        }
                    }
                }
                // favourite star
                Rectangle {
                    anchors.top: parent.top; anchors.left: parent.left
                    anchors.topMargin: 5; anchors.leftMargin: 5
                    height: 16; implicitWidth: starTxt.implicitWidth + 8
                    radius: 8
                    visible: isCurrent || hover
                    color: WallpaperStore.isFav(path) ? AxoraTheme.accent : "transparent"
                    border.color: WallpaperStore.isFav(path) ? AxoraTheme.accent : AxoraMaterials.borderFaint
                    border.width: 1
                    Text {
                        id: starTxt
                        anchors.centerIn: parent
                        text: WallpaperStore.isFav(path) ? "★" : "☆"
                        color: WallpaperStore.isFav(path) ? AxoraTheme.textOnAccent : AxoraTheme.muted
                        font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperStore.toggleFav(path)
                    }
                }
                Rectangle {
                    visible: isMedia
                    anchors.top: parent.top; anchors.right: parent.right
                    anchors.topMargin: 6; anchors.rightMargin: 6
                    height: 16; implicitWidth: txt.implicitWidth + 8
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.55)
                    Text {
                        id: txt
                        anchors.centerIn: parent
                        text: kind === "video" ? "▶" : "■"
                        color: "white"
                        font.family: AxoraTheme.fontUI; font.pixelSize: 9; font.bold: true
                    }
                }
                Rectangle {
                    visible: isActive
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                    height: 3
                    color: AxoraTheme.accent
                }
            }
            Text {
                anchors.top: card.bottom; anchors.left: parent.left; anchors.right: parent.right
                anchors.topMargin: 4
                elide: Text.ElideRight
                text: entry ? String(entry.name) : ""
                color: AxoraTheme.muted
                font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(10 * AxoraState.fontScale)
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: hover = true
                onExited: hover = false
                onClicked: {
                    grid.selected(index)
                    grid.pick(grid.entries[index])
                }
            }
        }
    }
}