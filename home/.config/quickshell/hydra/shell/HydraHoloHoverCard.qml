// ValkyxHoloHoverCard — the small live system window for the presence face.
// Every value reads the already-live ValkyxState metrics (the same
// expressions the HUD rails used); unknown reads show N/A. The signal row
// carries the voice level the right rail used to show. No new fetch,
// no new backend — shown on face hover, hidden on unhover by the host.
import QtQuick
import "../core"

Rectangle {
    width: 240
    height: 192
    radius: 10
    color: ValkyxHolo.bg
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
            Rectangle { width: 12; height: 2; color: ValkyxHolo.primary; x: 0; y: (index === 0) ? 0 : 10 }
            Rectangle { width: 2; height: 12; color: ValkyxHolo.primary; x: (index % 2 === 0) ? 0 : 10; y: 0 }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8
        Text {
            text: "SYSTEM — LIVE"
            color: ValkyxTheme.muted
            font.family: ValkyxTheme.fontMono
            font.pixelSize: Math.round(ValkyxHolo.fsMicro * ValkyxState.fontScale)
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
                    color: ValkyxTheme.muted
                    width: 34
                    font.family: ValkyxTheme.fontMono
                    font.pixelSize: Math.round(ValkyxHolo.fsMicro * ValkyxState.fontScale)
                    font.letterSpacing: 2
                }
                Text {
                    property var vals: [
                        (ValkyxState.cpuPct >= 0 ? ValkyxState.cpuPct.toFixed(0) + "%" : "N/A"),
                        (ValkyxState.memPct >= 0 ? ValkyxState.memPct.toFixed(0) + "%" : "N/A"),
                        "↑" + ValkyxState.netUpKbs.toFixed(0) + " ↓" + ValkyxState.netDownKbs.toFixed(0) + " KB/s",
                        ValkyxState.uptimeLine || "N/A"]
                    text: vals[index]
                    color: ValkyxTheme.text
                    width: 170
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    font.family: ValkyxTheme.fontMono
                    font.pixelSize: Math.round(ValkyxHolo.fsMicro * ValkyxState.fontScale)
                }
            }
        }
        // signal gauge (the right rail's content, kept live here)
        Row {
            width: 212
            spacing: 8
            Text {
                text: "SIG"
                color: ValkyxTheme.muted
                width: 34
                font.family: ValkyxTheme.fontMono
                font.pixelSize: Math.round(ValkyxHolo.fsMicro * ValkyxState.fontScale)
                font.letterSpacing: 2
            }
            Rectangle {
                width: 110
                height: 6
                radius: 3
                color: Qt.rgba(0, 0, 0, 0.4)
                border.color: ValkyxTheme.muted
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: Math.round(parent.width * level)
                    height: 6
                    radius: 3
                    color: ValkyxHolo.primary
                }
            }
            Text {
                text: level > 0 ? (level * 100).toFixed(0) + "%" : "N/A"
                color: ValkyxTheme.text
                width: 52
                horizontalAlignment: Text.AlignRight
                font.family: ValkyxTheme.fontMono
                font.pixelSize: Math.round(ValkyxHolo.fsMicro * ValkyxState.fontScale)
            }
        }
    }
}
