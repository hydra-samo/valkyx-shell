// AxoraReactor — ONE unbroken torus. Phase = color + spin, never layout.
// Canvas 2D translation of the reference shader (docs/design/jarvis-ref-brief.md §2).
// GREEN accent family by mandate: phase tints derive from the AxoraHolo tokens,
// never from the reference's cyan/violet. Animation is STATE-DRIVEN from the
// single authoritative `stateName` (idle, dormant, listening, thinking, tooling,
// speaking, waking, offline, needs-approval): idle drifts at 0.10 spin, never
// full speed. The paint driver is paintTick() — called by AxoraAssistantUi's
// pump ONLY while the UI is open, so no timer runs at load and close->open
// never accumulates one.
import QtQuick
import "../core"

Canvas {
    id: reactor

    property string stateName: "idle"
    property real level: 0
    property color accent: AxoraHolo.primary
    property bool online: true
    property real reactorScale: 1.0

    readonly property var _phases: ({
        "idle":            { tint: Qt.darker(accent, 1.3),  spin: 0.10, breath: 0.08 },
        "dormant":         { tint: Qt.darker(accent, 1.3),  spin: 0.20, breath: 0.08 },
        "listening":       { tint: accent,                  spin: 1.1,  breath: 0.12 },
        "thinking":        { tint: AxoraHolo.bright,        spin: 2.8,  breath: 0.12 },
        "tooling":         { tint: AxoraHolo.bright,        spin: 3.6,  breath: 0.12 },
        "speaking":        { tint: Qt.lighter(accent, 1.5), spin: 1.4,  breath: 0.12 },
        "waking":          { tint: Qt.lighter(accent, 1.8), spin: 4.5,  breath: 0.12 },
        "offline":         { tint: Qt.darker(accent, 1.8),  spin: 0.05, breath: 0.05 },
        "needs-approval":  { tint: AxoraHolo.warning,       spin: 2.2,  breath: 0.12 }
    })
    readonly property var _phase: _phases[stateName] || _phases["idle"]

    // smoothing (reference §2.7) — uPhase is ACCUMULATED, never elapsedTime*level
    property real _level: 0
    property real _spin: 0.15
    property color _tint: accent
    property real _phaseAcc: 0
    // ambient wall-clock: drives sweep/dust/twinkle at a visible-but-calm rate
    // even when _spin is near zero. Without this, idle motion couples to _spin
    // (0.10) and the reactor is a still image (sweep = 5 min/rotation).
    property real _ambient: 0
    property real _openAcc: 0
    property real _lastTick: 0

    property var _wanderFrames: []
    property var _dust: []

    Component.onCompleted: {
        // 64 perturbation frames: per-angle radius offsets from wrapped sine noise.
        // Built per-angle so the ±π seam is continuous by construction.
        const frames = []
        for (let f = 0; f < 64; f++) {
            const offs = []
            for (let i = 0; i <= 64; i++) {
                const a = (i % 64) / 64 * 2 * Math.PI
                const n1 = Math.sin(a * 3 + f * 0.21) * 0.55 + Math.sin(a * 5 - f * 0.13) * 0.45
                const n2 = Math.sin(a * 9 + f * 0.40) * 0.5
                const n3 = Math.sin(a * 17 - f * 0.31) * 0.3
                offs.push(n1 * 0.055 + n2 * 0.020 + n3 * 0.010)
            }
            frames.push(offs)
        }
        _wanderFrames = frames
        // dust: 180 static motes clinging to the rim — positions baked once, alpha animates
        let seed = 9781
        const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647
        const dust = []
        for (let i = 0; i < 180; i++) {
            const ang = rnd() * 2 * Math.PI
            const rad = (0.74 + (rnd() - 0.5) * 0.06) / 0.74
            dust.push({ x: Math.cos(ang) * rad, y: Math.sin(ang) * rad,
                        r: 0.9 + rnd() * 1.6, p: rnd() * 6.28, a: 0.25 + rnd() * 0.55 })
        }
        _dust = dust
    }

    // The whole animation step + repaint, in ONE call. AxoraAssistantUi's pump
    // (running only while uiOpen) is the sole driver — no Timer of our own,
    // nothing at load, nothing left running across a close.
    function paintTick() {
        const now = Date.now()
        if (_lastTick === 0) _lastTick = now
        const dt = Math.min(0.05, (now - _lastTick) / 1000)
        _lastTick = now
        // local phase resolve: never let a state-name miss kill the paint loop
        const ph = reactor._phase || reactor._phases[reactor.stateName] || reactor._phases["idle"]
        const breathe = (Math.sin(_phaseAcc * 0.9) * 0.5 + 0.5) * ph.breath
        const want = Math.max(level, breathe)
        _level += (want - _level) * Math.min(1, dt * 8)
        _spin += (ph.spin - _spin) * Math.min(1, dt * 2)
        _tint = _lerpColor(_tint, ph.tint, Math.min(1, dt * 2.5))
        _phaseAcc += dt * (0.5 + _level * 0.7) * _spin
        _ambient += dt
        _openAcc += (1 - _openAcc) * Math.min(1, dt * 1.6)
        requestPaint()
    }

    function _rgba(c, a) { return Qt.rgba(c.r, c.g, c.b, Math.min(1, Math.max(0, a))) }
    function _lerpColor(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
    }
    function _wrapAngle(d) {
        while (d > Math.PI) d -= 2 * Math.PI
        while (d < -Math.PI) d += 2 * Math.PI
        return d
    }
    function _smoothstep(a, b, x) {
        const t = Math.min(1, Math.max(0, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }

    onPaint: {
        const ctx = getContext("2d")
        const cx = width / 2, cy = height / 2
        const S = Math.min(width, height) / 200 * reactorScale
        ctx.reset()
        ctx.translate(cx, cy)
        const L = _level, ph = _phaseAcc, amb = _ambient, tint = _tint, open = _openAcc
        // tinted highlight, never pure white (inlined: member-fn calls from
        // onPaint throw "Too many arguments" in this Qt build)
        const hot = Qt.rgba(Math.min(1, tint.r + (1 - tint.r) * 0.30),
                            Math.min(1, tint.g + (1 - tint.g) * 0.30),
                            Math.min(1, tint.b + (1 - tint.b) * 0.30), 1)
        const frame = _wanderFrames.length ? _wanderFrames[Math.floor(ph * 12) % 64] : null
        const R = (0.74 + L * 0.03) * 100 * S

        function ringPath(rBase, lineW, color, glow) {
            ctx.save()
            ctx.strokeStyle = color
            ctx.lineWidth = lineW
            if (glow > 0) { ctx.shadowColor = color; ctx.shadowBlur = glow } else { ctx.shadowBlur = 0 }
            const seg = 64
            for (let i = 0; i < seg; i++) {
                const off0 = frame ? frame[i] : 0, off1 = frame ? frame[i + 1] : 0
                // erode: eaten patches via per-segment alpha
                const erode = 0.45 + 0.6 * (0.5 + 0.5 * Math.sin(i * 0.7 + ph * 0.5))
                ctx.globalAlpha = Math.min(1, erode * color.a)
                ctx.beginPath()
                const rMid = (rBase + (off0 + off1) * 50 * S)
                const a0 = i / seg * 2 * Math.PI, a1 = (i + 1) / seg * 2 * Math.PI
                ctx.arc(0, 0, rMid, a0, a1)
                ctx.stroke()
            }
            ctx.restore()
        }

        // bloom: inner glow disc
        ctx.globalCompositeOperation = "lighter"
        const g = ctx.createRadialGradient(0, 0, 0, 0, 0, R * 0.75)
        g.addColorStop(0, _rgba(tint, (0.16 + L * 0.34) * open))
        g.addColorStop(1, _rgba(tint, 0))
        ctx.fillStyle = g
        ctx.fillRect(-R, -R, R * 2, R * 2)

        // heartbeat pulse rippling out from centre (ambient: ~12s period at idle)
        const pr = (amb * 0.08 % 1) * 0.40 * 100 * S
        if (pr > 2) {
            ctx.beginPath()
            ctx.arc(0, 0, pr, 0, 2 * Math.PI)
            ctx.strokeStyle = _rgba(tint, 0.45 * (1 - pr / (0.40 * 100 * S)) * open)
            ctx.lineWidth = 2 * S
            ctx.stroke()
        }

        // core disc + membrane + soft rim
        ctx.beginPath(); ctx.arc(0, 0, 0.385 * 100 * S, 0, 2 * Math.PI)
        ctx.fillStyle = _rgba(tint, (0.04 + L * 0.08) * open); ctx.fill()
        ctx.beginPath(); ctx.arc(0, 0, 0.385 * 100 * S, 0, 2 * Math.PI)
        ctx.strokeStyle = _rgba(Qt.lighter(tint, 1.3), (0.55 + L * 0.5) * open)
        ctx.lineWidth = 1.5 * S
        ctx.shadowColor = _rgba(tint, 0.8); ctx.shadowBlur = 14 * S
        ctx.stroke(); ctx.shadowBlur = 0

        // three inner hairlines
        for (const rr of [0.615, 0.560, 0.470]) {
            ctx.beginPath(); ctx.arc(0, 0, rr * 100 * S, 0, 2 * Math.PI)
            ctx.strokeStyle = _rgba(tint, (rr === 0.560 ? 0.36 : 0.48) * open)
            ctx.lineWidth = S; ctx.stroke()
        }

        // THE TORUS: eroded outer body → inner wall (tube read) → hot filament edge
        ringPath(R, 3.4 * S, _rgba(Qt.lighter(tint, 1.35), open), 16 * S)
        ringPath(R - 0.055 * 100 * S, 2.2 * S, _rgba(tint, 0.62 * open), 0)
        ringPath(R + 0.004 * 100 * S, 1.4 * S, _rgba(hot, open), 10 * S)

        // radar sweep: 40 stepped wedges, BOTH edges eased (a hard step cuts a radial seam).
        // Ambient-driven: one calm ~13s rotation at idle; spin-coupled ph would freeze it.
        const sweepA = (amb * 0.5) % (2 * Math.PI)
        const step = 2 * Math.PI / 40
        for (let i = 0; i < 40; i++) {
            const a = i * step
            const dA = _wrapAngle(a - sweepA)
            const wake = _smoothstep(-2.6, -0.15, dA) * (1 - _smoothstep(0, 0.22, dA))
            if (wake < 0.02) continue
            ctx.beginPath()
            ctx.arc(0, 0, R - 0.02 * 100 * S, a, a + step + 0.008)
            ctx.strokeStyle = _rgba(tint, wake * (0.55 + L * 0.45) * open)
            ctx.lineWidth = 7.5 * S
            ctx.stroke()
        }

        // dust: motes clinging to the rim, twinkling — the reference-accurate detail
        ctx.fillStyle = _rgba(hot, 1)
        for (const d of _dust) {
            const tw = 0.5 + 0.5 * Math.sin(amb * 2 + d.p)
            ctx.globalAlpha = d.a * tw * (1.4 + L) * 0.35 * open
            ctx.beginPath()
            ctx.arc(d.x * R, d.y * R, d.r * S, 0, 2 * Math.PI)
            ctx.fill()
        }
        ctx.globalAlpha = 1
        ctx.globalCompositeOperation = "source-over"

        // offline: a muted dashed ring around the torus — the "no connection"
        // read, drawn regardless of phase so the state is never ambiguous.
        if (!online) {
            ctx.save()
            ctx.strokeStyle = AxoraTheme.tint(AxoraTheme.muted, "faint")
            ctx.lineWidth = Math.max(1, S)
            ctx.setLineDash([4, 4])
            ctx.beginPath(); ctx.arc(0, 0, R * 1.08, 0, 2 * Math.PI); ctx.stroke()
            ctx.restore()
        }
    }
}
