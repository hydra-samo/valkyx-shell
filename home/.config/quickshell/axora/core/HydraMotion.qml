pragma Singleton
// AXORA motion language — one source of timing AND curve truth.
//
// interaction 120–180 · panel 180–260 · transition 280–400 · ambient 600+
//
// Two things live here that did not used to, both because they were the places
// the design language leaked:
//
//  1. Easing curves. 36 `Behavior on` blocks each picking their own curve is how
//     `InOutQuad` — the curve in 83% of AI-generated pages — leaked into the
//     wallpaper skew. A curve is a decision, so it gets a name like any token.
//     Deliberately no bounce/elastic/back: reserved for things that are actually
//     physical, and nothing in a shell is.
//
//  2. Reduced motion. `motionScale` is pushed in by AxoraState from the desktop
//     preference. Because the durations below are *derived*, every existing
//     `duration: AxoraMotion.x` call site collapses to 0 with no edits — which is
//     the only way 36 sites stay honest.
import QtQuick

QtObject {
    // ── reduced motion ────────────────────────────────────────────────────
    // 1 = full motion, 0 = instant. Owned by AxoraState, pushed here.
    // Must be declared first: the duration tokens below derive from it.
    property int motionScale: 1

    // Duration gate. 0 keeps the animation frame but removes travel, so state
    // still lands correctly — snapping beats skipping the final value.
    function scaled(ms: int): int { return motionScale === 0 ? 0 : ms }

    // ── durations (derived, so reduced motion reaches all of them) ────────
    readonly property int instant: scaled(80)
    readonly property int fast: scaled(140)
    readonly property int base: scaled(180)
    readonly property int panel: scaled(220)
    readonly property int transition: scaled(320)
    readonly property int ambient: scaled(600)

    // NOT scaled: dwell time is legibility, not movement. A user who asked for
    // less motion still needs to be able to read the greeting. The greeting's
    // dwell lives on the greeter itself (holdMs) rather than here, so pinning it
    // to pin the greeting on screen actually works.
    readonly property int osdHold: 1400
    readonly property int peekDelay: scaled(350)

    // Stagger between the greeting's two lines. This is a token rather than a
    // literal precisely so it collapses: `AxoraMotion.transition + 280` would
    // evaluate to a bare 280 once reduced motion zeroes the token, quietly
    // defeating the whole mechanism. Never do arithmetic on a scaled token.
    readonly property int stagger: scaled(90)

    // ── curves, named by feel ─────────────────────────────────────────────
    readonly property int curveOut: Easing.OutQuint    // arriving, settling down
    readonly property int curveIn: Easing.InCubic      // leaving, accelerating away
    readonly property int curveSnap: Easing.OutExpo    // crisp arrival, no settle
}
