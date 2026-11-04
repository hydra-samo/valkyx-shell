// HydraJarvisHud — HUD chrome for the assistant surface: identity line, real
// status, angular geometry. The presence face stands clean: systems live in
// the hover card + system panel, the signal gauge in the hover card, the
// transcript in the chat popup — no rails, no decoder band here.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../core"

Item {
    id: root
    anchors.fill: parent

    property string stateName: "idle"
    property real level: 0
    property bool online: true
    property string face: "presence"
    // the currently open docked page ("" = none) — drives the chrome X
    property string dockPage: ""
    // the currently open side popup ("" = none) — drives launcher highlight
    property string activePopup: ""

    signal popupRequested(string slug)
    signal closeDockRequested()
    signal windowModeRequested()

    // signal is only meaningful while the mic is live (kept: the hover
    // card's signal row binds through the Ui, same source)
    readonly property bool hasSignal: root.stateName === "listening" || root.stateName === "speaking"

    // ── phase color (single source of truth) ──────────────────────────────
    // Emerald family only: amber is reserved for the ONE real warning
    // (needs-approval); thinking/tooling read as hot bright, not warnings.
    readonly property color phaseColor: (function() {
        switch (stateName) {
        case "listening": return HydraHolo.primary
        case "speaking": return Qt.lighter(HydraHolo.primary, 1.5)
        case "thinking": return HydraHolo.bright
        case "tooling": return HydraHolo.bright
        case "waking": return Qt.lighter(HydraHolo.primary, 1.8)
        case "needs-approval": return HydraHolo.warning
        default: return Qt.darker(HydraHolo.primary, 1.6) // idle, dormant, offline
        }
    })()

    // ── top chrome: identity + real status + tool badge ────────────────────
    Rectangle {
        id: topChrome
        width: parent.width
        height: 44
        color: "transparent"
        anchors.top: parent.top

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 92
            anchors.rightMargin: 92
            spacing: 16

            // identity line
            Text {
                text: "H Y D R A"
                color: HydraHolo.bright
                font.family: HydraTheme.fontUI
                font.pixelSize: Math.round(HydraHolo.fsXl * HydraState.fontScale)
                font.letterSpacing: Math.round(HydraHolo.fsXl * 0.42 * HydraState.fontScale)
                font.weight: Font.DemiBold
            }

            // live status chip — phase-colored border/text.
            // Width follows the text: a widthless Rectangle in a RowLayout
            // collapses to 0 and the 200px label overflows left over the
            // wordmark ("HYDRAIDLE"). implicitWidth keeps chip+text together.
            Rectangle {
                height: 26
                radius: 13
                implicitWidth: statusTxt.implicitWidth + 28
                Layout.leftMargin: 24
                color: "transparent"
                border.color: root.phaseColor
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: statusTxt
                    anchors.centerIn: parent
                    text: root.online ? root.stateName.toUpperCase() : "OFFLINE"
                    color: root.phaseColor
                    font.family: HydraTheme.fontMono
                    font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                    font.letterSpacing: Math.round(HydraHolo.fsMicro * 0.16 * HydraState.fontScale)
                }
            }

            Item { Layout.fillWidth: true }

            // tool badge — a tool is actively running
            Rectangle {
                width: 240
                height: 22
                radius: 11
                color: "transparent"
                border.color: HydraHolo.deep
                border.width: 1
                visible: HydraAssistantApi.stepsModel.count > 0
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    clip: true
                    elide: Text.ElideRight
                    text: "ACCESSING · " + (HydraAssistantApi.stepsModel.count > 0
                        ? (HydraAssistantApi.stepsModel.get(HydraAssistantApi.stepsModel.count - 1).body || "")
                        : "")
                    color: HydraHolo.bright
                    font.family: HydraTheme.fontMono
                    font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                    font.letterSpacing: Math.round(HydraHolo.fsTiny * 0.24 * HydraState.fontScale)
                }
            }

            // side-popup launchers — presence face only, Lucide stroke
            // icons (24 viewBox, transparent fill). The open one reads
            // emerald, the rest stay muted.
            Row {
                spacing: 4
                visible: root.face === "presence"
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: ["chat", "news", "music", "camera"]
                    delegate: Item {
                        required property string modelData
                        property string slug: modelData
                        property bool isActive: root.activePopup === slug
                        width: 32
                        height: 32
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: "transparent"
                            border.color: isActive ? HydraHolo.primary : "transparent"
                            border.width: 1
                        }
                        Shape {
                            width: 24; height: 24
                            anchors.centerIn: parent
                            antialiasing: true
                            ShapePath {
                                strokeColor: isActive ? HydraHolo.primary : HydraTheme.muted
                                strokeWidth: 2
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                joinStyle: ShapePath.RoundJoin
                                PathSvg { path: HydraHolo.iconPaths[slug] }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.popupRequested(slug)
                        }
                    }
                }

                // mic mute — always visible (muted reads red, same as the
                // desktop bar). Kills the mic for the voice daemon too.
                Item {
                    width: 32
                    height: 32
                    visible: root.face === "presence"
                    Layout.alignment: Qt.AlignVCenter
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "transparent"
                        border.color: HydraState.micMuted ? HydraHolo.error : "transparent"
                        border.width: 1
                    }
                    Shape {
                        width: 24; height: 24
                        anchors.centerIn: parent
                        antialiasing: true
                        ShapePath {
                            strokeColor: HydraState.micMuted ? HydraHolo.error
                                : (hudMicHover.containsMouse ? HydraHolo.primary : HydraTheme.muted)
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: HydraHolo.iconPaths.mic }
                        }
                    }
                    MouseArea {
                        id: hudMicHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: HydraState.toggleMic()
                    }
                }
            }

            // dock close: the docked pages have no header of their own, so
            // the top chrome carries its X (Lucide x, same Shape pattern as
            // the panels) -> back to the clean presence face.
            Item {
                width: 32
                height: 32
                visible: root.dockPage !== ""
                Layout.alignment: Qt.AlignVCenter
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: dockHover.containsMouse ? HydraMaterials.tileGlass : "transparent"
                }
                Shape {
                    width: 24; height: 24
                    scale: 0.58
                    anchors.centerIn: parent
                    antialiasing: true
                    ShapePath {
                        strokeColor: HydraTheme.muted
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: HydraHolo.iconPaths.x }
                    }
                }
                MouseArea {
                    id: dockHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.closeDockRequested()
                }
            }

            // fullscreen toggle: the window boots fullscreen (hologram wall),
            // this drops it to a normal floating window and back.
            Item {
                width: 32
                height: 32
                Layout.alignment: Qt.AlignVCenter
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: modeHover.containsMouse ? HydraMaterials.tileGlass : "transparent"
                }
                Shape {
                    width: 24; height: 24
                    scale: 0.58
                    anchors.centerIn: parent
                    antialiasing: true
                    ShapePath {
                        strokeColor: modeHover.containsMouse ? HydraHolo.primary : HydraTheme.muted
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: HydraHolo.iconPaths.maximize }
                    }
                }
                MouseArea {
                    id: modeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.windowModeRequested()
                }
            }
        }
    }

    // ── bottom decoder log: DELETED (dedup) ──
    // The transcript lives in the chat popup; the systems readouts in the
    // hover card + system panel; the signal gauge in the hover card.
    // The presence face stands clean: identity + status + icon launchers.
}
