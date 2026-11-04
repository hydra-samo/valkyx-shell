// HydraJarvisBoot — the power-up sequence. Wall-clock beats (NOT rAF: it
// throttles unfocused). Compressed to ~2.6s total (2.0s beats + 0.6s exit):
// the old 6.8s boot plus the 8s idle auto-close meant the window spent nearly
// all its life booting. Skippable by key or click, and it never blocks
// interaction for more than those 2.6s. Design: jarvis-ref-brief §4. GREEN
// accent family via HydraHolo tokens.
import QtQuick
import "../core"

Item {
    id: root
    property bool active: false
    property real elapsed: 0
    property bool _skipping: false

    signal finished()

    // beats at ~33% of the reference's 6.78s: 560 / 1120 / 1560 / 2000 ms
    readonly property int _b1: 560
    readonly property int _b2: 1120
    readonly property int _b3: 1560
    readonly property int _b4: 2000

    function start() {
        active = true
        _skipping = false
        elapsed = 0
        kernelStart = Date.now()
        cursorBlink.restart()
        forceActiveFocus()
    }
    function skip() {
        if (!active || _skipping) return
        _skipping = true
        elapsed = _b4 + 1
        exitFade.start()
    }
    function _beat() {
        if (elapsed < _b1) return 1
        if (elapsed < _b2) return 2
        if (elapsed < _b3) return 3
        if (elapsed < _b4) return 4
        return 0
    }
    function _beatProgress() {
        const b = _beat()
        const starts = [0, 0, _b1, _b2, _b3]
        const durs = [0, _b1, _b2 - _b1, _b3 - _b2, _b4 - _b3]
        if (b === 0) return 1
        return Math.min(1, (elapsed - starts[b]) / durs[b])
    }

    property double kernelStart: 0

    FrameAnimation {
        running: root.active && !root._skipping
        onTriggered: {
            root.elapsed = Date.now() - root.kernelStart
            if (root.elapsed >= root._b4 && !root._skipping) {
                root._skipping = true
                exitFade.start()
            }
        }
    }

    Timer {
        id: exitFade
        interval: 600
        onTriggered: {
            root.active = false
            root.finished()
        }
    }

    Timer {
        id: cursorBlink
        interval: 530
        repeat: true
        property bool on: false
        onTriggered: on = !on
    }

    visible: active || opacity > 0.01
    opacity: active ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: HydraMotion.ambient; easing.type: HydraMotion.curveIn } }

    focus: active
    Keys.onEscapePressed: skip()
    MouseArea {
        anchors.fill: parent
        enabled: root.active
        onClicked: root.skip()
    }

    Rectangle {
        anchors.fill: parent
        color: HydraHolo.bg
    }

    // ── BEAT 1: status frame + segments + log ─────────────────────────────
    Item {
        id: beat1Layer
        anchors.fill: parent
        visible: root._beat() === 1
        opacity: root._beat() === 1 ? 1 : (root.elapsed >= root._b1 ? 0.28 : 0)
        Behavior on opacity { NumberAnimation { duration: HydraMotion.ambient } }

        Rectangle {
            id: statusFrame
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.12
            width: Math.min(parent.width * 0.9, 1100)
            height: 120
            color: "transparent"

            // two opposite corner brackets (top-left + bottom-right) — the
            // HUD frame language, never four
            Item {
                width: 26; height: Math.min(58, parent.height * 0.42)
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: 26; height: 2; color: HydraHolo.primary; anchors.top: parent.top }
                Rectangle { width: 2; height: parent.height; color: HydraHolo.primary; anchors.left: parent.left }
            }
            Item {
                width: 26; height: Math.min(58, parent.height * 0.42)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: 26; height: 2; color: HydraHolo.primary; anchors.bottom: parent.bottom }
                Rectangle { width: 2; height: parent.height; color: HydraHolo.primary; anchors.right: parent.right }
            }

            Text {
                id: statusTitle
                anchors.horizontalCenter: parent.horizontalCenter
                y: 22
                text: "INITIATING SYSTEM"
                color: Qt.lighter(HydraTheme.text, 1.4)
                font.family: HydraTheme.fontMono
                font.pixelSize: Math.round(HydraHolo.fsXl * HydraState.fontScale)
                font.letterSpacing: 2.8
                Text {
                    visible: cursorBlink.on
                    text: "▌"
                    color: HydraHolo.primary
                    anchors.left: parent.right; anchors.leftMargin: 2
                    font: parent.font
                }
            }

            Row {
                id: segments
                anchors.horizontalCenter: parent.horizontalCenter
                y: 62
                spacing: 3
                readonly property real pct: Math.min(1, root.elapsed / 380)
                Repeater {
                    model: 22
                    Rectangle {
                        required property int index
                        width: Math.min(38, (statusFrame.width - 70) / 22)
                        height: 12
                        color: index / 22 < segments.pct ? HydraHolo.primary : "transparent"
                        border.color: Qt.rgba(HydraHolo.primary.r, HydraHolo.primary.g, HydraHolo.primary.b, 0.45)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: HydraMotion.instant } }
                    }
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 88
                spacing: 3
                readonly property int lines: Math.floor(Math.min(1, root.elapsed / 450) * 7) + 1
                Repeater {
                    model: ["MOUNT /dev/primer · hydra core",
                            "EXTEND SYSTEM MEMORY .......... OK",
                            "THEME ACCENT .................. OK",
                            "VOICE STACK whisper/piper ..... OK",
                            "WAKE MODEL .................... OK",
                            "CHECKSUM ...................... OK",
                            "RUN SYSTEM TOOL"]
                    Text {
                        required property string modelData
                        required property int index
                        visible: index < parent.lines
                        opacity: index < parent.lines ? 1 : 0
                        text: "› " + modelData
                        color: HydraTheme.muted
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                        font.letterSpacing: 0.8
                        Behavior on opacity { NumberAnimation { duration: HydraMotion.fast } }
                    }
                }
            }
        }
    }

    // ── BEATS 2-4: the canvas ring/mark/segments machine ──────────────────
    Canvas {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height) * 0.6
        height: width
        opacity: [2, 3, 4].indexOf(root._beat()) >= 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: HydraMotion.transition } }
        onPaint: {
            const ctx = getContext("2d")
            const w = width, h = height
            ctx.reset()
            ctx.translate(w / 2, h / 2)
            const S = w / 320          // fits the brief's 320-unit field
            const beat = root._beat()
            const p = root._beatProgress()
            const accent = HydraHolo.primary
            const ink = Qt.rgba(accent.r, accent.g, accent.b, 1)
            const soft = Qt.rgba(accent.r, accent.g, accent.b, 0.4)
            const hot = Qt.lighter(accent, 1.7)
            ctx.lineCap = "round"

            if (beat === 2) {
                // five dashed rings assembling inward (inner first), 50ms apart
                const rings = [
                    { r: 150, dash: [1, 3], lw: 1 },
                    { r: 128, dash: [2, 4], lw: 1 },
                    { r: 104, dash: [3, 6], lw: 1.2 },
                    { r: 84, dash: [40, 8, 12, 8], lw: 1.4 },
                    { r: 60, dash: [30, 6, 6, 6], lw: 1.6 }
                ]
                for (let i = 0; i < rings.length; i++) {
                    const local = Math.min(1, Math.max(0, (p * rings.length - i * 0.22) / 0.78))
                    if (local <= 0) continue
                    const r = rings[i].r * S * local
                    ctx.save()
                    ctx.globalAlpha = local * 0.85
                    ctx.setLineDash(rings[i].dash)
                    ctx.strokeStyle = ink
                    ctx.lineWidth = rings[i].lw
                    ctx.beginPath()
                    ctx.arc(0, 0, r, 0, Math.PI * 2)
                    ctx.stroke()
                    ctx.restore()
                }
                return
            }

            if (beat === 3) {
                // hydra mark schematic, self-drawing: hexagon + 3 petals, point-walked
                const hex = []
                for (let i = 0; i <= 6; i++) {
                    const a = -Math.PI / 2 + i * Math.PI / 3
                    hex.push([Math.cos(a) * 34 * S, Math.sin(a) * 34 * S])
                }
                strokeProgress(ctx, hex, Math.min(1, p * 1.3), soft, 1.6 * S, ink)
                for (let pt = 0; pt < 3; pt++) {
                    const a = -Math.PI / 2 + pt * (Math.PI * 2 / 3)
                    const cx = Math.cos(a) * 56 * S, cy = Math.sin(a) * 56 * S
                    const local = Math.min(1, Math.max(0, (p * 3 - 1.6 - pt * 0.45) / 0.9))
                    if (local <= 0) continue
                    ctx.save()
                    ctx.globalAlpha = local
                    ctx.translate(cx, cy)
                    ctx.rotate(pt * (Math.PI * 2 / 3))
                    ctx.beginPath()
                    ctx.ellipse(0, 0, 22 * S, 44 * S, Math.PI / 6, 0, Math.PI * 2)
                    ctx.strokeStyle = ink
                    ctx.lineWidth = 1.8 * S
                    ctx.stroke()
                    ctx.restore()
                }
                // callouts
                const co = Math.min(1, Math.max(0, (p - 0.55) / 0.4))
                if (co > 0) {
                    ctx.save()
                    ctx.globalAlpha = co
                    ctx.fillStyle = soft
                    for (const side of [-1, 1]) {
                        ctx.setLineDash([3, 4])
                        ctx.beginPath()
                        ctx.arc(side * 118 * S, 0, 26 * S, 0, Math.PI * 2)
                        ctx.strokeStyle = ink
                        ctx.lineWidth = 1
                        ctx.stroke()
                        ctx.setLineDash([])
                        ctx.beginPath()
                        ctx.arc(side * 118 * S, 0, 3 * S, 0, Math.PI * 2)
                        ctx.fillStyle = ink
                        ctx.fill()
                        ctx.beginPath()
                        ctx.moveTo(side * 96 * S, 0)
                        ctx.lineTo(side * 60 * S, 0)
                        ctx.stroke()
                    }
                    ctx.restore()
                }
                return
            }

            if (beat === 4) {
                // hex core lights up; 16 radial spokes fill clockwise from -90°
                const glow = Math.min(1, p)
                const n = 16
                for (let i = 0; i < n; i++) {
                    const on = (i + 1) / n <= glow * 1.05
                    const a = -Math.PI / 2 + i * (Math.PI * 2 / n)
                    ctx.save()
                    ctx.rotate(a)
                    ctx.globalAlpha = on ? 0.95 : 0.3
                    const grad = ctx.createLinearGradient(0, -58 * S, 0, -84 * S)
                    grad.addColorStop(0, on ? hot : accent)
                    grad.addColorStop(1, Qt.rgba(accent.r, accent.g, accent.b, 0.2))
                    ctx.fillStyle = grad
                    ctx.fillRect(-4 * S, -84 * S, 8 * S, 26 * S)
                    ctx.restore()
                }
                ctx.save()
                ctx.globalAlpha = 0.3 + glow * 0.6
                ctx.strokeStyle = ink
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.arc(0, 0, 90 * S, 0, Math.PI * 2)
                ctx.stroke()
                ctx.restore()
                // hex core
                ctx.save()
                ctx.globalAlpha = glow
                ctx.beginPath()
                for (let i = 0; i < 6; i++) {
                    const a = -Math.PI / 2 + i * Math.PI / 3
                    const x = Math.cos(a) * 30 * S, y = Math.sin(a) * 30 * S
                    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                }
                ctx.closePath()
                ctx.fillStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.45 * glow)
                ctx.fill()
                ctx.strokeStyle = hot
                ctx.lineWidth = 2.4
                ctx.shadowColor = accent
                ctx.shadowBlur = 26 * glow
                ctx.stroke()
                ctx.restore()
                return
            }
        }

        // walk a polyline to drawProgress, alpha-ramping each subsequent point
        function strokeProgress(ctx, pts, prog, pre, preW, ink) {
            const total = pts.length - 1
            const upto = prog * total
            for (let i = 0; i < total; i++) {
                const t = Math.min(1, Math.max(0, upto - i))
                if (t <= 0) break
                const a = pts[i], b = pts[i + 1]
                ctx.globalAlpha = 0.35 + t * 0.6
                ctx.strokeStyle = ink
                ctx.lineWidth = preW
                ctx.beginPath()
                ctx.moveTo(a[0], a[1])
                ctx.lineTo(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
                ctx.stroke()
            }
        }
    }

    // H Y D R A resolving last (beat 2, second half)
    Text {
        anchors.centerIn: parent
        visible: root._beat() === 2
        text: "H Y D R A"
        color: Qt.lighter(HydraHolo.primary, 1.5)
        font.family: HydraTheme.fontMono
        font.pixelSize: Math.round(HydraHolo.fsDisplay * HydraState.fontScale)
        font.letterSpacing: 1.4 - 1.0 * Math.min(1, Math.max(0, (root.elapsed - root._b1 - 250) / 250))
        font.weight: Font.Medium
    }
}
