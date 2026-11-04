pragma Singleton
// AXORA metrics — the single source of truth for dimension/spacing/radius tokens.
// Per spec §2.3/§2.4: strict radius scale (sm/md/lg/xl/full) and spacing scale (4/8/12/16/24/32).
// Components reference these tokens, never one-off literals.
import QtQuick

QtObject {
    // ── spacing scale (§2.4): 4 / 8 / 12 / 16 / 24 / 32 ──
    readonly property int xs: 4
    readonly property int s: 8
    readonly property int m: 12
    readonly property int l: 16
    readonly property int xl: 24
    readonly property int xxl: 32

    // ── font sizes ────────────────────────────────────────────────────
    readonly property int fsSm: 12   // small/body text
    readonly property int fsMd: 14   // medium text
    readonly property int fsLg: 28   // large text

    // ── radius scale (§2.3): 8 / 12 / 16 / 24 / full ──
    readonly property int radiusSm: 8    // chips, small buttons
    readonly property int radiusMd: 12   // list items, inputs
    readonly property int radiusLg: 16   // panels (launcher, control center)
    readonly property int radiusXl: 24   // dock, pill-shaped bar segments
    readonly property int radiusFull: 9999

    // ── backward-compatible aliases (existing components reference these) ──
    readonly property int rBtn: radiusSm
    readonly property int rPill: radiusSm
    readonly property int rTile: radiusMd
    readonly property int rPanel: radiusLg
    readonly property int rDock: radiusXl

    // panels
    readonly property int sidebarW: 360
    readonly property int dockH: 56
    readonly property int hudH: 30
    readonly property int osdW: 220
    readonly property int osdH: 54

    // controls
    readonly property int tileH: 62
    readonly property int rowH: 40
    readonly property int btnH: 36
    readonly property int sliderH: 5
    readonly property int handleS: 15
    readonly property int iconDock: 32

    // screen furniture
    readonly property int topGap: 30      // below waybar
    readonly property int bottomGap: 56   // above dock
    readonly property int edgeGap: 6
}