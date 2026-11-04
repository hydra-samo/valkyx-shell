// HydraHolo — the assistant UI's token singleton: the fixed emerald palette,
// the scanline layer's one opacity, and the type scale. The assistant surface
// is the BRAND surface: it does NOT follow the desktop theme presets, so the
// palette is literals here, not aliases of HydraTheme. Registered in
// core/qmldir; consumed via `import "../core"`.
pragma Singleton
import QtQuick

QtObject {
    // ── palette (theme-following identity) ──
    // The assistant is a BRAND surface no longer: the whole window follows
    // the desktop theme (user override). Geometry (plexus/ring/brackets)
    // is untouched — only color derives from HydraTheme.accent, so the
    // default Hydra theme renders exactly the old emerald. Amber/red stay
    // reserved literals (approval = the ONE warning, red = deny only).
    readonly property color bg: HydraTheme.bg          // the glass field
    readonly property color deep: Qt.darker(HydraTheme.accent, 3.0) // structural fills
    readonly property color primary: HydraTheme.accent // borders, text, icons, active marks
    readonly property color bright: Qt.lighter(HydraTheme.accent, 1.5) // hot states (thinking/tooling/waking)
    // amber/red are reserved for REAL warnings/errors only. The only warning
    // state is needs-approval; there is no error state in the state machine.
    readonly property color warning: "#D0A86A"
    readonly property color error: "#C96A6A"

    // ── scanline layer ──
    // 1px black every 4px at alpha 0.04, painted ONCE (never per-frame).
    // 0.04 is the strongest line that stays invisible under 10px type at any
    // fontScale — at 0.06+ the lines start to shimmer against bright text.
    readonly property real scanAlpha: 0.04

    // ── board grid ──
    // 1px lines every gridStep at gridAlpha, painted once into the treatments
    // layer: a near-invisible blackboard under the side popups. 0.03 white
    // stays texture-only on the #050807 glass at any fontScale.
    readonly property real gridAlpha: 0.03
    readonly property int gridStep: 46

    // ── lucide icons (MIT, baked path data, 24x24 viewBox) ──
    // Stroke icons only: strokeWidth 2, round caps, transparent fill.
    // Multi-element glyphs are concatenated into ONE PathSvg `d` (subpaths);
    // <circle> elements are pre-converted to arc subpaths; <rect> bars to
    // sharp-corner subpaths (rx <= 1 vanishes at glyph size). Single source
    // for every Holo icon — files read HydraHolo.iconPaths.<name>.
    readonly property var iconPaths: ({
        chat: "M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719",
        news: "M15 18h-5 M18 14h-8 M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-4 0v-9a2 2 0 0 1 2-2h2 M10 6h8v4h-8Z",
        music: "M9 18V5l12-2v13 M3 18a3 3 0 1 0 6 0a3 3 0 1 0-6 0 M15 16a3 3 0 1 0 6 0a3 3 0 1 0-6 0",
        camera: "M13.997 4a2 2 0 0 1 1.76 1.05l.486.9A2 2 0 0 0 18.003 7H20a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.997a2 2 0 0 0 1.759-1.048l.489-.904A2 2 0 0 1 10.004 4z M9 13a3 3 0 1 0 6 0a3 3 0 1 0-6 0",
        x: "M18 6 6 18 m6 6 12 12",
        arrowUp: "m5 12 7-7 7 7 M12 19V5",
        arrowLeft: "m12 19-7-7 7-7 M19 12H5",
        check: "M20 6 9 17l-5-5",
        pause: "M14 3h5v18h-5Z M5 3h5v18h-5Z",
        play: "M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z",
        next: "M21 4v16 M6.029 4.285A2 2 0 0 0 3 6v12a2 2 0 0 0 3.029 1.715l9.997-5.998a2 2 0 0 0 .003-3.432z",
        apps: "M3 3h7v7H3z M14 3h7v7h-7z M14 14h7v7h-7z M3 14h7v7h-7z",
        maximize: "M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3",
        mic: "M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z M19 10v2a7 7 0 0 1-14 0v-2 M12 19v3"
    })

    // ── type scale (scale-1 px) ──
    // Every use is Math.round(N * HydraState.fontScale); nothing renders
    // below 10px at scale 1. One scale for the whole assistant UI — no fixed
    // sizes, no second regime.
    readonly property int fsMicro: 10   // labels, chips, metric readouts
    readonly property int fsTiny: 11    // dense mono (steps, memory rows)
    readonly property int fsSm: 12      // rail items, state captions
    readonly property int fsBody: 13    // chat bubbles, composer, page titles
    readonly property int fsMd: 14      // decoder log, reply line
    readonly property int fsLg: 16      // send control
    readonly property int fsXl: 20      // identity line, boot status title
    readonly property int fsDisplay: 24 // boot brand resolve
}
