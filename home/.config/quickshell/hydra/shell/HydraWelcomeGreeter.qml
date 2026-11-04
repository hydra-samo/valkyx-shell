// HYDRA Welcome — the post-login greeting.
//
// A greeting that drifts in over the desktop and leaves on its own. Deliberately
// NOT a screen: no fullscreen background, no "press Enter", no keyboard grab, no
// input interception of any kind. It is a guest on the desktop for a few seconds,
// not a gate you have to pass through. The window with the actual settings
// (theme, language, keybinds) is the panel — HydraWelcomePanel.qml, Super+Shift+W.
//
// The gate below is still mandatory even though nothing here is interactive:
// the surface exists for the whole greeting and is unmounted by the Loader in
// shell.qml, not by fading. `visible: true` is only safe HERE because something
// outside this file removes the whole thing — a mapped PanelWindow that only
// fades still eats every pointer event under it, and this one is fullscreen.
// focusable is false and there is not one MouseArea or Keys handler in this
// file, which is what makes it safe to leave up.
//
// ── MOTION ────────────────────────────────────────────────────────────────
// This used to be the single most recognisable AI-generated animation: a pair of
// NumberAnimations driving `opacity 0->1` and `y 26->0` at one identical
// duration, then the same pair in reverse for the exit. That exact shape
// (opacity + translateY, uniform timing) is what shows up in the large majority
// of generated pages, because it is the highest-probability way to write
// "something fades in". Three things changed:
//
//   1. The two lines are STAGGERED. Same-duration, same-easing, same-direction
//      movement on both lines is what made it read as machinery.
//   2. The exit no longer travels. It used to drift y 0->-14 on the way out, so
//      the element moved twice. It now fades in place: the block is anchored and
//      nothing re-translates on the way down.
//   3. The name is part of the SENTENCE. "Welcome back HYDRA SAMO" is one
//      greeting, so the name is set in the UI sans at the sentence's own size
//      and tracking. It used to be a standalone lockup at 0.5em tracking — a
//      monospace code eyebrow, the single most reliably-generated "label" in
//      this genre — sitting on its own line above the greeting.
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "../core"
import "../core/components"

PanelWindow {
    id: greeter

    visible: true
    // No keyboard grab, ever. A focusable fullscreen surface is what bricked the
    // desktop on Sep 26.
    focusable: false
    aboveWindows: true
    exclusiveZone: -1
    // MUST stay transparent: a mapped PanelWindow always paints its root colour,
    // so an opaque one leaves a 1366x768 block over the desktop after we leave.
    color: "transparent"
    // Full screen, so the greeting sits centred. The surface is transparent and
    // non-interactive, so covering the screen costs nothing.
    implicitWidth: 1366
    implicitHeight: 768

    // Nothing starts the greeting from in here. The Loader's onLoaded calls
    // showOnce(), which is the single trigger, and shell.qml's boot trigger is
    // the single place that reads the user's on/off preference — an earlier copy
    // of that check lived here and could never fire, because by the time
    // Component.onCompleted ran, onLoaded had already opened the greeting.
    // Adding a second entry point back would only make the preference look
    // enforceable in two places when it is in one.

    // The logged-in user's picture. QML has no file-exists(), and a Process is
    // this shell's existing answer to that (HydraState.sysInfo does the same), so
    // ONE `sh -c` probe walks the candidates in order and prints the first hit.
    // Order matters: the shell's own copy is already cropped to a circle, so it
    // beats a square login picture. The trailing `true` is not decoration — the
    // loop's exit status would otherwise be the last `[ -f ]` test, and a
    // Process that exits non-zero logs an error for a probe that simply found
    // nothing.
    property string avatarSource: ""
    Process {
        running: true
        command: ["/bin/sh", "-c", "for f in \"$HOME/.config/hydra/avatar-circle.png\" \"$HOME/.config/hydra/avatar-placeholder.svg\" \"$HOME/.local/share/sddm/avatars/user.face.icon\" \"$HOME/.face.icon\" \"$HOME/.face\"; do [ -f \"$f\" ] && printf %s \"$f\" && break; done; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = String(text).trim()
                // Empty stays empty: the ring then draws with no photo, which is
                // what a machine with no avatar at all should look like.
                if (found !== "") greeter.avatarSource = "file://" + found
            }
        }
    }

    // ── ANIMATION TARGETS ───────────────────────────────────────────────────
    // Declared HERE, ahead of the timeline, because the timeline names them and
    // the visuals that read them live further down the tree. Naming a visual id
    // from up here is a forward reference: it throws at runtime while qmllint
    // passes clean. One target per animated quantity — the greeting is
    // word-by-word, so the words cannot share a single opacity.
    //
    // avatar
    property real avatarOp: 0
    property real avatarScale: 0.9
    // The accent halo, shared by the avatar ring and the name so they light up
    // as one event. It rides the name's own step, so there is no separate clock
    // for it to be half a beat out of sync with.
    property real brandGlow: 0
    // "Welcome back HYDRA SAMO" — one pair per word, or they arrive together
    // and it is just a phrase fade, which is the thing this is meant NOT to be.
    // The third word is the accent name, so it needs its own pair like the rest.
    property real greet0Op: 0
    property real greet0Rise: 18
    property real greet1Op: 0
    property real greet1Rise: 18
    property real greet2Op: 0
    property real greet2Rise: 18
    // the progress bar and "Entering the shell"
    property real stat0Op: 0
    property real stat0Rise: 10
    // The exit runs on the hero as ONE unit rather than 12 per-word exits. The
    // entrance is what has to be word-by-word; an exit that unwinds in reverse is
    // a second choreography to keep in sync, and it buys nothing a single fade
    // plus a small lift does not.
    property real contentOp: 1
    property real contentRise: 0

    // ── BLURRED BACKDROP ────────────────────────────────────────────────────
    // Hyprland's own `layer_rules = blur,quickshell` is the obvious native answer
    // and it is NOT: on this build the rule is accepted and blurs nothing —
    // measured 0.3% change in image gradient energy, i.e. noise. (Same reason
    // `hyprctl keyword` is a no-op here: the non-legacy config parser refuses it,
    // which is also why HydraState.applyBlur() never actually changed anything.
    // Use `hyprctl eval 'hl.config({...})'` instead.) So: grab the real frame and
    // blur it in Qt, which is real blur and costs one grim call.
    readonly property string bgPath: "/run/user/1000/hydra-greet-bg.png"
    // The Image's source, kept SEPARATE from bgPath and reassigned on capture.
    // Binding `source` straight to bgPath looks correct and is not: the path
    // does not exist when the component loads (grim writes it later), QML logs
    // "Cannot open" and never retries a failed URL — so the backdrop stayed
    // permanently absent and the greeting showed over a SHARP desktop, with
    // nothing in the log but that one line. Reassigning the source is what
    // actually triggers the load. `cache: false` is required for the same
    // reason: Qt's disk cache would happily serve yesterday's desktop.
    property string bgSource: ""
    property bool bgReady: false
    property real backdropOpacity: 0

    Process {
        id: shot
        function grab() {
            // rm first: a stale file from an earlier session would otherwise load
            // and show a screenshot of the PREVIOUS desktop. timeout guards the
            // known 0.56 grim hang — if it trips, the greeting still shows, just
            // unblurred, which is the whole point of not gating on the capture.
            command = ["/bin/sh", "-c", "/usr/bin/rm -f " + greeter.bgPath
                + " && /usr/bin/timeout 6 /usr/bin/grim " + greeter.bgPath]
            running = true
        }
        // Reassigning the source here is what makes the capture load. Doing it
        // on exit rather than on start means a timed-out grim simply leaves
        // bgSource alone and the greeting degrades to unblurred, instead of
        // binding a path that does not exist.
        onExited: greeter.bgSource = greeter.bgPath + "?t=" + Date.now()
    }

    // userName arrives from sysInfo, so the greeting must wait for it or it
    // renders as a bare "Welcome, ". Fire the read on load, not just when the
    // panel opens, because this is the first thing on screen after login.
    function showOnce() {
        if (HydraState.userName === "") { HydraState.sysInfo.running = true; awaitFacts.tries = 0; awaitFacts.start() }
        HydraState.showGreeter()
        // play() HERE, not from the onWelcomeOpenChanged handler. If this
        // instance is mounted while the state is ALREADY open, the assignment
        // above changes nothing, no signal is emitted, and the handler never
        // runs — so the greeting would sit there with every animated value at
        // its initial zero: an invisible but MAPPED fullscreen surface, eating
        // every click, with no timeline and no backstop timer started to ever
        // take it down. That is the one failure the handler could not cover,
        // and it is the one that bricks the desktop. Starting the animation
        // here makes the mount itself responsible for playing, which is the
        // only place that knows a new instance exists.
        play()
    }

    // Bounded: if the read never lands, carry on with whatever we have rather than
    // a bare "Welcome, ". 120 x 200ms = ~24s. ONE onTriggered — declaring a
    // second one on a Timer silently replaces the first.
    Timer {
        id: awaitFacts
        interval: 200
        repeat: true
        property int tries: 0
        onTriggered: {
            tries++
            if (HydraState.userName !== "" || tries > 120) stop()
        }
    }

    // ── WHEN THE GREETING ENDS ──────────────────────────────────────────────
    // Two independent things have to be true, and the original design could
    // only express one of them:
    //
    //   a) the exit must be SEEN. The gate's opacity is bound to welcomeOpen,
    //      so the instant that flips, the greeting is invisible. Ending the
    //      greeting mid-exit means the user never sees it retract.
    //   b) an interrupted greeting must still retract. The original had a
    //      ScriptAction owning the state and NOTHING else, so interrupting the
    //      animation left welcomeOpen true forever — a greeting that would not
    //      go away.
    //
    // Satisfying both: the animation's last step ends the greeting, and a
    // generous backstop timer ends it too. Whichever fires first wins, and
    // neither is load-bearing alone. This is deliberately NOT a computed
    // `holdMs + sum-of-durations` — that needs the durations hand-counted into a
    // multiplier, which is wrong the moment anyone reorders a phase (it was
    // already wrong once here, 600ms short) and nothing warns you.
    // Full-motion entrance is ~2.6s and the exit ~0.6s, so this lands the whole
    // greeting at ~5s on screen. It is plain (never arithmetic on a token) so
    // pinning `holdMs` from a test still pins the greeting.
    property int holdMs: 2400

    // Backstop only. Generous on purpose: it exists so that a stalled, killed
    // or never-started animation can still never leave a fullscreen surface up.
    Timer {
        id: hold
        interval: greeter.holdMs + 8000
        onTriggered: HydraState.welcomeOpen = false
    }

    function play() {
        // Grab alongside the animation, not before it: grim needs ~150ms and the
        // text fade is 600ms, so the blur is established before the text is
        // legible and there is nothing to see pop in.
        bgReady = false
        bgSource = ""
        shot.grab()
        timeline.restart()
        hold.restart()
    }

    // Visual only: it never writes state until the final step. The backdrop
    // arrives first, the hero assembles on its own clock, and the exit fades the
    // hero as one unit WHILE the blur lifts, so the desktop comes back into focus
    // underneath the leaving greeting rather than a beat after it.
    SequentialAnimation {
        id: timeline
        loops: 1
        // 0. the blur, before anything is readable on top of it
        NumberAnimation {
            target: greeter; property: "backdropOpacity"; from: 0; to: 1
            duration: HydraMotion.ambient; easing.type: HydraMotion.curveOut
        }
        // 1. the avatar. Scale from slightly under 1 so it settles into place
        //    rather than popping in at full size.
        ParallelAnimation {
            NumberAnimation {
                target: greeter; property: "avatarOp"; from: 0; to: 1
                duration: HydraMotion.ambient; easing.type: HydraMotion.curveOut
            }
            NumberAnimation {
                target: greeter; property: "avatarScale"; from: 0.9; to: 1
                duration: HydraMotion.ambient; easing.type: HydraMotion.curveOut
            }
        }
        // 2. "Welcome" — word one. This is the whole point of the build: the
        //    greeting is a sequence of words, not one line that fades up.
        PauseAnimation { duration: HydraMotion.stagger }
        ParallelAnimation {
            NumberAnimation {
                target: greeter; property: "greet0Op"; from: 0; to: 1
                duration: HydraMotion.base; easing.type: HydraMotion.curveOut
            }
            NumberAnimation {
                target: greeter; property: "greet0Rise"; from: 18; to: 0
                duration: HydraMotion.base; easing.type: HydraMotion.curveOut
            }
        }
        // 3. "back" — word two, a stagger behind the first.
        PauseAnimation { duration: HydraMotion.stagger }
        ParallelAnimation {
            NumberAnimation {
                target: greeter; property: "greet1Op"; from: 0; to: 1
                duration: HydraMotion.base; easing.type: HydraMotion.curveOut
            }
            NumberAnimation {
                target: greeter; property: "greet1Rise"; from: 18; to: 0
                duration: HydraMotion.base; easing.type: HydraMotion.curveOut
            }
        }
        // 4. "HYDRA SAMO" — the name, in accent, with the halo rising on the
        //    same step. It is the loudest word in the line, so it is also the one
        //    that gets the glow; the avatar ring and the name therefore light up
        //    together instead of in two separate events.
        PauseAnimation { duration: HydraMotion.stagger }
        ParallelAnimation {
            NumberAnimation {
                target: greeter; property: "greet2Op"; from: 0; to: 1
                duration: HydraMotion.base; easing.type: HydraMotion.curveOut
            }
            NumberAnimation {
                target: greeter; property: "greet2Rise"; from: 18; to: 0
                duration: HydraMotion.base; easing.type: HydraMotion.curveOut
            }
            NumberAnimation {
                target: greeter; property: "brandGlow"; from: 0; to: 1
                duration: HydraMotion.ambient; easing.type: HydraMotion.curveOut
            }
        }
        // 5. the bar and "Entering the shell"
        PauseAnimation { duration: HydraMotion.stagger }
        ParallelAnimation {
            NumberAnimation {
                target: greeter; property: "stat0Op"; from: 0; to: 1
                duration: HydraMotion.fast; easing.type: HydraMotion.curveOut
            }
            NumberAnimation {
                target: greeter; property: "stat0Rise"; from: 10; to: 0
                duration: HydraMotion.fast; easing.type: HydraMotion.curveOut
            }
        }
        // 8. dwell. This is legibility, not motion, so it is NOT scaled — the
        //    plain holdMs, which also makes pinning it (for a screenshot)
        //    actually work.
        PauseAnimation { duration: greeter.holdMs }
        // 9. exit. The hero leaves as one unit, drifting up as it goes; the blur
        //    lifts at the same time. Two tracks, not a twelve-step rewind.
        ParallelAnimation {
            NumberAnimation {
                target: greeter; property: "contentOp"; from: 1; to: 0
                duration: HydraMotion.ambient; easing.type: HydraMotion.curveIn
            }
            NumberAnimation {
                target: greeter; property: "contentRise"; from: 0; to: -10
                duration: HydraMotion.ambient; easing.type: HydraMotion.curveIn
            }
            NumberAnimation {
                target: greeter; property: "backdropOpacity"; from: 1; to: 0
                duration: HydraMotion.ambient; easing.type: HydraMotion.curveIn
            }
        }
        // Last step, deliberately: end the greeting here, once the last frame
        // has actually been shown. Paired with the backstop Timer above.
        ScriptAction { script: HydraState.welcomeOpen = false }
    }

    // Only the CLOSE half lives here now. Opening is showOnce()'s job, because
    // only the mount can be certain the state actually changed — see the note
    // there. Both halves of the old handler could stop a running greeting, and
    // stopping the backstop alongside the timeline is what left the surface
    // alive with nothing running.
    Connections {
        target: HydraState
        function onWelcomeOpenChanged() {
            if (!HydraState.welcomeOpen) { timeline.stop(); hold.stop() }
        }
    }

    // ── THE GATE. Exactly one depth-1 visual child, or the overlay is
    // permanently painted (QML ignores indentation, so a sibling that LOOKS
    // nested is not nested).
    Item {
        id: greeterBody
        anchors.fill: parent
        enabled: HydraState.welcomeOpen
        // The gate's opacity is ALWAYS this binding — never an animation target.
        opacity: HydraState.welcomeOpen ? 1 : 0

        // ── The blurred desktop, behind the type. First child so it paints
        // under the Column. It is a still frame of the desktop as it was at
        // boot, which is the point: nothing behind this can move or be clicked,
        // and the blur is what makes the greeting readable on any wallpaper.
        Item {
            id: backdrop
            anchors.fill: parent
            opacity: greeter.backdropOpacity
            // Nothing to draw until there is a frame, and `visible` here is what
            // keeps an unfilled fullscreen Rectangle from flashing black.
            visible: greeter.bgReady && opacity > 0.001

            Image {
                id: bgShot
                anchors.fill: parent
                // The reassigned source, NOT bgPath — see bgSource above.
                source: greeter.bgSource
                // Downscale BEFORE blurring. A 480x270 source makes the blur
                // cheap and also looks more like real defocus than a full-res
                // pass would — and cheap matters: this compositor has already
                // aborted on the iGPU in a fullscreen shader once.
                sourceSize.width: 480
                sourceSize.height: 270
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Must be false: with the disk cache on, a repeat greeting in the
                // same session can be served the previous frame.
                cache: false
                onStatusChanged: if (status === Image.Ready) greeter.bgReady = true
            }

            MultiEffect {
                anchors.fill: parent
                source: bgShot
                blurEnabled: true
                // Qt names these `blur` (0-1 amount) and `blurMax` (px cap) —
                // there is no `blurRadius`, which is the other library's name.
                blur: 1
                blurMax: 64
            }

            // Legibility, not decoration. The blur alone still lets a bright
            // wallpaper wash the type out, and this is a neutral themed dim —
            // no accent wash, which is banned for decoration.
            Rectangle {
                anchors.fill: parent
                color: HydraTheme.tint(HydraTheme.bg, "rest")
            }
        }

        // ── The hero. No logo plate: the avatar IS the identity, and the shell's
        //    rule is text-only identity, so a brand rectangle here would be
        //    decoration. `contentOp`/`contentRise` are the exit pair — they live on
        //    this Column rather than on the gate, because the gate's opacity is
        //    bound to welcomeOpen and animating it would cut the exit short.
        //
        //    The Column IS the hero, not a wrapper around one. An Item wrapper
        //    needs its own explicit height for `centerIn` (a zero-height Item
        //    centres a zero-height box and the Column overflows DOWNWARD, which
        //    renders the stack bottom-heavy and silently), and getting that
        //    height right means referencing the Column's implicitHeight from a
        //    parent — a forward reference. A Column already carries its own
        //    implicitHeight into `centerIn`, so centring it directly is correct
        //    with no height to get wrong.
        Column {
            id: hero
            // Explicit width: the Rows below read `parent.width`, so a Column
            // left to derive its own width from them is a circular binding. It
            // collapses to 0 and the whole greeting renders as nothing, silently.
            width: Math.min(parent.width - HydraMetrics.xl * 2, 720)
            anchors.centerIn: parent
            spacing: HydraMetrics.m
            opacity: greeter.contentOp
            // transform only — animating `y` here would fight the layout pass.
            transform: Translate { y: greeter.contentRise }

                // ── the avatar ────────────────────────────────────────────────
                Item {
                    id: avatarFrame
                    width: 112
                    height: 112
                    anchors.horizontalCenter: parent.horizontalCenter
                    // transform scales from the centre, not the corner, so the
                    // settle reads as depth rather than as a resize.
                    transform: Scale {
                        xScale: greeter.avatarScale
                        yScale: greeter.avatarScale
                    }

                    // The glow is a second, larger, blurred copy BEHIND the ring —
                    // not a plate. A shadowEnabled MultiEffect on the frame itself
                    // is the pattern already proven in TopHud.qml.
                    Rectangle {
                        id: avatarGlow
                        anchors.fill: parent
                        anchors.margins: -10
                        radius: width / 2
                        color: HydraTheme.accent
                        opacity: 0.1 * greeter.brandGlow
                        visible: opacity > 0.005
                        layer.enabled: visible
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: HydraTheme.accent
                            shadowBlur: 1.0
                        }
                    }

                    // The ring: a solid accent border, which is the only kind of
                    // accent the design rules allow as a shape.
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: HydraTheme.accent
                        // The ring brightens with the brand glow, so the avatar and
                        // the wordmark light up as one event.
                        opacity: 0.35 + 0.65 * greeter.brandGlow
                    }

                    // The image is already a transparent PNG cropped to a circle
                    // (512x512, alpha 78.5%), so it needs no Qt mask of its own.
                    Image {
                        anchors.fill: parent
                        anchors.margins: 3
                        // Resolved for whoever is logged in, not baked in. The
                        // shell's own pre-cropped circle wins when it is there;
                        // a fresh install falls back to the login picture.
                        source: greeter.avatarSource
                        sourceSize.width: 512
                        sourceSize.height: 512
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        opacity: greeter.avatarOp
                    }
                }

                // ── "Welcome back HYDRA SAMO" ────────────────────────────────
                // The greeting, word by word. Three Texts rather than one
                // animated string: the gap between the words has to be a real
                // layout gap, and each word needs its own clock.
                //
                // The Row's width is its CONTENT width (implicitWidth), not
                // parent.width. A Row packs children from its left edge, so
                // `width: parent.width` left-aligns the line at x=0 of a 720px
                // box — it looked like the greeting was hanging off to the side
                // while the avatar above it was centred. Anchored, not sized.
                Row {
                    id: greetRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 52
                    // No `spacing`. The gaps are leftPadding on the two words
                    // that follow a word, because on the FIRST run "back" is
                    // gone and a Row's uniform spacing would leave a double gap
                    // where it used to be — and "does a Row skip a hidden
                    // child" is not something worth depending on. An empty Text
                    // with no padding contributes nothing, whichever way the
                    // positioner treats it.
                    spacing: 0

                    Text {
                        id: greet0
                        text: "Welcome"
                        color: HydraTheme.text
                        font.family: HydraTheme.fontUI
                        font.pixelSize: 40
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        opacity: greeter.greet0Op
                        transform: Translate { y: greeter.greet0Rise }
                    }

                    Text {
                        id: greet1
                        // Empty on the first run, so the line reads "Welcome
                        // HYDRASAMO" instead of "Welcome back HYDRASAMO". Bound
                        // to `text`, not `visible`, so the word's width really is
                        // zero and the Row's layout cannot leave its gap behind.
                        text: HydraState.firstGreeting ? "" : "back"
                        leftPadding: HydraState.firstGreeting ? 0 : HydraMetrics.m
                        color: HydraTheme.text
                        font.family: HydraTheme.fontUI
                        font.pixelSize: 40
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        opacity: greeter.greet1Op
                        transform: Translate { y: greeter.greet1Rise }
                    }

                    // The name is a word OF the greeting, not a wordmark above
                    // it, so it is the same size and tracking as the sentence it
                    // sits in. It keeps the old 0.5em tracking of a standalone
                    // lockup that no longer applies — "H Y D R A  S A M O" at this
                    // size reads as a rendering glitch, not as a brand.
                    Text {
                        id: greet2
                        // The user who is logged in, uppercase. Falls back to the
                        // brand while HydraState.userName is still empty: the
                        // system-facts process has not answered yet on a cold
                        // boot, and an empty word would collapse the whole
                        // centred line to nothing.
                        text: HydraState.userName === ""
                              ? "HYDRA SAMO"
                              : HydraState.userName.toUpperCase()
                        color: HydraTheme.accent
                        // Always padded: the name follows "Welcome" on the first
                        // run too, so unlike "back" this gap never disappears.
                        leftPadding: HydraMetrics.m
                        font.family: HydraTheme.fontUI
                        font.pixelSize: 40
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        opacity: greeter.greet2Op
                        transform: Translate { y: greeter.greet2Rise }
                        // The glow, on the layer, not on a shadow-enabled
                        // MultiEffect over a Rectangle: layer.effect draws ONLY
                        // the effect output, so there is no sharp unblurred copy
                        // left underneath. Same construction as the accent dot in
                        // TopHud.qml. Bound to the glow clock so the halo rises
                        // WITH the letters instead of arriving as a flat flash.
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: HydraTheme.accent
                            // 0.5 keeps it a halo, not a second text.
                            shadowBlur: 0.5
                            shadowOpacity: 0.55 * greeter.brandGlow
                        }
                    }
                }

                // ── "Entering the shell", with a bar that sweeps ──────────────
                // The indeterminate bar, Android-launcher style: a calm track with
                // one accent segment travelling end to end. An Item, not a
                // Rectangle, so the track and the segment are two shapes and the
                // segment is not clipped to the track's rounded ends.
                Item {
                    id: bar
                    width: 240
                    height: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: greeter.stat0Op

                    Rectangle {
                        id: track
                        anchors.fill: parent
                        radius: width / 2
                        // Neutral, not accent: the accent is the segment. Two
                        // accent shapes in a row reads as decoration.
                        color: HydraTheme.tint(HydraTheme.line, "fill")
                    }

                    Rectangle {
                        id: seg
                        width: 72
                        height: parent.height
                        radius: width / 2
                        color: HydraTheme.accent
                    }

                    // End to end and back, forever, for as long as the greeting is
                    // up. One NumberAnimation with `loops: Infinite` would snap
                    // back to the left edge on every lap; the out-and-back pair is
                    // what makes it read as one continuous sweep. `running` is
                    // bound to the state so it can never outlive the greeting.
                    //
                    // curveOut on BOTH legs is the point, not a shortcut: easing
                    // out into each end is what makes the segment settle and turn
                    // around instead of arriving and snapping back. Token + token
                    // (not token + literal) so it still scales with reduced motion.
                    SequentialAnimation {
                        id: sweep
                        running: HydraState.welcomeOpen
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: seg; property: "x"
                            from: 0; to: 168  // 240 track − 72 segment
                            duration: HydraMotion.ambient + HydraMotion.base
                            easing.type: HydraMotion.curveOut
                        }
                        NumberAnimation {
                            target: seg; property: "x"
                            from: 168; to: 0  // same travel, reversed
                            duration: HydraMotion.ambient + HydraMotion.base
                            easing.type: HydraMotion.curveOut
                        }
                    }
                }

                Text {
                    id: stat0
                    text: "Entering the shell"
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: HydraTheme.muted
                    font.family: HydraTheme.fontUI
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    opacity: greeter.stat0Op
                    transform: Translate { y: greeter.stat0Rise }
                }
        }
    }
}
