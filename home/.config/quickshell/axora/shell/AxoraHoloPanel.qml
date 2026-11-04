// AxoraHoloPanel — the workbench's reusable overlay panel: a fixed 620x460 glass
// card with the HUD's two-bracket frame, a heading + status line, the four
// non-content states (loading / empty / error / offline) and a slot for the
// caller's scrollable list. Open/close travel uses AxoraMotion tokens only —
// no literal durations, no raw curves.
//
// Usage (children arrive via the default property, parented to the slot):
//
//     AxoraHoloPanel {
//         title: "SYSTEM"
//         status: "GET /api/system · 5 ROWS"
//         state: "content"          // loading | empty | error | offline | content
//         message: ""               // optional override; defaults per state
//         ListView { anchors.fill: parent; ... }
//     }
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../core"

Item {
    id: panel
    width: 620
    height: 460

    property string title: ""
    property string status: ""
    property string state: "content"
    property string message: ""

    signal closed()

    function stateText() {
        if (panel.message !== "") return panel.message
        if (panel.state === "loading") return "QUERYING API…"
        if (panel.state === "empty") return "NO DATA RETURNED"
        if (panel.state === "error") return "REQUEST FAILED"
        if (panel.state === "offline") return "OFFLINE — API UNREACHABLE"
        return ""
    }

    // enter travel: literal inits are not bindings, so assigning plain values
    // here is safe and the Behaviors animate them in. Exit never plays — the
    // host unmounts the panel.
    opacity: 0
    scale: 0.96
    transformOrigin: Item.Center
    Behavior on opacity { NumberAnimation { duration: AxoraMotion.panel; easing.type: AxoraMotion.curveSnap } }
    Behavior on scale { NumberAnimation { duration: AxoraMotion.panel; easing.type: AxoraMotion.curveSnap } }
    Component.onCompleted: { opacity = 1; scale = 1 }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: AxoraMetrics.rTile
        color: AxoraHolo.bg
        border.color: AxoraMaterials.border
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: AxoraMotion.fast } }
        Behavior on color { ColorAnimation { duration: AxoraMotion.fast } }
        // swallow clicks so they reach nothing, not the dim behind
        MouseArea { anchors.fill: parent }

        // HUD corner brackets — exactly TWO: top-left + bottom-right
        Repeater {
            model: 2
            delegate: Item {
                width: 14; height: 14
                x: (index % 2 === 0) ? 5 : card.width - 19
                y: (index === 0) ? 5 : card.height - 19
                Rectangle { width: 14; height: 2; color: AxoraHolo.primary; x: 0; y: (index === 0) ? 0 : 12 }
                Rectangle { width: 2; height: 14; color: AxoraHolo.primary; x: (index % 2 === 0) ? 0 : 12; y: 0 }
            }
        }

        // Content container is a plain Item with explicit anchors — NOT a
        // Column: a positioner hijacks every child's x/y/anchors (including
        // the brackets Repeater's delegates and the header), which is what
        // scattered the status text into the list ("10 ITEMS" at y330).
        Item {
            anchors.fill: parent
            // Clear the TL corner bracket (x5-19,y5-19): without this inset
            // the title's first letter renders under the bracket ("4HAT").
            anchors.leftMargin: 24
            anchors.topMargin: 10
            anchors.rightMargin: 14
            anchors.bottomMargin: 14

            // heading + status + close. The title/status block is the drag
            // handle: press-and-move repositions the panel inside its host
            // face, clamped to full containment. The close button stays a
            // sibling so its clicks never hit the drag area. Drag state dies
            // with the item (Loader unmounts on close) — dock = default.
            Item {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 24
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: panel.title
                        color: AxoraHolo.primary
                        font.family: AxoraTheme.fontMono
                        font.pixelSize: Math.round(AxoraHolo.fsSm * AxoraState.fontScale)
                        font.letterSpacing: Math.round(AxoraHolo.fsSm * 0.3 * AxoraState.fontScale)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        property real _px: 0
                        property real _py: 0
                        onPressed: function(mouse) { _px = mouse.x; _py = mouse.y }
                        onPositionChanged: function(mouse) {
                            if (!pressed) return
                            const loader = panel.parent
                            if (!loader || !loader.parent) return
                            const face = loader.parent
                            const lx = Math.max(0, Math.min(face.width - panel.width,
                                loader.x + panel.x + (mouse.x - _px)))
                            const ly = Math.max(0, Math.min(face.height - panel.height,
                                loader.y + panel.y + (mouse.y - _py)))
                            panel.x = Math.round(lx - loader.x)
                            panel.y = Math.round(ly - loader.y)
                        }
                    }
                // Status + close live INSIDE the header bar: as content-box
                // siblings their verticalCenter resolved to card middle
                // ("10 ITEMS" floating at y330 next to list rows).
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 32
                    anchors.verticalCenter: parent.verticalCenter
                    visible: panel.status !== ""
                    text: panel.status
                    color: AxoraTheme.muted
                    font.family: AxoraTheme.fontMono
                    font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
                    font.letterSpacing: Math.round(AxoraHolo.fsMicro * 0.16 * AxoraState.fontScale)
                }
                Item {
                    width: 24; height: 24
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    Shape {
                        width: 24; height: 24
                        scale: 0.58
                        anchors.centerIn: parent
                        antialiasing: true
                        ShapePath {
                            strokeColor: AxoraTheme.muted
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: AxoraHolo.iconPaths.x }
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: panel.closed() }
                }
                }

            // content slot — anchors, not Layout: an invisible slot collapses a
            // layout, and the state message must keep the same geometry in
            // every state. The caller's list paints over the (transparent)
            // message when the model is empty.
            Item {
                id: slotItem
                anchors.fill: parent
                anchors.topMargin: 48
                anchors.bottomMargin: 30
                anchors.leftMargin: 18
                anchors.rightMargin: 18

                Text {
                    id: stateMsg
                    anchors.centerIn: parent
                    // Long server messages must wrap inside the card — an
                    // unwrapped line paints past the viewport and brackets.
                    width: parent.width - 36
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: panel.state !== "content"
                    text: panel.stateText()
                    color: (panel.state === "error" || panel.state === "offline")
                        ? AxoraHolo.warning : AxoraTheme.muted
                    font.family: AxoraTheme.fontMono
                    font.pixelSize: Math.round(AxoraHolo.fsSm * AxoraState.fontScale)
                    font.letterSpacing: Math.round(AxoraHolo.fsSm * 0.2 * AxoraState.fontScale)
                }
            }

            Text {
                text: "ESC — CLOSE"
                color: AxoraTheme.muted
                font.family: AxoraTheme.fontMono
                font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
                font.letterSpacing: Math.round(AxoraHolo.fsMicro * 0.24 * AxoraState.fontScale)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
            }
        }
    }
}
