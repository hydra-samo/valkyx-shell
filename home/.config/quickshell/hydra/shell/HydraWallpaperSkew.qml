// VALKYX Wallpaper Skew Deck — iNiR/skwd-style parallelogram slice carousel.
// Center card expands, side slices shrink + dim + slant (Matrix4x4 skewX),
// z-order pulls them behind the active card.
import QtQuick
import QtMultimedia
import "../core"

Item {
    id: deck

    property var entries: []
    property int currentIndex: 0
    property bool animatePreview: false
    property string activePath: ""

    signal pick(var entry)

    function rebuild(list) {
        entries = list
        if (currentIndex >= list.length) currentIndex = Math.max(0, list.length - 1)
    }

    readonly property real expCardW: 415            // center card width (pre-mimic scale)
    readonly property real sliceW: 110              // side slices
    readonly property real sliceSpacing: 2         // small gap between skew edges
    readonly property real skew: 0.19               // italic lean
    readonly property real cardH: 250               // fixed center card height
    readonly property real sideH: 238               // taller side slices

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
            if (Math.abs(d) >= 8 && deck.entries.length)
                deck.currentIndex = Math.max(0, Math.min(deck.entries.length - 1, deck.currentIndex + (d < 0 ? 1 : -1)))
        }
    }

    ListView {
        id: list
        anchors.top: parent.top
        anchors.topMargin: ValkyxMetrics.m
        anchors.left: parent.left
        anchors.right: parent.right
        height: deck.cardH            // fan band tight under the pill (reference: cards hug it)
        orientation: ListView.Horizontal
        spacing: deck.sliceSpacing
        clip: true
        cacheBuffer: deck.expCardW * 2
        focus: false
        interactive: false

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - deck.expCardW) / 2
        preferredHighlightEnd: (width + deck.expCardW) / 2
        highlightMoveDuration: 180
        highlightFollowsCurrentItem: true
        boundsBehavior: Flickable.StopAtBounds
        model: deck.entries

        currentIndex: deck.currentIndex
        onCurrentIndexChanged: if (currentIndex !== deck.currentIndex) deck.currentIndex = currentIndex

        delegate: Item {
            required property int index

            readonly property var entry: index >= 0 && index < deck.entries.length ? deck.entries[index] : null
            readonly property var path: entry ? entry.path : ""
            readonly property string kind: entry ? String(entry.kind) : "image"
            readonly property bool online: entry ? Boolean(entry.online) : false
            readonly property string poster: entry && entry.poster ? String(entry.poster) : ""

            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property int dist: Math.abs(index - list.currentIndex)
            readonly property bool isActive: !online && path === deck.activePath
            readonly property bool isMedia: kind === "video" || kind === "gif"
            readonly property bool livePlay: isCurrent && deck.animatePreview && kind === "video"
            readonly property bool liveGif: isCurrent && deck.animatePreview && kind === "gif"

            property bool hover: false
            property bool flipped: false

            width: isCurrent ? deck.expCardW : deck.sliceW
            height: isCurrent ? deck.cardH : deck.sideH
            y: Math.round((list.height - height) / 2)   // fan row floats vertically centered
            z: isCurrent ? 100 : Math.max(1, 60 - dist)
            antialiasing: true                          // MSAA the skew → smooth diagonals, no stair-stepping
            opacity: isCurrent ? 1.0 : Math.max(0.72, 1 - 0.06 * dist)
            // skewX (m12, negative lean) applies to ALL cards — current just enlarged, same parallelogram form
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -deck.skew, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

            Behavior on width { NumberAnimation { duration: ValkyxMotion.panel; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: ValkyxMotion.panel; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: ValkyxMotion.fast } }

            // hover-zoom + y-flip wrapper (front art / back details)
            Item {
                id: fx
                anchors.fill: parent
                scale: isCurrent ? 1.0 : (hover ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: ValkyxMotion.fast; easing.type: Easing.OutCubic } }

                // FRONT — art card
                Rectangle {
                    id: front
                    opacity: flipped ? 0 : 1
                    scale: flipped ? 0.75 : 1
                    Behavior on opacity { NumberAnimation { duration: ValkyxMotion.panel; easing.type: ValkyxMotion.curveOut } }
                    Behavior on scale { NumberAnimation { duration: ValkyxMotion.panel; easing.type: ValkyxMotion.curveOut } }
                    anchors.fill: parent
                    radius: 0                           // reference: ALL cards sharp corners, no radius
                    color: ValkyxMaterials.surface2
                    border.color: isActive && !isCurrent ? ValkyxTheme.tint(ValkyxTheme.accent, "88") : "transparent"   // no boxes (reference); accent marks the applied one
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: !livePlay && !liveGif ? poster : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(deck.expCardW * 2, deck.height * 2)
                    }

                    VideoOutput {
                        id: lvOut
                        anchors.fill: parent
                        visible: livePlay
                        MediaPlayer {
                            id: lvPlayer
                            videoOutput: lvOut
                            source: livePlay ? ("file://" + path) : ""
                            loops: MediaPlayer.Infinite
                            onSourceChanged: if (source.toString().length > 0) play()
                        }
                    }
                    AnimatedImage {
                        anchors.fill: parent
                        visible: liveGif
                        source: liveGif ? ("file://" + path) : ""
                        playing: liveGif
                        fillMode: Image.PreserveAspectCrop
                    }

                    Rectangle {
                        visible: isCurrent || online
                        anchors.fill: parent
                        color: "transparent"
                    }

                    // hue dots (dominant colours) — current card only, clean reference look
                    Row {
                        visible: isCurrent && (entry?.colors ?? []).length > 0
                        anchors.bottom: parent.bottom; anchors.left: parent.left
                        anchors.bottomMargin: 10; anchors.leftMargin: 10
                        spacing: 4
                        Repeater {
                            model: (entry?.colors ?? []).slice(0, 3)
                            Rectangle {
                                required property string modelData
                                width: 9; height: 9; radius: 4
                                color: modelData
                                border.color: "white"; border.width: 1
                            }
                        }
                    }

                    // favourite star toggle
                    Rectangle {
                        anchors.top: parent.top; anchors.left: parent.left
                        anchors.topMargin: 8; anchors.leftMargin: 8
                        height: 18; implicitWidth: starTxt.implicitWidth + 10
                        radius: 9
                        visible: isCurrent || hover
                        color: WallpaperStore.isFav(path) ? ValkyxTheme.accent : "transparent"
                        border.color: WallpaperStore.isFav(path) ? ValkyxTheme.accent : ValkyxMaterials.borderFaint
                        border.width: 1
                        Text {
                            id: starTxt
                            anchors.centerIn: parent
                            text: WallpaperStore.isFav(path) ? "★" : "☆"
                            color: WallpaperStore.isFav(path) ? ValkyxTheme.textOnAccent : ValkyxTheme.muted
                            font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperStore.toggleFav(path)
                        }
                    }

                    // reference-style play overlay on video cards (hidden while live-previewing)
                    Rectangle {
                        visible: kind === "video" && !livePlay
                        anchors.centerIn: parent
                        width: 44; height: 44; radius: 22
                        color: Qt.rgba(0, 0, 0, 0.35)
                        border.color: "white"; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "▶"
                            color: "white"
                            font.family: ValkyxTheme.fontUI; font.pixelSize: 18; font.bold: true
                        }
                    }

                    // selection is the accent border + left strip — no CURRENT pill on the art
                    Rectangle {
                        visible: isMedia && !isActive
                        anchors.top: parent.top; anchors.right: parent.right
                        anchors.topMargin: 8; anchors.rightMargin: 8
                        height: 18; implicitWidth: txtKind.implicitWidth + 10
                        radius: 9
                        color: ValkyxMaterials.surface1
                        border.color: ValkyxMaterials.borderFaint; border.width: 1
                        Text {
                            id: txtKind
                            anchors.centerIn: parent
                            text: kind === "video" ? "▶ VID" : "■ GIF"
                            color: ValkyxTheme.muted
                            font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale); font.bold: true
                        }
                    }
                }

// BACK — details (cross-fades in behind the front)
                Rectangle {
                    id: back
                    opacity: flipped ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: ValkyxMotion.panel; easing.type: ValkyxMotion.curveOut } }
                    anchors.fill: parent
                    radius: isCurrent ? ValkyxMetrics.radiusMd : ValkyxMetrics.radiusSm
                    color: ValkyxMaterials.surface1
                    border.color: isCurrent ? ValkyxTheme.accent : ValkyxMaterials.borderFaint
                    border.width: isCurrent ? 2 : 1
                    clip: true

                    Column {
                        anchors.top: parent.top; anchors.bottom: parent.bottom
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: entry ? String(entry.name) : ""
                            width: parent.width
                            elide: Text.ElideMiddle
                            color: ValkyxTheme.text
                            font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(11 * ValkyxState.fontScale); font.bold: true
                        }
                        Text {
                            text: kind === "image" ? "still" : (kind === "video" ? "video" : "gif")
                                + (online ? " · wallhaven" : " · local")
                            color: ValkyxTheme.muted
                            font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                        }
                        Text {
                            visible: !online
                            text: String(path).split("/").pop()
                            width: parent.width
                            elide: Text.ElideMiddle
                            color: ValkyxMaterials.border
                            font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                        }
                        Item { width: 1; height: 2 }

                        Rectangle {
                            height: 26; implicitWidth: setTxt.implicitWidth + 24
                            radius: 13
                            color: ValkyxTheme.accent
                            Text {
                                id: setTxt
                                anchors.centerIn: parent
                                text: online ? "DOWNLOAD + SET" : "SET AS WALLPAPER"
                                color: ValkyxTheme.textOnAccent
                                font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale); font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: deck.pick(deck.entries[index])
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: hover = true
                onExited: hover = false
                // wheel over a card drives the fan (deck-level WheelHandler is shadowed by this MouseArea)
                onWheel: (event) => {
                    const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                    if (Math.abs(d) >= 8 && deck.entries.length)
                        deck.currentIndex = Math.max(0, Math.min(deck.entries.length - 1, deck.currentIndex + (d < 0 ? 1 : -1)))
                    event.accepted = true
                }
onClicked: {
                deck.currentIndex = index
                if (isCurrent) deck.pick(deck.entries[index])
            }
            onDoubleClicked: {
                deck.currentIndex = index
                flipped = !flipped
            }
        }
    }
}
}