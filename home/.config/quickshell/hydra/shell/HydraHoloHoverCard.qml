// HydraHoloHoverCard — the small live system window for the presence face.
// Every value reads the already-live HydraState metrics (the same
// expressions the HUD rails used); unknown reads show N/A. The signal row
// carries the voice level the right rail used to show. No new fetch,
// no new backend — shown on face hover, hidden on unhover by the host.
import QtQuick
import "../core"

Rectangle {
    width: 240
    height: 192
    radius: 10
    color: HydraHolo.bg
    border.color: Qt.rgba(1, 1, 1, 0.22)
    border.width: 1

    // 0..1 voice level, bound by the host (live only while mic is live)
    property real level: 0

    // HUD corner brackets — exactly TWO: top-left + bottom-right
    Repeater {
        model: 2
        delegate: Item {
            width: 12; height: 12
            x: (index % 2 === 0) ? 5 : parent.width - 17
            y: (index === 0) ? 5 : parent.height - 17
            Rectangle { width: 12; height: 2; color: HydraHolo.primary; x: 0; y: (index === 0) ? 0 : 10 }
            Rectangle { width: 2; height: 12; color: HydraHolo.primary; x: (index % 2 === 0) ? 0 : 10; y: 0 }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8
        Text {
            text: "SYSTEM — LIVE"
            color: HydraTheme.muted
            font.family: HydraTheme.fontMono
            font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
            font.letterSpacing: 2
        }
        Repeater {
            model: ["CPU", "RAM", "NET", "UP"]
            delegate: Row {
                required property string modelData
                required property int index
                width: 212
                spacing: 8
                Text {
                    text: modelData
                    color: HydraTheme.muted
                    width: 34
                    font.family: HydraTheme.fontMono
                    font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                    font.letterSpacing: 2
                }
                Text {
                    property var vals: [
                        (HydraState.cpuPct >= 0 ? HydraState.cpuPct.toFixed(0) + "%" : "N/A"),
                        (HydraState.memPct >= 0 ? HydraState.memPct.toFixed(0) + "%" : "N/A"),
                        "↑" + HydraState.netUpKbs.toFixed(0) + " ↓" + HydraState.netDownKbs.toFixed(0) + " KB/s",
                        HydraState.uptimeLine || "N/A"]
                    text: vals[index]
                    color: HydraTheme.text
                    width: 170
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    font.family: HydraTheme.fontMono
                    font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                }
            }
        }
        // signal gauge (the right rail's content, kept live here)
        Row {
            width: 212
            spacing: 8
            Text {
                text: "SIG"
                color: HydraTheme.muted
                width: 34
                font.family: HydraTheme.fontMono
                font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                font.letterSpacing: 2
            }
            Rectangle {
                width: 110
                height: 6
                radius: 3
                color: Qt.rgba(0, 0, 0, 0.4)
                border.color: HydraTheme.muted
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: Math.round(parent.width * level)
                    height: 6
                    radius: 3
                    color: HydraHolo.primary
                }
            }
            Text {
                text: level > 0 ? (level * 100).toFixed(0) + "%" : "N/A"
                color: HydraTheme.text
                width: 52
                horizontalAlignment: Text.AlignRight
                font.family: HydraTheme.fontMono
                font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
            }
        }
    }
}
