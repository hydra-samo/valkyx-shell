pragma Singleton
// VALKYX materials — elevation tiers + border recipes (§2.2).
// Blur is applied compositor-side via layerrules on the quickshell namespace;
// the fill alpha controls how much blurred background shows through.
// Neutral charcoal fills only — accent NEVER tint a fill (hard rule: accent is
// solid borders/text/icons only, never a translucent wash).
import QtQuick

QtObject {
    // ── elevation tiers (§2.2) ── neutral alpha-first surfaces, independent of theme bg,
    // so panels never pick up a color cast (teal/olive). Theme color lives on text/icons.
    // surface-0: top bar + dock background (edge-docked → flatter, no drop shadow)
    // surface-1: launcher panel + control center (floating → soft drop shadow)
    // surface-2: nested surface (search input, list-item hover, popover, buttons/drawers)
    readonly property string surface0: ValkyxTheme.lightMode ? "#a8eceef0" : "#2d0f1112"
    readonly property string surface1: ValkyxTheme.lightMode ? "#b8eceef0" : "#3a0f1112"
    readonly property string surface2: ValkyxTheme.lightMode ? "#cceceef0" : "#4d0f1112"

    // ── backward-compatible aliases → mapped to tiers ──
    readonly property string hudGlass:  surface0
    readonly property string dockGlass: surface0
    readonly property string panelGlass: surface1
    readonly property string osdGlass:  surface1
    readonly property string tileGlass: surface2

    // ── hairline borders (accent-tinted lines, follow the live accent) ──
    readonly property color border: ValkyxTheme.lightMode
        ? Qt.rgba(0.55 + ValkyxTheme.accent.r * 0.08, 0.57 + ValkyxTheme.accent.g * 0.08, 0.59 + ValkyxTheme.accent.b * 0.08, 1)
        : Qt.rgba(0.16 + ValkyxTheme.accent.r * 0.08, 0.18 + ValkyxTheme.accent.g * 0.08, 0.19 + ValkyxTheme.accent.b * 0.08, 1)
    readonly property color borderActive: ValkyxTheme.accent
    readonly property color borderFaint: ValkyxTheme.lightMode
        ? Qt.rgba(0.78 + ValkyxTheme.accent.r * 0.03, 0.80 + ValkyxTheme.accent.g * 0.03, 0.82 + ValkyxTheme.accent.b * 0.03, 1)
        : Qt.rgba(0.10 + ValkyxTheme.accent.r * 0.03, 0.12 + ValkyxTheme.accent.g * 0.03, 0.13 + ValkyxTheme.accent.b * 0.03, 1)
}