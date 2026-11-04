// HydraAssistantPresence — the two designed presence shapes, ported from the
// approved mockup (hydra-assistant/docs/mockups/presence-language.html; design
// spec §6). ONE SHAPE PER DIRECTION:
//     listening -> BLOB    organic mass, swells with YOUR mic level
//     speaking  -> PLEXUS  48-node network globe, flares with HIS tts level
// The desktop used to render two flat `radius: 42` circles here and the code
// even called the second one a "plexus stand-in" -- the shapes were
// indistinguishable. These are the real geometries. The node/edge tables below
// are the mockup's own SVG extracted verbatim, so the desktop globe is the
// approved one rather than a re-guess that drifts from it.
import QtQuick
import QtQuick.Shapes
import "../core"

Item {
    id: root
    property string stateName: "idle"
    property real level: 0
    // voice-active = TTS is actually sounding (1.5s cadence) vs idle (6.5s).
    property bool voiceActive: true
    property bool online: false

    implicitWidth: 84
    implicitHeight: 84
    readonly property real _dim: Math.min(1, 0.55 + level * 0.9)

    // state-change pulse: readable from across the room (away-status at a
    // glance). Token durations only; reduced motion collapses to a snap.
    SequentialAnimation {
        id: statePulse
        running: false
        NumberAnimation { target: root; property: "scale"; from: 1; to: 1.1;
            duration: HydraMotion.fast; easing.type: HydraMotion.curveOut }
        NumberAnimation { target: root; property: "scale"; from: 1.1; to: 1;
            duration: HydraMotion.base; easing.type: HydraMotion.curveOut }
    }
    onStateNameChanged: statePulse.restart()

    Canvas {
        id: plexus
        anchors.fill: parent
        visible: root.stateName === "listening"
        antialiasing: true
        scale: 1 + root.level * 0.09

        Behavior on scale {
            NumberAnimation { duration: HydraMotion.instant; easing.type: Easing.OutCubic }
        }

        // The mockup hardcoded its Hydra-green (#7ef0b8/#00c97e/#00A86B) as a
        // literal gradient. The shell ships 6 accent presets, so a literal here
        // left the plexus green while the blob followed the theme. Bright ->
        // mid -> accent keeps the same three-step read in every theme.
        readonly property color _c0: HydraTheme.tint(HydraTheme.accent, "vivid")
        readonly property color _c1: HydraTheme.accent
        readonly property color _c2: HydraTheme.tint(HydraTheme.accent, "mid")

        // 170 edges: x1,y1,x2,y2,baseOpacity,phase   (48 nodes: cx,cy,r,tier,o,phase; tier "1"=bright)
        property var _edges: [100,180,83,176.6,0.15,2.36,100,180,102.8,173.2,0.12,2.3,100,180,123.8,169.8,0.15,2.27,100,180,56,166.4,0.14,2.29,100,180,141.6,163,0.13,2.23,100,180,86.1,159.6,0.15,2.1,100,180,73.7,156.2,0.11,2.08,100,180,156.5,152.8,0.15,2.16,83,176.6,102.8,173.2,0.12,2.26,83,176.6,123.8,169.8,0.16,2.2,83,176.6,56,166.4,0.14,2.33,83,176.6,86.1,159.6,0.16,2.09,83,176.6,41.8,149.4,0.16,2.2,83,176.6,57.9,132.3,0.16,1.86,102.8,173.2,123.8,169.8,0.12,2.18,102.8,173.2,56,166.4,0.12,2.18,102.8,173.2,141.6,163,0.12,2.15,102.8,173.2,73.7,156.2,0.11,1.97,102.8,173.2,127.8,146,0.1,1.85,102.8,173.2,90.4,128.9,0.09,1.54,123.8,169.8,141.6,163,0.13,2.22,123.8,169.8,86.1,159.6,0.18,1.95,123.8,169.8,156.5,152.8,0.17,2.2,123.8,169.8,120.3,142.6,0.18,1.81,123.8,169.8,158,125.5,0.18,1.88,56,166.4,86.1,159.6,0.14,2.08,56,166.4,73.7,156.2,0.11,2.12,56,166.4,41.8,149.4,0.14,2.32,56,166.4,39.6,139.1,0.12,2.23,56,166.4,23.2,122.1,0.14,2.25,141.6,163,156.5,152.8,0.13,2.28,141.6,163,127.8,146,0.1,1.94,141.6,163,169.9,135.7,0.13,2.23,141.6,163,155.1,118.7,0.1,1.9,86.1,159.6,41.8,149.4,0.17,1.96,86.1,159.6,120.3,142.6,0.2,1.53,86.1,159.6,57.9,132.3,0.2,1.61,86.1,159.6,96.4,115.3,0.2,1.15,73.7,156.2,127.8,146,0.1,1.53,73.7,156.2,39.6,139.1,0.11,1.93,73.7,156.2,90.4,128.9,0.09,1.39,73.7,156.2,49.3,111.9,0.1,1.54,156.5,152.8,120.3,142.6,0.17,1.84,156.5,152.8,169.9,135.7,0.14,2.31,156.5,152.8,158,125.5,0.17,2.08,156.5,152.8,178.8,108.5,0.16,2.23,41.8,149.4,39.6,139.1,0.12,2.22,41.8,149.4,57.9,132.3,0.17,1.94,41.8,149.4,23.2,122.1,0.15,2.29,41.8,149.4,34.5,105.1,0.17,2.03,127.8,146,169.9,135.7,0.1,1.91,127.8,146,90.4,128.9,0.09,1.16,127.8,146,155.1,118.7,0.1,1.58,127.8,146,117.6,101.7,0.08,0.99,120.3,142.6,57.9,132.3,0.2,1.17,120.3,142.6,158,125.5,0.19,1.56,120.3,142.6,96.4,115.3,0.21,0.9,120.3,142.6,139.8,98.3,0.21,1.09,39.6,139.1,90.4,128.9,0.09,1.46,39.6,139.1,23.2,122.1,0.12,2.25,39.6,139.1,49.3,111.9,0.1,1.83,39.6,139.1,23.9,94.9,0.12,2.11,169.9,135.7,158,125.5,0.14,2.13,169.9,135.7,155.1,118.7,0.1,2.05,169.9,135.7,178.8,108.5,0.14,2.33,169.9,135.7,172.2,91.5,0.12,2.17,57.9,132.3,23.2,122.1,0.15,1.96,57.9,132.3,96.4,115.3,0.2,0.99,57.9,132.3,34.5,105.1,0.19,1.71,57.9,132.3,69.5,88.1,0.2,1.13,90.4,128.9,155.1,118.7,0.09,0.99,90.4,128.9,49.3,111.9,0.09,1.09,90.4,128.9,117.6,101.7,0.08,0.47,90.4,128.9,73.4,84.7,0.09,0.58,158,125.5,178.8,108.5,0.16,2.11,158,125.5,139.8,98.3,0.19,1.51,158,125.5,168.8,81.3,0.18,1.91,23.2,122.1,34.5,105.1,0.15,2.17,23.2,122.1,23.9,94.9,0.13,2.31,23.2,122.1,25.7,77.9,0.15,2.27,155.1,118.7,117.6,101.7,0.08,1.13,155.1,118.7,172.2,91.5,0.1,1.92,155.1,118.7,141,74.5,0.09,1.45,96.4,115.3,139.8,98.3,0.21,0.58,96.4,115.3,69.5,88.1,0.21,0.52,96.4,115.3,112.6,71.1,0.21,0.24,49.3,111.9,23.9,94.9,0.1,1.9,49.3,111.9,73.4,84.7,0.09,1.16,49.3,111.9,42.1,67.7,0.1,1.66,178.8,108.5,172.2,91.5,0.12,2.27,178.8,108.5,168.8,81.3,0.16,2.22,178.8,108.5,171.3,64.3,0.14,2.29,34.5,105.1,69.5,88.1,0.19,1.44,34.5,105.1,25.7,77.9,0.17,2.11,34.5,105.1,52.6,60.9,0.19,1.77,117.6,101.7,73.4,84.7,0.08,0.25,117.6,101.7,141,74.5,0.08,0.95,117.6,101.7,100.3,57.4,0.08,0.67,139.8,98.3,168.8,81.3,0.18,1.66,139.8,98.3,112.6,71.1,0.21,0.91,139.8,98.3,144,54,0.19,1.45,23.9,94.9,25.7,77.9,0.13,2.29,23.9,94.9,42.1,67.7,0.11,2.09,23.9,94.9,37.3,50.6,0.13,2.24,172.2,91.5,141,74.5,0.09,1.77,172.2,91.5,171.3,64.3,0.12,2.25,172.2,91.5,147.9,47.2,0.12,2.02,69.5,88.1,112.6,71.1,0.21,0.67,69.5,88.1,52.6,60.9,0.19,1.4,69.5,88.1,89.8,43.8,0.2,1.19,73.4,84.7,42.1,67.7,0.09,1.45,73.4,84.7,100.3,57.4,0.09,0.95,73.4,84.7,71.6,40.4,0.09,1.39,168.8,81.3,112.6,71.1,0.18,1.42,168.8,81.3,171.3,64.3,0.14,2.26,168.8,81.3,144,54,0.18,1.95,168.8,81.3,147.6,37,0.16,2.13,25.7,77.9,42.1,67.7,0.11,2.14,25.7,77.9,52.6,60.9,0.17,2.04,25.7,77.9,37.3,50.6,0.14,2.32,25.7,77.9,60.3,33.6,0.17,2.17,141,74.5,171.3,64.3,0.09,1.92,141,74.5,100.3,57.4,0.09,1.19,141,74.5,147.9,47.2,0.09,1.78,141,74.5,113.6,30.2,0.09,1.65,112.6,71.1,52.6,60.9,0.19,1.15,112.6,71.1,144,54,0.19,1.41,112.6,71.1,89.8,43.8,0.2,1.28,112.6,71.1,112.2,26.8,0.18,1.58,42.1,67.7,100.3,57.4,0.09,1.42,42.1,67.7,37.3,50.6,0.11,2.18,42.1,67.7,71.6,40.4,0.11,1.89,42.1,67.7,79.1,23.4,0.11,2.02,171.3,64.3,144,54,0.14,2.12,171.3,64.3,147.9,47.2,0.12,2.23,171.3,64.3,147.6,37,0.14,2.32,52.6,60.9,37.3,50.6,0.14,2.12,52.6,60.9,89.8,43.8,0.19,1.67,52.6,60.9,60.3,33.6,0.17,2.05,100.3,57.4,147.9,47.2,0.09,1.6,100.3,57.4,71.6,40.4,0.09,1.59,100.3,57.4,113.6,30.2,0.09,1.7,144,54,89.8,43.8,0.19,1.61,144,54,147.6,37,0.16,2.13,144,54,112.2,26.8,0.18,1.98,37.3,50.6,71.6,40.4,0.11,2.13,37.3,50.6,60.3,33.6,0.14,2.32,37.3,50.6,79.1,23.4,0.14,2.27,147.9,47.2,147.6,37,0.12,2.25,147.9,47.2,113.6,30.2,0.12,2.06,147.9,47.2,100,20,0.12,2.12,89.8,43.8,60.3,33.6,0.17,1.98,89.8,43.8,112.2,26.8,0.18,1.94,89.8,43.8,100,20,0.15,2.05,71.6,40.4,60.3,33.6,0.11,2.15,71.6,40.4,113.6,30.2,0.11,1.95,71.6,40.4,79.1,23.4,0.11,2.17,71.6,40.4,100,20,0.11,2.14,147.6,37,113.6,30.2,0.12,2.19,147.6,37,112.2,26.8,0.16,2.23,147.6,37,100,20,0.15,2.26,60.3,33.6,112.2,26.8,0.17,2.13,60.3,33.6,79.1,23.4,0.14,2.33,60.3,33.6,100,20,0.15,2.28,113.6,30.2,112.2,26.8,0.12,2.18,113.6,30.2,79.1,23.4,0.12,2.2,113.6,30.2,100,20,0.12,2.26,112.2,26.8,79.1,23.4,0.14,2.25,112.2,26.8,100,20,0.15,2.31,79.1,23.4,100,20,0.14,2.37]
        property var _nodes: [100,180,1.9,"1",0.59,2.4,83,176.6,2.08,"1",0.64,2.35,102.8,173.2,1.54,"1",0.49,2.2,123.8,169.8,2.25,"1",0.69,2.21,56,166.4,1.81,"1",0.57,2.39,141.6,163,1.6,"1",0.51,2.26,86.1,159.6,2.48,"0",0.75,1.83,73.7,156.2,1.33,"1",0.43,1.86,156.5,152.8,2.13,"1",0.65,2.32,41.8,149.4,2.17,"1",0.67,2.29,127.8,146,1.23,"1",0.4,1.61,120.3,142.6,2.63,"0",0.79,1.41,39.6,139.1,1.51,"1",0.48,2.16,169.9,135.7,1.73,"1",0.54,2.36,57.9,132.3,2.57,"0",0.78,1.59,90.4,128.9,1.07,"1",0.36,0.91,158,125.5,2.45,"0",0.74,1.9,23.2,122.1,1.94,"1",0.6,2.4,155.1,118.7,1.28,"1",0.42,1.75,96.4,115.3,2.78,"0",0.84,0.47,49.3,111.9,1.22,"1",0.4,1.56,178.8,108.5,2.02,"1",0.62,2.38,34.5,105.1,2.41,"1",0.73,1.97,117.6,101.7,1.02,"1",0.35,0.53,139.8,98.3,2.68,"0",0.81,1.19,23.9,94.9,1.63,"1",0.51,2.29,172.2,91.5,1.52,"1",0.49,2.18,69.5,88.1,2.72,"0",0.82,0.98,73.4,84.7,1.07,"1",0.36,0.92,168.8,81.3,2.31,"1",0.7,2.14,25.7,77.9,2.12,"1",0.65,2.33,141,74.5,1.18,"1",0.39,1.45,112.6,71.1,2.73,"0",0.82,0.95,42.1,67.7,1.4,"1",0.45,1.99,171.3,64.3,1.83,"1",0.57,2.39,52.6,60.9,2.48,"0",0.75,1.84,100.3,57.4,1.14,"1",0.38,1.28,144,54,2.45,"0",0.74,1.91,37.3,50.6,1.83,"1",0.57,2.39,147.9,47.2,1.49,"1",0.48,2.14,89.8,43.8,2.53,"0",0.77,1.71,71.6,40.4,1.39,"1",0.45,1.98,147.6,37,2.05,"1",0.63,2.37,60.3,33.6,2.13,"1",0.65,2.32,113.6,30.2,1.49,"1",0.48,2.13,112.2,26.8,2.24,"1",0.68,2.23,79.1,23.4,1.79,"1",0.56,2.38,100,20,1.9,"1",0.59,2.4]

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var s = width / 200          // viewBox is 0 0 200 200
            var beat = root.voiceActive ? (Math.sin(Date.now() / 240) * 0.5 + 0.5) : 0
            var dim = root._dim

            ctx.lineWidth = Math.max(0.5, 0.5 * s)
            var e = _edges
            for (var i = 0; i + 5 < e.length; i += 6) {
                var lo = e[i + 4]
                // quiet lines sit low; a wave of brightness travels core->rim
                var phase = e[i + 5]
                var wave = 0.5 + 0.5 * Math.sin((Date.now() / 1400) - phase * 6.28318)
                ctx.strokeStyle = _c0
                ctx.globalAlpha = Math.min(1, (lo + wave * (0.2 + dim * 0.55)) * dim)
                ctx.beginPath()
                ctx.moveTo(e[i] * s, e[i + 1] * s)
                ctx.lineTo(e[i + 2] * s, e[i + 3] * s)
                ctx.stroke()
            }
            var n = _nodes
            for (var j = 0; j + 5 < n.length; j += 6) {
                var o = n[j + 4]
                var ph = n[j + 5]
                var w = 0.5 + 0.5 * Math.sin((Date.now() / 1400) - ph * 6.28318)
                ctx.globalAlpha = Math.min(1, o * (0.55 + dim * 0.9))
                ctx.fillStyle = (n[j + 3] == "1") ? _c0 : _c1
                ctx.beginPath()
                ctx.arc(n[j] * s, n[j + 1] * s, Math.max(0.6, n[j + 2] * s), 0, 6.28318)
                ctx.fill()
            }
            ctx.globalAlpha = 1
        }

        // repaint while speaking (the wave) -- 20/s is plenty for a throb
        Timer {
            running: plexus.visible
            interval: 50
            repeat: true
            onTriggered: plexus.requestPaint()
        }
        SequentialAnimation on rotation {
            running: plexus.visible
            loops: Animation.Infinite
            // Very slow drift so the globe never reads as a static decal. Token, not a
            // literal: reduced motion collapses it instead of freezing the spin.
            NumberAnimation {
                from: 0; to: 360
                duration: HydraMotion.ambient * 100
                easing.type: Easing.Linear
            }
        }
    }


    // ---- speaking: the reactor ring (JARVIS polar shader, in canvas) -------
    // The reference approach (Core.tsx) is a fragment shader on one camera-facing
    // plane: everything is a function of radius + angle, so the eroded edge,
    // hairlines, dust and radar sweep come from value-noise fbm rather than
    // made geometry. Qt's ShaderEffect would work but needs a cached QSB per
    // frame here and there is no in-shell GLSL precedent; evaluating the same
    // math per-pixel into a small ImageData is the reliable port. 84x84 ~= 7k
    // px, cheap to repaint at ~12 Hz.
    Canvas {
        id: reactor
        anchors.fill: parent
        visible: root.stateName === "speaking"
        antialiasing: true
        scale: 1 + root.level * 0.06

        Behavior on scale {
            NumberAnimation { duration: HydraMotion.instant; easing.type: Easing.OutCubic }
        }

        function drawReactor(phase) {
            // Canvas 2D version of the JARVIS reactor ring (thinking/speaking).
            // This used to be a per-pixel ImageData port of the GLSL fragment
            // shader, but putImageData does not render in QML's Canvas, so use
            // the 2D arc/stroke path API instead -- the same ring geometry and
            // the same rotating sweep, drawn with arcs + a shadowed glow.
            var ctx = getContext("2d")
            var w = width, h = height
            if (w <= 0 || h <= 0) return
            var L = root.level
            var TAU = 6.283185, cx = w / 2, cy = h / 2
            var R = Math.min(w, h) * 0.5 * (0.68 + L * 0.05)
            ctx.clearRect(0, 0, w, h)
            ctx.lineCap = 'round'

            var acc = HydraTheme.accent
            var hot = HydraTheme.tint(HydraTheme.accent, 'vivid')

            // the disc + dark fill
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, TAU)
            ctx.fillStyle = HydraTheme.tint(HydraTheme.accent, 'ghost')
            ctx.fill()

            // main glowing ring
            ctx.save()
            ctx.shadowBlur = 9
            ctx.shadowColor = acc
            ctx.strokeStyle = hot
            ctx.lineWidth = Math.max(2, w * 0.045)
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, TAU); ctx.stroke()
            ctx.restore()

            // inner wall + hairlines
            ctx.lineWidth = 1
            ctx.strokeStyle = HydraTheme.tint(HydraTheme.accent, 'faint')
            ctx.beginPath(); ctx.arc(cx, cy, R * 0.86, 0, TAU); ctx.stroke()
            ctx.beginPath(); ctx.arc(cx, cy, R * 0.62, 0, TAU); ctx.stroke()

            // eroded rim: dashed outer ring that gets dimmer as level drops
            ctx.strokeStyle = HydraTheme.tint(acc, 'mid')
            ctx.shadowBlur = 0
            ctx.setLineDash([w * 0.05, w * 0.04])
            ctx.lineWidth = Math.max(1, w * 0.018)
            ctx.beginPath(); ctx.arc(cx, cy, R * 1.04, 0, TAU); ctx.stroke()
            ctx.setLineDash([])

            // radar sweep: bright arc rotating around the ring, sets with level
            var a0 = phase
            ctx.strokeStyle = hot
            ctx.lineWidth = Math.max(2, w * 0.06)
            ctx.save(); ctx.shadowBlur = 8; ctx.shadowColor = hot
            ctx.beginPath(); ctx.arc(cx, cy, R, a0, a0 + 1.35); ctx.stroke()
            ctx.restore()
            // its fading wake
            ctx.strokeStyle = HydraTheme.tint(acc, 'strong')
            ctx.lineWidth = Math.max(2, w * 0.04)
            ctx.beginPath(); ctx.arc(cx, cy, R, a0 - 2.2, a0 - 0.1); ctx.stroke()

            // dust motes sitting on the rim
            ctx.fillStyle = hot
            for (var k = 0; k < 10; k++) {
                var an = k * 0.63 + phase * 0.1
                var rr = R * (1.0 + 0.03 * Math.sin(k * 2.1 + phase))
                var dx = cx + Math.cos(an) * rr
                var dy = cy + Math.sin(an) * rr
                ctx.beginPath(); ctx.arc(dx, dy, Math.max(0.6, w * 0.008), 0, TAU); ctx.fill()
            }
        }


        onPaint: {
            var ph = (Date.now() / 1000) * 0.45
            drawReactor(ph)
        }

        Timer {
            running: reactor.visible && root.voiceActive
            interval: 85
            repeat: true
            onTriggered: reactor.requestPaint()
        }
    }

    // ---- everything else: the soft dot -----------------------------------
    Rectangle {
        anchors.centerIn: parent
        width: 22; height: 22; radius: 11
        visible: root.stateName !== "listening" && root.stateName !== "speaking"
        color: root.stateName === "thinking" ? HydraTheme.tint(HydraTheme.accent, "fill") : HydraTheme.accent
        border.color: HydraTheme.accent
        border.width: root.stateName === "needs-approval" ? 2 : 0
    }

    // ---- offline: subdued dashed ring around the shape -------------------
    // Muted, thin, motionless — the "no connection" read. Shown regardless
    // of stateName so the offline state is never ambiguous.
    Canvas {
        id: offlineRing
        anchors.fill: parent
        visible: !root.online
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = width / 2, cy = height / 2
            var R = Math.min(width, height) * 0.46
            ctx.strokeStyle = HydraTheme.tint(HydraTheme.muted, "faint")
            ctx.lineWidth = 1
            ctx.setLineDash([4, 4])
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, 6.28318); ctx.stroke()
            ctx.setLineDash([])
        }
    }
}
