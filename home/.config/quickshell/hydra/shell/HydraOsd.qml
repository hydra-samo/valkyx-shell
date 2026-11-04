// VALKYX OSD — right-edge vertical pill (Caelestia / smart-TV style).
// Shows volume / brightness / mic / media as a capsule with an accent fill
// rising from the bottom; scroll over it to change the value it represents.
import Quickshell
import QtQuick
import "../core"

PanelWindow {
    id: osd
    // A mapped layershell surface keeps the pointer, so the root visible must
    // follow the open state (never pinned to true).
    visible: ValkyxState.osdMode !== ""
    focusable: ValkyxState.osdMode !== ""
    anchors { right: true; top: true; bottom: true }
    margins { right: ValkyxMetrics.l }
    color: "transparent"
    exclusiveZone: -1
    aboveWindows: true

    readonly property real pillW: 44
    readonly property real pillH: 168
    readonly property real barH: 96
    readonly property real barW: 6

    readonly property string glyph: ({
        "vol":   ValkyxState.volPct === 0 ? "\uDB81\uDD81" : ValkyxState.volPct < 33 ? "\uDB81\uDD7F" : ValkyxState.volPct < 66 ? "\uDB81\uDD80" : "\uDB81\uDD7E",
        "bri":   "\uDB81\uDDA8",
        "mic":   ValkyxState.micMuted ? "\uDB80\uDF6D" : "\uDB80\uDF6C",
        "media": "\uDB81\uDF5A"
    }[ValkyxState.osdMode] || "")
    readonly property string label: ({
        "vol":   Math.round(ValkyxState.volPct) + "%",
        "bri":   Math.round(ValkyxState.briPct) + "%",
        "mic":   ValkyxState.micMuted ? "Muted" : "Live",
        "media": ""
    }[ValkyxState.osdMode] || "")
    // 0..1 fill. mic/media have no level, so they read as full/empty.
    // "vol" MUST be an explicit branch: falling through to the mic default
    // pinned the volume pill at 100% no matter what the real value was.
    readonly property real pct: ValkyxState.osdMode === "vol" ? ValkyxState.volPct / 100
                                  : ValkyxState.osdMode === "bri" ? ValkyxState.briPct / 100
                                  : ValkyxState.osdMode === "media" ? 1
                                  : ValkyxState.micMuted ? 0 : 1

    function nudge(dir) {
        if (ValkyxState.osdMode === "vol")
            ValkyxState.setVolume(Math.max(0, Math.min(100, ValkyxState.volPct + dir * 5)))
        else if (ValkyxState.osdMode === "bri")
            ValkyxState.setBrightness(Math.max(0, Math.min(100, ValkyxState.briPct + dir * 5)))
    }

    Rectangle {
        id: pill
        width: osd.pillW
        height: osd.pillH
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        radius: width / 2            // capsule family: r == min(w,h)/2
        color: ValkyxMaterials.osdGlass
        border.color: ValkyxMaterials.border
        border.width: 1

        Text {
            id: icon
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14
            text: osd.glyph
            color: ValkyxTheme.accent
            font.family: ValkyxTheme.fontMono
            font.pixelSize: Math.round(13 * ValkyxState.fontScale)
        }

        // track
        Rectangle {
            id: track
            width: osd.barW
            height: osd.barH
            anchors.horizontalCenter: parent.horizontalCenter
            y: 38
            radius: width / 2
            color: ValkyxTheme.tint(ValkyxTheme.muted, "33")
        }

        // accent fill, rises from the bottom
        Rectangle {
            width: track.width
            height: track.height * osd.pct
            anchors.horizontalCenter: parent.horizontalCenter
            y: track.y + track.height - height
            radius: width / 2
            color: ValkyxTheme.accent
            Behavior on height { NumberAnimation { duration: ValkyxMotion.fast; easing.type: Easing.OutCubic } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 140
            text: osd.label
            color: ValkyxTheme.text
            font.family: ValkyxTheme.fontUI
            font.pixelSize: Math.round(11 * ValkyxState.fontScale)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onWheel: (e) => osd.nudge(e.angleDelta.y > 0 ? 1 : -1)
        }

        // Fade the CONTENT, never the window: PanelWindow has no opacity and a
        // mapped-but-invisible layershell surface still holds the pointer, which
        // is how the closed OSD ends up eating clicks (see ValkyxPowerMenu).
        opacity: ValkyxState.osdMode !== "" ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: ValkyxMotion.base; easing.type: Easing.OutCubic }
        }
    }
}