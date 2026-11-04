// AXORA OSD — right-edge vertical pill (Caelestia / smart-TV style).
// Shows volume / brightness / mic / media as a capsule with an accent fill
// rising from the bottom; scroll over it to change the value it represents.
import Quickshell
import QtQuick
import "../core"

PanelWindow {
    id: osd
    // A mapped layershell surface keeps the pointer, so the root visible must
    // follow the open state (never pinned to true).
    visible: AxoraState.osdMode !== ""
    focusable: AxoraState.osdMode !== ""
    anchors { right: true; top: true; bottom: true }
    margins { right: AxoraMetrics.l }
    color: "transparent"
    exclusiveZone: -1
    aboveWindows: true

    readonly property real pillW: 44
    readonly property real pillH: 168
    readonly property real barH: 96
    readonly property real barW: 6

    readonly property string glyph: ({
        "vol":   AxoraState.volPct === 0 ? "\uDB81\uDD81" : AxoraState.volPct < 33 ? "\uDB81\uDD7F" : AxoraState.volPct < 66 ? "\uDB81\uDD80" : "\uDB81\uDD7E",
        "bri":   "\uDB81\uDDA8",
        "mic":   AxoraState.micMuted ? "\uDB80\uDF6D" : "\uDB80\uDF6C",
        "media": "\uDB81\uDF5A"
    }[AxoraState.osdMode] || "")
    readonly property string label: ({
        "vol":   Math.round(AxoraState.volPct) + "%",
        "bri":   Math.round(AxoraState.briPct) + "%",
        "mic":   AxoraState.micMuted ? "Muted" : "Live",
        "media": ""
    }[AxoraState.osdMode] || "")
    // 0..1 fill. mic/media have no level, so they read as full/empty.
    // "vol" MUST be an explicit branch: falling through to the mic default
    // pinned the volume pill at 100% no matter what the real value was.
    readonly property real pct: AxoraState.osdMode === "vol" ? AxoraState.volPct / 100
                                  : AxoraState.osdMode === "bri" ? AxoraState.briPct / 100
                                  : AxoraState.osdMode === "media" ? 1
                                  : AxoraState.micMuted ? 0 : 1

    function nudge(dir) {
        if (AxoraState.osdMode === "vol")
            AxoraState.setVolume(Math.max(0, Math.min(100, AxoraState.volPct + dir * 5)))
        else if (AxoraState.osdMode === "bri")
            AxoraState.setBrightness(Math.max(0, Math.min(100, AxoraState.briPct + dir * 5)))
    }

    Rectangle {
        id: pill
        width: osd.pillW
        height: osd.pillH
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        radius: width / 2            // capsule family: r == min(w,h)/2
        color: AxoraMaterials.osdGlass
        border.color: AxoraMaterials.border
        border.width: 1

        Text {
            id: icon
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14
            text: osd.glyph
            color: AxoraTheme.accent
            font.family: AxoraTheme.fontMono
            font.pixelSize: Math.round(13 * AxoraState.fontScale)
        }

        // track
        Rectangle {
            id: track
            width: osd.barW
            height: osd.barH
            anchors.horizontalCenter: parent.horizontalCenter
            y: 38
            radius: width / 2
            color: AxoraTheme.tint(AxoraTheme.muted, "33")
        }

        // accent fill, rises from the bottom
        Rectangle {
            width: track.width
            height: track.height * osd.pct
            anchors.horizontalCenter: parent.horizontalCenter
            y: track.y + track.height - height
            radius: width / 2
            color: AxoraTheme.accent
            Behavior on height { NumberAnimation { duration: AxoraMotion.fast; easing.type: Easing.OutCubic } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 140
            text: osd.label
            color: AxoraTheme.text
            font.family: AxoraTheme.fontUI
            font.pixelSize: Math.round(11 * AxoraState.fontScale)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onWheel: (e) => osd.nudge(e.angleDelta.y > 0 ? 1 : -1)
        }

        // Fade the CONTENT, never the window: PanelWindow has no opacity and a
        // mapped-but-invisible layershell surface still holds the pointer, which
        // is how the closed OSD ends up eating clicks (see AxoraPowerMenu).
        opacity: AxoraState.osdMode !== "" ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: AxoraMotion.base; easing.type: Easing.OutCubic }
        }
    }
}