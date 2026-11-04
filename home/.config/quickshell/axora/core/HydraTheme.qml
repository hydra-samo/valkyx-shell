pragma Singleton
// AXORA visual identity — the only place color/font values live.
import QtQuick

QtObject {
    // palette — accent + bg family are mutable (theme picker changes them)
    property color accent: "#00A86B"
    readonly property color accentDim: Qt.rgba(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 1)
    readonly property color accentFaint: Qt.rgba(accent.r * 0.08, accent.g * 0.08, accent.b * 0.08, 1)
    property color bg: "#0a1210"
    readonly property string bgGlass: "#e6" + bg.toString().substring(1)   // alpha-first, tracks bg
    property color surface: "#101614"
    property color field: "#141d19"
    // adaptive typography: flip to dark-on-light when the wallpaper is bright,
    // keep light-on-dark otherwise (auto-detected, no manual light mode).
    property bool lightMode: false
    readonly property color text: lightMode ? "#15181a" : "#e6eae8"
    // muted = grey tinted by the live accent (sliders/toggles/lines inherit the
    // theme + wallpaper accent everywhere instead of a neutral olive).
    readonly property color muted: lightMode
        ? Qt.rgba(0.15 + accent.r * 0.12, 0.17 + accent.g * 0.12, 0.16 + accent.b * 0.12, 1)
        : Qt.rgba(0.40 + accent.r * 0.35, 0.43 + accent.g * 0.35, 0.40 + accent.b * 0.35, 1)
    readonly property color danger: "#c96a6a"
    readonly property color warning: "#d0a86a"
    property color line: "#1a2420"

    // adaptive scrollbar thumb — follows TEXT luminance (dark on light surfaces,
    // light on dark), NOT the accent-tinted muted (which inverts on light accents).
    readonly property color scrollThumb: lightMode
        ? Qt.rgba(0.10, 0.12, 0.11, 0.40)
        : Qt.rgba(0.90, 0.93, 0.91, 0.35)

    // adaptive light-flip for solid backgrounds (chips, fields, separators)
    readonly property color surfaceFill: lightMode ? "#e8ebea" : surface
    readonly property color fieldFill: lightMode ? "#f0f2f1" : field
    readonly property color lineFill: lightMode ? "#c9cecc" : line

    // typography
    readonly property string fontUI: "Space Grotesk"
    readonly property string fontMono: "CaskaydiaCove Nerd Font"

    // semantic
    readonly property color textOnAccent: "#04140d"

    // named themes — accent + bg family, applied live by the picker
    property var themes: [
        { name: "Axora", accent: "#00A86B", bg: "#0a1210", surface: "#101614", field: "#141d19", line: "#1a2420" },
        { name: "Violet", accent: "#7C4DFF", bg: "#0d0a14", surface: "#141018", field: "#181420", line: "#221c2e" },
        { name: "Ocean", accent: "#2196F3", bg: "#0a1016", surface: "#10161c", field: "#141c24", line: "#1c2834" },
        { name: "Ember", accent: "#FF5252", bg: "#140a0a", surface: "#1a1010", field: "#221414", line: "#2e1c1c" },
        { name: "Amber", accent: "#FF9800", bg: "#14100a", surface: "#1a1610", field: "#221c14", line: "#2e261c" },
        { name: "Cyan", accent: "#00BCD4", bg: "#0a1214", surface: "#10181a", field: "#141e20", line: "#1c2a2e" }
    ]

    // Repeater CANNOT render a JS array of objects — `modelData` never arrives and
    // the delegate produces nothing at all, silently. Only a string array (or a real
    // ListModel) works. So every theme picker iterates this and resolves by name.
    property var themeNames: ["Axora", "Violet", "Ocean", "Ember", "Amber", "Cyan"]
    function themeByName(name) {
        for (const t of themes) if (t.name === name) return t
        return null
    }

    // ── alpha palette (GLOBAL, shared by every theme) ──
    // Qt parses 8-digit hex as #AARRGGBB, so `color + "NN"` scrambles channels
    // (olive). NEVER append alpha to a hex; use tint() with a named level: the
    // layer appears once here, applies to ALL themes (present + future) via
    // their accent/surface, and works on any color you pass as `c`.
    readonly property var alphaLevels: {
        "ghost": 0x18 / 255,    // .094 barely-there (scrims, dust)
        "faint": 0x22 / 255,    // .133 row/selection glow
        "soft":  0x26 / 255,    // .149 hover edges
        "mid":   0x33 / 255,    // .200 tinted plates
        "rest":  0x44 / 255,    // .267 calm fills
        "fill":  0x55 / 255,    // .333 slider fills / toggle tracks
        "strong":0x66 / 255,    // .400 borders wash
        "vivid": 0x88 / 255,    // .533 emphatic highlight
        "glass": 0x99 / 255     // .600 near-solid tint
    }
    // named-alpha resolver. `tint(AxoraTheme.accent, "fill")` — name is global
    // and theme-agnostic. Also accepts a raw 2-digit hex ("55") for one-offs;
    // NEVER pass a bare color+hex string concat — that is the olive bug.
    function tint(c, levelOrHex) {
        const v = typeof levelOrHex === "string"
            ? (alphaLevels[levelOrHex] ?? parseInt(levelOrHex, 16) / 255)
            : levelOrHex
        return Qt.rgba(c.r, c.g, c.b, typeof v === "number" ? v : 0.2)
    }

    function applyTheme(name) {
        for (const t of themes) {
            if (t.name === name) {
                accent = t.accent; bg = t.bg; surface = t.surface; field = t.field; line = t.line
                return
            }
        }
    }

    // Apply an arbitrary palette entry (axora preset OR omarchy catalog theme).
    // Same fields the picker/cycle use; `light` flips the adaptive text family.
    function applyEntry(e) {
        if (e.accent) accent = e.accent
        if (e.bg) bg = e.bg
        if (e.surface) surface = e.surface
        if (e.field) field = e.field
        if (e.line) line = e.line
        if (e.light !== undefined) lightMode = e.light
    }
}