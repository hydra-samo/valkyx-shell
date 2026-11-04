// HydraAssistantUi — the ENTIRE assistant UI as ONE plain Item. It defines no
// window, no surface, no `visible:` of its own beyond the uiOpen gate: it is
// hostable both in the layershell PanelWindow (HydraAssistantHolo) and in a
// plain Qt Window (a REAL resizable assistant window). All data comes from the
// HydraAssistantApi singleton (import "../core"), exactly as the live shell
// has always used it. Visual tokens come from HydraHolo (same import).
//
// Layout budget on the 1200x690 glass (presence face): chrome 18..48 ·
// presence 374px centred at y=247 -> 60..440 · state label 458..486 ·
// clock under the face. No composer, no decoder band, no rails — input and
// transcript live in the chat popup, systems in the hover card + panels.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../core"

Item {
    id: root
    implicitWidth: 1200
    implicitHeight: 690
    // Fill the host surface. implicitWidth/Height do NOT size children — without
    // this the glass anchors.fill:parent resolve against a 0x0 item and the
    // entire assistant renders as nothing while the surface still maps.
    // Fullscreen: clear the desktop TopHud (layershell top sits above
    // fullscreen windows) so the identity chrome is never covered.
    anchors.fill: parent
    anchors.topMargin: root.isFullscreen ? 56 : 0

    // the ONLY open-state the UI knows. The host binds this to its own state;
    // EVERYTHING below is gated on it.
    property bool uiOpen: false
    visible: uiOpen

    // presence <-> workbench flip (voice states force the presence face)
    property string face: "presence"
    // boot gating: each open plays the short power-up once
    property bool _bootPending: false
    property bool _bootPlayed: false

    signal closeRequested()
    signal windowModeRequested()
    // shell.qml binds this (fullscreen boot + chrome toggle); main shell
    // leaves it false (Ui is window-hosted only).
    property bool isFullscreen: false

    // side popups beside the center face (presence only, non-modal, one at a
    // time): chat | news | music | camera | "". Toggled by the HUD launchers.
    // The dock (voice/memory/flows/agents/settings) is the other beside-face
    // surface: popup and dock never show together — one surface at a time.
    property string holoPopup: ""
    // docked workbench page beside the face ("" = closed). The face never
    // flips away: presence stays mounted, the dock slides in at the right.
    property string dockPage: ""
    function togglePopup(slug) { dockPage = ""; holoPopup = (holoPopup === slug ? "" : slug) }
    function closePopup() { holoPopup = "" }
    function openDock(slug) { holoPopup = ""; workbenchFace.workPage = slug; dockPage = (dockPage === slug ? "" : slug); hubOpen = false }
    onFaceChanged: if (face !== "presence") holoPopup = ""

    onUiOpenChanged: {
        if (uiOpen && !_bootPlayed) { _bootPending = true; _bootPlayed = true }
        if (!uiOpen) { _bootPending = false; _bootPlayed = false; holoPopup = "" }
        // The Holo calls setPolling(open) for panel mode; window mode hosts
        // this Ui directly with no Holo, so drive polling from uiOpen here —
        // otherwise the window never polls /api/state and reads OFFLINE.
        HydraAssistantApi.setPolling(uiOpen)
    }

    Connections {
        target: HydraAssistantApi
        function onStateNameChanged() {
            const s = HydraAssistantApi.stateName
            if (s === "listening" || s === "speaking" || s === "needs-approval")
                root.face = "presence"
        }
    }

    function skipBoot() { if (bootLoader.item) bootLoader.item.skip() }

    // ── the glass ──
    Rectangle {
        id: glass
        anchors.fill: parent
        radius: HydraMetrics.rTile
        color: HydraHolo.bg
        border.color: HydraHolo.deep
        border.width: 1

        // HUD corner brackets — exactly TWO: top-left + bottom-right.
        Repeater {
            model: 2
            delegate: Item {
                width: 18; height: 18
                x: (index % 2 === 0) ? 6 : glass.width - 24
                y: (index === 0) ? 6 : glass.height - 24
                Rectangle {
                    width: 18; height: 2; color: HydraHolo.primary
                    x: 0; y: (index === 0) ? 0 : 16
                }
                Rectangle {
                    width: 2; height: 18; color: HydraHolo.primary
                    x: (index % 2 === 0) ? 0 : 16; y: 0
                }
            }
        }
    }

    // ── treatments: corner vignette + the scanline layer, painted ONCE ──
    // The scanline layer is 1px every 4px at HydraHolo.scanAlpha (0.04) —
    // one repaint, never per-frame: no flicker, no ongoing CPU, and the
    // opacity is the one named token (see shell/holo/HydraHolo.qml).
    Canvas {
        id: treatments
        anchors.fill: parent
        antialiasing: false

        onPaint: {
            var ctx = getContext("2d")
            var w = width, h = height
            if (w <= 0 || h <= 0) return

            // vignette: transparent centre -> 35% black at the corners
            var cx = w / 2, cy = h / 2
            var maxR = Math.sqrt(cx * cx + cy * cy)
            var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, maxR)
            g.addColorStop(0.30, "rgba(0,0,0,0)")
            g.addColorStop(1.0, "rgba(0,0,0,0.35)")
            ctx.fillStyle = g
            ctx.fillRect(0, 0, w, h)

            // scanlines
            ctx.fillStyle = Qt.rgba(0, 0, 0, HydraHolo.scanAlpha)
            for (var y = 0; y < h; y += 4) ctx.fillRect(0, y, w, 1)

            // board grid: 1px every gridStep at gridAlpha — the same single
            // repaint, a near-invisible blackboard under the side popups
            ctx.fillStyle = Qt.rgba(1, 1, 1, HydraHolo.gridAlpha)
            for (var gx = 0.5; gx < w; gx += HydraHolo.gridStep) ctx.fillRect(gx, 0, 1, h)
            for (var gy = 0.5; gy < h; gy += HydraHolo.gridStep) ctx.fillRect(0, gy, w, 1)
        }
    }

    // ── PRESENCE FACE: plexus (listening) + ring (speaking), dot otherwise ──
    // HydraAssistantPresence is the approved presence language (mockup-verbatim
    // node/edge tables). Its canvases self-pump on visibility via Date.now() —
    // no external pump needed, nothing to accumulate across open/close.
    Item {
        id: presenceFace
        anchors.fill: parent
        visible: root.face === "presence"

        HydraAssistantPresence {
            id: presence
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 130
            // Side-docked surfaces overlap the face flank: yield the docked
            // side so face + card read as one blended surface, not a stack.
            anchors.horizontalCenterOffset: (root.holoPopup === "chat" || root.holoPopup === "news") ? 190
                : (root.holoPopup === "music" || root.holoPopup === "camera" || root.dockPage !== "") ? -190 : 0
            width: Math.min(parent.width, parent.height) * 0.54
            height: width
            stateName: HydraAssistantApi.stateName
            level: HydraAssistantApi.level
            online: HydraAssistantApi.online
        }

        // State lives in the header chip + the face itself (dot/plexus/ring):
        // a third text restatement here read as clutter ("one state
        // expression, stated once").
        // idle clock — honest content for the empty band (system time, no backend)
        Text {
            id: idleClock
            anchors.horizontalCenter: presence.horizontalCenter
            anchors.top: presence.verticalCenter
            anchors.topMargin: 70
            visible: HydraAssistantApi.stateName === "idle" && HydraAssistantApi.online
            text: Qt.formatDateTime(new Date(), "hh:mm:ss") + "  ·  " + Qt.formatDateTime(new Date(), "ddd MMM d")
            color: HydraTheme.muted
            font.family: HydraTheme.fontMono
            font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
            font.letterSpacing: Math.round(HydraHolo.fsMicro * 0.16 * HydraState.fontScale)

            Timer {
                interval: 1000
                running: idleClock.visible
                repeat: true
                onTriggered: idleClock.text = Qt.formatDateTime(new Date(), "hh:mm:ss") + "  ·  " + Qt.formatDateTime(new Date(), "ddd MMM d")
            }
        }

        // usage line under the clock: current provider + last-turn total,
        // or the unbilled line when the brain runs local
        Text {
            anchors.horizontalCenter: presence.horizontalCenter
            anchors.top: idleClock.bottom
            anchors.topMargin: 4
            visible: idleClock.visible && workbenchFace.presenceUsage() !== ""
            text: workbenchFace.presenceUsage()
            color: HydraTheme.muted
            font.family: HydraTheme.fontMono
            font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
            font.letterSpacing: Math.round(HydraHolo.fsTiny * 0.16 * HydraState.fontScale)
        }

        // hover zone over the face: opens the live system card, never swallows
        // clicks (NoButton) so presence taps pass through unaffected —
        // hover in, card; hover out, gone.
        MouseArea {
            id: faceHover
            anchors.horizontalCenter: presence.horizontalCenter
            anchors.bottom: presence.bottom
            width: 400
            height: 400
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        HydraHoloHoverCard {
            x: 816
            y: 120
            visible: faceHover.containsMouse
                     && root.holoPopup === ""
                     && HydraAssistantApi.pendingModel.count === 0
            level: HydraAssistantApi.level
        }

        // side popups — HydraHoloPanel cards docked beside the face.
        // Non-modal: no dim, the face keeps animating underneath, hover yields
        // while one is open. Chat/news dock left, music/camera dock right.
        Loader {
            id: popupLoader
            active: root.holoPopup !== "" && root.face === "presence"
            // maximized camera takes the window center (tapes' fullscreen
            // feed); everything else docks beside the face as before.
            x: (root.holoPopup === "camera" && popupLoader.item && popupLoader.item.maximized) ? 18
                : (root.holoPopup === "music" || root.holoPopup === "camera") ? root.width - 638 : 18
            y: 60
            sourceComponent: root.holoPopup === "chat" ? chatPopup
                : root.holoPopup === "news" ? newsPopup
                : root.holoPopup === "music" ? musicPopup : cameraPopup
            onLoaded: {
                if (item) item.closed.connect(root.closePopup)
            }
        }
        Component { id: chatPopup; HydraHoloChatPopup {} }
        Component { id: newsPopup; HydraHoloNewsPopup {} }
        Component { id: musicPopup; HydraHoloMusicPopup {} }
        Component { id: cameraPopup; HydraHoloCameraPopup {} }

        // modal scrim — dim behind APPROVAL only; side popups stay non-modal.
        // Declared above the popup layer so a pending approval takes precedence.
        Rectangle {
            anchors.fill: parent
            visible: HydraAssistantApi.pendingModel.count > 0
            color: Qt.rgba(0, 0, 0, 0.45)
            MouseArea { anchors.fill: parent }
        }

        // approval overlay — presence face (amber = a REAL warning)
        Rectangle {
            id: approvalOverlay
            visible: HydraAssistantApi.pendingModel.count > 0
            anchors.centerIn: parent
            width: 320
            radius: HydraMetrics.rTile
            color: HydraHolo.bg
            border.color: HydraHolo.warning
            border.width: 1

            // Gap-4 token receipt: the overlay fetches each pending's token +
            // expires_at itself (GET /api/state) so HydraAssistantApi stays
            // untouched. Token shown truncated (first 6 chars) — a receipt,
            // never the full secret. Approve posts /api/confirm {token,
            // verdict}; ungated entries fall back to the legacy path.
            property var confirmMeta: ({})
            property int _tick: 0
            function refreshConfirmMeta() {
                HydraAssistantApi._request("GET", "/api/state", null, (obj) => {
                    const m = {}
                    for (const p of (obj && obj.pending) || []) {
                        if (p.token) m[p.name] = { token: p.token, expires_at: p.expires_at || 0 }
                    }
                    approvalOverlay.confirmMeta = m
                })
            }
            function remainFor(name) {
                approvalOverlay._tick
                const m = approvalOverlay.confirmMeta[name]
                if (!m) return -1
                return m.expires_at - Date.now() / 1000
            }
            function fmtRemain(sec) {
                if (sec < 0) sec = 0
                const mm = Math.floor(sec / 60), ss = Math.floor(sec % 60)
                return (mm < 10 ? "0" + mm : "" + mm) + ":" + (ss < 10 ? "0" + ss : "" + ss)
            }
            function receiptFor(name) {
                const m = approvalOverlay.confirmMeta[name]
                if (!m || !m.token) return ""
                return m.token.slice(0, 6) + "…"
            }
            function headerCountdown() {
                approvalOverlay._tick
                let best = -1
                for (const k in approvalOverlay.confirmMeta) {
                    const r = approvalOverlay.remainFor(k)
                    if (r >= 0 && (best < 0 || r < best)) best = r
                }
                return best < 0 ? "" : approvalOverlay.fmtRemain(best)
            }
            onVisibleChanged: if (visible) refreshConfirmMeta()
            Timer {
                interval: 1000
                running: approvalOverlay.visible
                repeat: true
                onTriggered: {
                    approvalOverlay._tick++
                    if (approvalOverlay._tick % 5 === 0) approvalOverlay.refreshConfirmMeta()
                }
            }

            // corner brackets (HUD language) — exactly TWO
            Repeater {
                model: 2
                delegate: Item {
                    width: 14; height: 14
                    x: (index % 2 === 0) ? -4 : approvalOverlay.width - 10
                    y: (index === 0) ? -4 : approvalOverlay.height - 10
                    Rectangle { width: 14; height: 2; color: HydraHolo.warning; x: 0; y: (index === 0) ? 0 : 12 }
                    Rectangle { width: 2; height: 14; color: HydraHolo.warning; x: (index % 2 === 0) ? 0 : 12; y: 0 }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10
                Text { text: "NEEDS APPROVAL"; color: HydraHolo.warning
                    font.family: HydraTheme.fontMono; font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale); font.letterSpacing: 1.8 }
                Text {
                    visible: approvalOverlay.headerCountdown() !== ""
                    text: "EXPIRES " + approvalOverlay.headerCountdown()
                    color: HydraHolo.warning
                    font.family: HydraTheme.fontMono; font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale); font.letterSpacing: 1.8
                }
                Repeater {
                    model: HydraAssistantApi.pendingModel
                    delegate: Rectangle {
                        required property string name
                        required property var args
                        width: 288; height: approveCol.implicitHeight + 24
                        radius: HydraMetrics.rTile
                        color: "transparent"
                        border.color: HydraHolo.warning; border.width: 1
                        Column {
                            id: approveCol
                            x: 12; y: 12; width: parent.width - 24; spacing: 10
                            Text { text: name; color: HydraHolo.warning
                                font.family: HydraTheme.fontMono; font.pixelSize: Math.round(HydraHolo.fsSm * HydraState.fontScale) }
                            Text {
                                visible: approvalOverlay.receiptFor(name) !== ""
                                text: "TOKEN " + approvalOverlay.receiptFor(name)
                                    + " · " + approvalOverlay.fmtRemain(approvalOverlay.remainFor(name))
                                color: HydraTheme.muted
                                font.family: HydraTheme.fontMono; font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            }
                            Row {
                                spacing: 8
                                Item {
                                    width: 56; height: 32
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: "transparent"; border.color: HydraHolo.primary; border.width: 1
                                    }
                                    Shape {
                                        width: 24; height: 24
                                        scale: 0.67
                                        anchors.centerIn: parent
                                        antialiasing: true
                                        ShapePath {
                                            strokeColor: HydraHolo.primary
                                            strokeWidth: 2
                                            fillColor: "transparent"
                                            capStyle: ShapePath.RoundCap
                                            joinStyle: ShapePath.RoundJoin
                                            PathSvg { path: HydraHolo.iconPaths.check }
                                        }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: {
                                        const m = approvalOverlay.confirmMeta[name]
                                        if (m && m.token) HydraAssistantApi._request("POST", "/api/confirm", { token: m.token, verdict: "approve" }, () => HydraAssistantApi.refresh())
                                        else HydraAssistantApi.approve(name, args)
                                    } }
                                }
                                Item {
                                    width: 56; height: 32
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: "transparent"; border.color: HydraMaterials.border; border.width: 1
                                    }
                                    Shape {
                                        width: 24; height: 24
                                        scale: 0.67
                                        anchors.centerIn: parent
                                        antialiasing: true
                                        ShapePath {
                                            strokeColor: HydraTheme.muted
                                            strokeWidth: 2
                                            fillColor: "transparent"
                                            capStyle: ShapePath.RoundCap
                                            joinStyle: ShapePath.RoundJoin
                                            PathSvg { path: HydraHolo.iconPaths.pause }
                                        }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: {
                                        const m = approvalOverlay.confirmMeta[name]
                                        if (m && m.token) HydraAssistantApi._request("POST", "/api/confirm", { token: m.token, verdict: "hold" }, () => HydraAssistantApi.refresh())
                                        else HydraAssistantApi.hold(name)
                                    } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── HOVER HUB: settings/chat/voice/flows rail as a slide-out panel
    // from the LEFT border — not stuck on the faces. Hover the 14px strip
    // (or the open hub) to show; leaving both hides after a 400ms grace so
    // the pointer can travel strip→panel without flicker. Clicking an entry
    // navigates exactly like the workbench rail, then the hub closes.
    property bool hubOpen: false
    Timer {
        id: hubGrace
        interval: 400
        onTriggered: root.hubOpen = false
    }
    MouseArea {
        id: hubStrip
        width: 14
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 55
        onEntered: { hubGrace.stop(); root.hubOpen = true }
        onExited: hubGrace.restart()
    }
    Rectangle {
        id: hubPanel
        width: 248
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 60
        anchors.bottomMargin: 60
        x: root.hubOpen ? 14 : -270
        z: 56
        radius: 12
        color: HydraHolo.bg
        border.color: HydraMaterials.border
        border.width: 1
        Behavior on x { NumberAnimation { duration: HydraMotion.panel; easing.type: HydraMotion.curveSnap } }
        visible: x > -270
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: hubGrace.stop()
            onExited: hubGrace.restart()
        }
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 2
            Text {
                text: "HUB"
                color: HydraTheme.muted
                font.family: HydraTheme.fontMono
                font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                font.letterSpacing: 3
            }
            Repeater {
                // Hub: the beside-face surfaces. System/Steps/Routines are
                // NOT here (approvals auto-overlay, steps live in the island).
                model: ListModel {
                    ListElement { slug: "chat"; label: "Chat" }
                    ListElement { slug: "voice"; label: "Voice" }
                    ListElement { slug: "memory"; label: "Memory" }
                    ListElement { slug: "flows"; label: "Flows" }
                    ListElement { slug: "agents"; label: "Agents" }
                    ListElement { slug: "settings"; label: "Settings" }
                }
                delegate: Rectangle {
                    required property string slug
                    required property string label
                    property bool hovered: entryHover.containsMouse
                    property bool isOpen: (slug === "chat" && root.holoPopup === "chat")
                        || root.dockPage === slug
                    width: 224; height: 34
                    radius: HydraMetrics.rTile
                    color: isOpen ? HydraMaterials.tileGlass
                        : hovered ? HydraMaterials.tileGlass : "transparent"
                    border.color: isOpen ? HydraHolo.primary : "transparent"
                    border.width: 1
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        text: label
                        color: isOpen ? HydraTheme.text
                            : hovered ? HydraHolo.primary : HydraTheme.muted
                        font.family: HydraTheme.fontUI
                        font.pixelSize: Math.round(HydraHolo.fsSm * HydraState.fontScale)
                        font.underline: hovered || isOpen
                    }
                    MouseArea {
                        id: entryHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (slug === "chat") { root.dockPage = ""; root.togglePopup("chat") }
                            else root.openDock(slug)
                            root.hubOpen = false
                        }
                    }
                }
            }
        }
    }

    // ── DOCK: the workbench as a right-side card, face always visible ──
    // Same rail + pages, but docked beside the presence face instead of
    // replacing it. Opened from the hub rail; Esc or the chrome X closes.
    Item {
        id: workbenchFace
        visible: root.dockPage !== ""
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: Math.min(620, parent.width * 0.52)
        anchors.topMargin: 60
        anchors.bottomMargin: 82
        anchors.rightMargin: 18

        property string workPage: "chat"

        // ── overlay panels (system / steps) ──
        // At most one at a time: the dim backdrop blocks the rail behind it, so
        // no second entry point can reach the workbench while one is open.
        property string openPanel: ""
        property string sysState: "loading"
        property string sysMessage: ""
        property string sysStatus: ""
        property ListModel sysModel: ListModel {}
        property var keyDrafts: ({})
        property string keysNote: "FILL FIELDS + SAVE — KEYS GO TO 600 FILES, NEVER SHOWN AGAIN"
        property Timer sysTimeout: Timer {
            interval: 8000
            repeat: false
            running: false
            onTriggered: {
                if (workbenchFace.sysState === "loading") {
                    workbenchFace.sysState = "error"
                    workbenchFace.sysMessage = "NO RESPONSE AFTER 8S — API DOWN OR UNREACHABLE"
                }
            }
        }
        property ListModel keyProviders: ListModel {
            ListElement { key: "groq"; label: "Groq"; extra: "" }
            ListElement { key: "gemini"; label: "Gemini"; extra: "" }
            ListElement { key: "cloudflare"; label: "Cloudflare"; extra: "account" }
            ListElement { key: "nvidia"; label: "NVIDIA"; extra: "" }
            ListElement { key: "openrouter"; label: "OpenRouter"; extra: "" }
            ListElement { key: "serpapi"; label: "SerpAPI"; extra: "" }
            ListElement { key: "posthog"; label: "PostHog"; extra: "" }
            ListElement { key: "custom"; label: "Custom"; extra: "url" }
        }

        function openPanel(slug) {
            workbenchFace.openPanel = slug
            if (slug === "system") {
                workbenchFace.sysState = "loading"
                workbenchFace.sysMessage = ""
                workbenchFace.sysStatus = ""
                workbenchFace.sysModel.clear()
                workbenchFace.sysTimeout.restart()
                if (!HydraAssistantApi.online) {
                    workbenchFace.sysState = "offline"
                    workbenchFace.sysMessage = "API NOT REACHABLE — RETRY ONCE THE ASSISTANT SERVICE ANSWERS"
                } else {
                    // the SAME path the System rail page has always used — no new fetch
                    HydraAssistantApi._request("GET", "/api/system", null, (obj) => {
                        const rows = obj || []
                        workbenchFace.sysModel.clear()
                        for (const r of rows)
                            workbenchFace.sysModel.append({ slug: r.slug || "", desc: r.desc || "" })
                        workbenchFace.sysState = rows.length ? "content" : "empty"
                        workbenchFace.sysMessage = ""
                        workbenchFace.sysStatus = "GET /api/system · " + rows.length + " ROWS"
                    })
                }
            }
            panelKeySink.forceActiveFocus()
        }
        function closePanel() {
            workbenchFace.openPanel = ""
        }
        // POST each filled draft to /api/keys (atomic 600 writes, server
        // never echoes values). Drafts clear only for providers the server
        // confirms; failures report per-provider, values never shown.
        // _request fires back only on HTTP 200, so a watchdog advances the
        // chain if a POST is refused (400/401) instead of wedging on SAVING…
        property var keyQueue: []
        property var keySaved: []
        property var keyFailed: []
        property string keyCurrent: ""
        // live input boxes for post-save clearing (rebuilt each time the
        // settings page opens — delegates die when you leave the page)
        property var keyInputs: []
        // Per-provider saved-key flags from GET /api/keys/status (booleans
        // only — never key material). Drives the ACTIVE badges.
        property var keyActive: ({})
        // Token usage snapshot: .brain.usage from /api/state (counts only,
        // no secrets). Fetched once alongside the key status — the Api
        // singleton itself is out of scope, so no piggyback on its poller.
        property var brainUsage: ({ totals: ({}), last: ({ prompt: 0, completion: 0 }), provider: "" })
        // Voice config from GET /api/voice (ids + engine names only).
        // voiceIds is the string projection for the Repeater: it takes
        // array-of-strings only (array-of-objects renders nothing).
        property var voiceInfo: ({ voices: [], voiceIds: [], current: "", sttEngine: "", sttModel: "", wake: 0 })
        property string voiceNote: ""
        function fmtK(n) {
            n = n || 0
            if (n >= 1000) return (n / 1000).toFixed(1) + "k"
            return "" + n
        }
        function usageLine(key) {
            const t = (workbenchFace.brainUsage.totals || {})[key]
            if (!t) return ""
            return fmtK(t.prompt) + " prompt · " + fmtK(t.completion) + " completion"
        }
        function presenceUsage() {
            const u = workbenchFace.brainUsage
            const p = (u.provider || "").toLowerCase()
            if (p === "") return ""
            if (p === "local" || p === "opencode") return "LOCAL · UNBILLED"
            const last = u.last || { prompt: 0, completion: 0 }
            return u.provider.toUpperCase() + " · " + fmtK((last.prompt || 0) + (last.completion || 0))
        }
        Timer {
            id: keyWatchdog
            interval: 8000
            onTriggered: {
                if (workbenchFace.keyCurrent !== "") {
                    workbenchFace.keyFailed.push(workbenchFace.keyCurrent + " (refused)")
                    workbenchFace.keyCurrent = ""
                    workbenchFace.nextKey()
                }
            }
        }
        // Key-status fetch, re-run on the offline->online flip: settings
        // opened before the first poll answers would show no badges forever.
        // Also stashes the usage totals riding the same /api/state snapshot.
        function fetchKeyStatus() {
            HydraAssistantApi._request("GET", "/api/keys/status", null, (obj) => {
                if (obj && obj.saved) workbenchFace.keyActive = obj.saved
            })
            HydraAssistantApi._request("GET", "/api/state", null, (obj) => {
                if (obj && obj.brain && obj.brain.usage) workbenchFace.brainUsage = obj.brain.usage
            })
        }
        // Voice config fetch — same online-flip guard as the keys (one shared
        // fetchSettings covers both).
        function fetchVoice() {
            HydraAssistantApi._request("GET", "/api/voice", null, (obj) => {
                if (!obj) return
                const vs = (obj.tts && obj.tts.voices) || []
                workbenchFace.voiceInfo = {
                    voices: vs,
                    voiceIds: vs.map((v) => v.id),
                    current: (obj.tts && obj.tts.current) || "",
                    sttEngine: (obj.stt && obj.stt.engine) || "",
                    sttModel: (obj.stt && obj.stt.model) || "",
                    wake: (obj.wake && obj.wake.threshold) || 0
                }
            })
        }
        function fetchSettings() {
            workbenchFace.fetchKeyStatus()
            workbenchFace.fetchVoice()
        }
        // CHANGE: unlock one provider so the key can be retyped (Save
        // re-locks automatically). Raw XHR, not _request: _request only
        // fires back on 200, and the 404/500 server text is the note here.
        function unlockProvider(p) {
            if (!HydraAssistantApi.online || HydraAssistantApi.apiBase === "" || !HydraAssistantApi.tokenReady) {
                workbenchFace.keysNote = "OFFLINE — CANNOT UNLOCK " + p.toUpperCase()
                return
            }
            const xhr = new XMLHttpRequest()
            xhr.open("POST", HydraAssistantApi.apiBase + "/api/keys/unlock")
            xhr.setRequestHeader("X-Hydra-Token", HydraAssistantApi.token)
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.onreadystatechange = () => {
                if (xhr.readyState !== XMLHttpRequest.DONE) return
                if (xhr.status === 200) {
                    const a = Object.assign({}, workbenchFace.keyActive)
                    a[p] = false
                    workbenchFace.keyActive = a
                    workbenchFace.keysNote = "UNLOCKED — SAVE TO RELOCK"
                } else {
                    let msg = "UNLOCK FAILED (" + xhr.status + ")"
                    try {
                        const o = JSON.parse(xhr.responseText)
                        if (o.error || o.message) msg = (o.error || o.message).toUpperCase()
                    } catch (e) {
                        if (xhr.responseText) msg = xhr.responseText.slice(0, 80).toUpperCase()
                    }
                    workbenchFace.keysNote = msg
                }
            }
            xhr.send(JSON.stringify({ provider: p }))
        }
        function cycleVoice(id) {
            if (!HydraAssistantApi.online) {
                workbenchFace.voiceNote = "OFFLINE — VOICE HELD AS IS"
                return
            }
            workbenchFace.voiceNote = "SENDING…"
            HydraAssistantApi._request("POST", "/api/voice", { tts_voice: id }, (obj) => {
                workbenchFace.fetchVoice()
                const v = (obj && (obj.tts_voice || obj.current)) || id
                workbenchFace.voiceNote = "VOICE — " + v
            })
        }
        function setWake(v) {
            if (!HydraAssistantApi.online) {
                workbenchFace.voiceNote = "OFFLINE — VOICE HELD AS IS"
                return
            }
            HydraAssistantApi._request("POST", "/api/voice", { wake_threshold: v }, (obj) => {
                workbenchFace.fetchVoice()
                const applied = (obj && obj.wake_threshold !== undefined) ? obj.wake_threshold : v
                workbenchFace.voiceNote = "WAKE THRESHOLD — " + applied
            })
        }
        function sttBase() {
            const m = workbenchFace.voiceInfo.sttModel || ""
            const parts = m.split("/")
            return parts.length ? parts[parts.length - 1] : m
        }
        function saveKeys() {
            const drafts = workbenchFace.keyDrafts
            workbenchFace.keyQueue = Object.keys(drafts).filter((k) => drafts[k].trim() !== ""
                && k.indexOf("_") < 0)
            workbenchFace.keySaved = []
            workbenchFace.keyFailed = []
            workbenchFace.keyCurrent = ""
            if (!HydraAssistantApi.online) {
                workbenchFace.keysNote = "OFFLINE — KEYS HELD IN MEMORY ONLY"
                return
            }
            if (!workbenchFace.keyQueue.length) {
                workbenchFace.keysNote = "NOTHING TO SAVE — FILL A KEY FIELD FIRST"
                return
            }
            workbenchFace.keysNote = "SAVING " + workbenchFace.keyQueue.length + " KEY(S)…"
            workbenchFace.nextKey()
        }
        function nextKey() {
            keyWatchdog.stop()
            if (!workbenchFace.keyQueue.length && workbenchFace.keyCurrent === "") {
                let msg = workbenchFace.keySaved.length ? "SAVED: " + workbenchFace.keySaved.join(", ") : "NOTHING SAVED"
                if (workbenchFace.keyFailed.length) msg += " · FAILED: " + workbenchFace.keyFailed.join(", ")
                workbenchFace.keysNote = msg
                // refresh ACTIVE badges (a 423-locked overwrite reports FAILED,
                // badges stay as the server says they are)
                HydraAssistantApi._request("GET", "/api/keys/status", null, (obj) => {
                    if (obj && obj.saved) workbenchFace.keyActive = obj.saved
                })
                // clear on-screen secrets for confirmed providers only
                for (const rec of workbenchFace.keyInputs) {
                    if (workbenchFace.keySaved.indexOf(rec.key) >= 0
                        || workbenchFace.keySaved.indexOf(rec.key.split("_")[0]) >= 0) {
                        try { rec.box.clear() } catch (e) {}
                    }
                }
                return
            }
            if (workbenchFace.keyCurrent === "")
                workbenchFace.keyCurrent = workbenchFace.keyQueue.shift()
            const p = workbenchFace.keyCurrent
            const drafts = workbenchFace.keyDrafts
            const body = { provider: p, key: drafts[p] }
            if (p === "cloudflare" && (drafts[p + "_account"] || "").trim() !== "")
                body.account_id = drafts[p + "_account"]
            if (p === "custom" && (drafts[p + "_url"] || "").trim() !== "")
                body.base_url = drafts[p + "_url"]
            keyWatchdog.restart()
            HydraAssistantApi._request("POST", "/api/keys", body, (obj) => {
                keyWatchdog.stop()
                if (obj && obj.saved && obj.saved.length) {
                    workbenchFace.keySaved.push(p)
                    delete drafts[p]; delete drafts[p + "_account"]; delete drafts[p + "_url"]
                } else {
                    workbenchFace.keyFailed.push(p)
                }
                workbenchFace.keyCurrent = ""
                workbenchFace.nextKey()
            })
        }

        RowLayout {
            anchors.fill: parent
            spacing: 14

            // rail — only pages with real data (spec §3)
            Column {
                Layout.preferredWidth: 132
                Layout.fillHeight: true
                spacing: 2
                Repeater {
                    // Dock rail mirrors the hub: no System/Steps/Routines.
                    model: ListModel {
                        ListElement { slug: "chat"; label: "Chat" }
                        ListElement { slug: "voice"; label: "Voice" }
                        ListElement { slug: "memory"; label: "Memory" }
                        ListElement { slug: "flows"; label: "Flows" }
                        ListElement { slug: "agents"; label: "Agents" }
                        ListElement { slug: "settings"; label: "Settings" }
                    }
                    delegate: Rectangle {
                        required property string slug
                        required property string label
                        required property int index
                        property bool hovered: railHover.containsMouse
                        property bool isOpen: workbenchFace.workPage === slug
                        width: 132; height: 34
                        radius: HydraMetrics.rTile
                        color: isOpen ? HydraMaterials.tileGlass
                            : hovered ? HydraMaterials.tileGlass : "transparent"
                        border.color: isOpen ? HydraHolo.primary : "transparent"
                        border.width: 1
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            text: label
                            color: isOpen ? HydraTheme.text
                                : hovered ? HydraHolo.primary : HydraTheme.muted
                            font.family: HydraTheme.fontUI
                            font.pixelSize: Math.round(HydraHolo.fsSm * HydraState.fontScale)
                            font.underline: hovered || isOpen
                        }
                        MouseArea {
                            id: railHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                workbenchFace.workPage = slug
                            }
                        }
                    }
                }
            }

            // chat transcript
            ListView {
                id: chatView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: workbenchFace.workPage === "chat"
                clip: true
                spacing: 12
                model: HydraAssistantApi.historyModel
                onCountChanged: positionViewAtEnd()
                delegate: Column {
                    required property string kind
                    required property string body
                    width: chatView.width
                    Rectangle {
                        id: bubbleRect
                        width: chatView.width * 0.78
                        height: bubbleText.implicitHeight + 20
                        radius: 12
                        anchors.right: kind === "you" ? parent.right : undefined
                        color: kind === "you" ? "transparent" : HydraMaterials.tileGlass
                        border.color: kind === "you" ? HydraHolo.primary : HydraMaterials.border
                        border.width: 1
                        Text {
                            id: bubbleText
                            x: 13; y: 10
                            width: bubbleRect.width - 26
                            wrapMode: Text.WordWrap
                            text: body
                            color: HydraTheme.text
                            font.family: HydraTheme.fontUI
                            font.pixelSize: Math.round(HydraHolo.fsBody * HydraState.fontScale)
                        }
                    }
                }
            }

            // rail pages (voice/memory/routines/flows/agents/system)
            Item {
                id: pageLoader
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: workbenchFace.workPage !== "chat"

                property var pageRows: []
                onPageRowsChanged: {
                    pageModel.clear()
                    for (const r of pageRows)
                        pageModel.append({ title: r.slug || r.name || "",
                                           sub: r.blurb || r.title || r.desc || "" })
                }
                Connections {
                    target: HydraAssistantApi
                    function onOnlineChanged() {
                        if (HydraAssistantApi.online && workbenchFace.workPage === "settings") workbenchFace.fetchSettings()
                    }
                }
                function loadPage() {
                    const p = workbenchFace.workPage
                    if (p === "settings") {
                        workbenchFace.keyInputs = []
                        workbenchFace.fetchSettings()
                    }
                    if (p === "chat") { pageRows = []; return }
                    if (p === "voice") { pageRows = []; return }
                    if (p === "memory") { pageRows = []; return }
                    if (p === "settings") { pageRows = []; return }
                    HydraAssistantApi._request("GET", "/api/" + p, null, (obj) => { pageRows = obj })
                }
                Component.onCompleted: loadPage()
                Connections {
                    target: workbenchFace
                    function onWorkPageChanged() { pageLoader.loadPage() }
                }

                // voice page: status only — the daemon owns the mic
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: workbenchFace.workPage === "voice"
                    Text { text: "VOICE"; color: HydraHolo.primary
                        font.family: HydraTheme.fontMono; font.pixelSize: Math.round(HydraHolo.fsSm * HydraState.fontScale); font.letterSpacing: 2 }
                    Text { text: "say \"hey hydra\"  ·  Super+Ctrl+Space = push-to-talk"
                        color: HydraTheme.text; font.family: HydraTheme.fontUI; font.pixelSize: Math.round(HydraHolo.fsBody * HydraState.fontScale) }
                    Text { text: "state: " + HydraAssistantApi.stateName
                        color: HydraTheme.muted; font.family: HydraTheme.fontMono; font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale) }
                }

                // memory page: the whole store (newest 50), per-row delete.
                // Fetched live from /api/memory on page open — memoryModel
                // (state snapshot) only carries this session's writes.
                ListView {
                    id: memView
                    anchors.fill: parent
                    visible: workbenchFace.workPage === "memory"
                    clip: true; spacing: 6
                    property ListModel storeModel: ListModel {}
                    model: storeModel
                    function refreshMem() {
                        HydraAssistantApi._request("GET", "/api/memory", null, (obj) => {
                            storeModel.clear()
                            for (const r of (obj && obj.items) || [])
                                storeModel.append({ body: r.text || "" })
                        })
                    }
                    delegate: Row {
                        required property string body
                        required property int index
                        width: memView.width
                        spacing: 8
                        Text {
                            text: "· " + body; color: HydraTheme.text
                            width: parent.width - 30; wrapMode: Text.WordWrap
                            font.family: HydraTheme.fontMono
                            font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                        }
                        Item {
                            width: 20; height: 20
                            Shape {
                                width: 16; height: 16
                                scale: 0.58
                                anchors.centerIn: parent
                                antialiasing: true
                                ShapePath {
                                    strokeColor: delHover.containsMouse ? HydraHolo.error : HydraTheme.muted
                                    strokeWidth: 2
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap
                                    joinStyle: ShapePath.RoundJoin
                                    PathSvg { path: HydraHolo.iconPaths.x }
                                }
                            }
                            MouseArea {
                                id: delHover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: HydraAssistantApi._request("POST", "/api/memory",
                                    { "delete": body }, () => memView.refreshMem())
                            }
                        }
                    }
                }
                Connections {
                    target: workbenchFace
                    function onWorkPageChanged() {
                        if (workbenchFace.workPage === "memory") memView.refreshMem()
                    }
                }

                // settings page: theme preset row (the shell's own applyTheme
                // mechanism), the reduced-motion override (HydraState.setMotion),
                // API key drafts, and the voice section. A Flickable, not a
                // bare Column: keys + usage lines + voice overflow 548px.
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 20
                    contentHeight: settingsCol.height
                    clip: true
                    visible: workbenchFace.workPage === "settings"
                    Column {
                        id: settingsCol
                        width: parent.width
                        spacing: 12

                    Text {
                        text: "SETTINGS"
                        color: HydraHolo.primary
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(HydraHolo.fsSm * HydraState.fontScale)
                        font.letterSpacing: Math.round(HydraHolo.fsSm * 0.3 * HydraState.fontScale)
                    }

                    Text {
                        text: "THEME — APPLIES SHELL-WIDE"
                        color: HydraTheme.muted
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                        font.letterSpacing: Math.round(HydraHolo.fsMicro * 0.34 * HydraState.fontScale)
                    }
                    Row {
                        spacing: 8
                        Repeater {
                            model: HydraTheme.themeNames
                            delegate: Rectangle {
                                required property string modelData
                                width: 76; height: 30
                                radius: HydraMetrics.rTile
                                color: HydraState.themeName === modelData ? HydraMaterials.tileGlass : "transparent"
                                border.color: HydraState.themeName === modelData ? HydraHolo.primary : HydraMaterials.border
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.toUpperCase()
                                    color: HydraState.themeName === modelData ? HydraTheme.text : HydraTheme.muted
                                    font.family: HydraTheme.fontUI
                                    font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: HydraState.applyTheme(modelData)
                                }
                            }
                        }
                    }

                    Text {
                        text: "MOTION — REDUCED OVERRIDE"
                        color: HydraTheme.muted
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                        font.letterSpacing: Math.round(HydraHolo.fsMicro * 0.34 * HydraState.fontScale)
                    }
                    Row {
                        spacing: 10
                        Rectangle {
                            width: 130; height: 30
                            radius: HydraMetrics.rTile
                            color: "transparent"
                            border.color: HydraState.reducedMotion ? HydraHolo.warning : HydraMaterials.border
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: HydraState.reducedMotion ? "REDUCED" : "FULL"
                                color: HydraState.reducedMotion ? HydraHolo.warning : HydraTheme.text
                                font.family: HydraTheme.fontUI
                                font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: HydraState.setMotion(!HydraState.reducedMotion)
                            }
                        }
                        Text {
                            text: "every HydraMotion duration collapses to 0"
                            color: HydraTheme.muted
                            font.family: HydraTheme.fontMono
                            font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: "API KEYS — SAVED TO 600 FILES, NEVER ECHOED"
                        color: HydraTheme.muted
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                        font.letterSpacing: Math.round(HydraHolo.fsMicro * 0.34 * HydraState.fontScale)
                    }
                    Repeater {
                        model: workbenchFace.keyProviders
                        delegate: Column {
                            required property string key
                            required property string label
                            required property string extra
                            width: settingsCol.width
                            spacing: 4
                            Row {
                                spacing: 8
                                Text {
                                    text: label.toUpperCase()
                                    color: HydraTheme.text
                                    width: 110
                                    font.family: HydraTheme.fontMono
                                    font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                // ACTIVE badge instead of a dead password row:
                                // a saved key is never shown again (not even masked
                                // length). To replace: unlock the file, retype, Save.
                                Text {
                                    visible: !!workbenchFace.keyActive[key]
                                    text: "● ACTIVE"
                                    color: HydraHolo.primary
                                    font.family: HydraTheme.fontMono
                                    font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    visible: !!workbenchFace.keyActive[key]
                                    text: "CHANGE"
                                    color: HydraTheme.muted
                                    font.family: HydraTheme.fontMono
                                    font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                                    font.underline: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: workbenchFace.unlockProvider(key)
                                    }
                                }
                                TextInput {
                                    visible: !workbenchFace.keyActive[key]
                                    width: 340; height: 26
                                    color: HydraTheme.text
                                    font.family: HydraTheme.fontMono
                                    font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                                    echoMode: TextInput.Password
                                    onTextEdited: workbenchFace.keyDrafts[key] = text
                                    Component.onCompleted: workbenchFace.keyInputs.push({ box: this, key: key })
                                    // Empty password inputs are otherwise invisible —
                                    // a 1px underline marks the field.
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 1
                                        color: HydraMaterials.border
                                    }
                                }
                                Item {
                                    width: 180; height: 26
                                    visible: extra !== ""
                                    TextInput {
                                        id: extraInput
                                        anchors.fill: parent
                                        color: HydraTheme.text
                                        font.family: HydraTheme.fontMono
                                        font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                                        onTextEdited: workbenchFace.keyDrafts[key + "_" + extra] = text
                                        Component.onCompleted: workbenchFace.keyInputs.push({ box: this, key: key + "_" + extra })
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        visible: extraInput.text.length === 0 && !extraInput.activeFocus
                                        text: extra === "account" ? "ACCOUNT ID" : "BASE URL"
                                        color: HydraTheme.muted
                                        font: extraInput.font
                                    }
                                }
                            }
                            // dim usage line under each saved provider row
                            Text {
                                visible: !!workbenchFace.keyActive[key] && workbenchFace.usageLine(key) !== ""
                                x: 118
                                text: workbenchFace.usageLine(key)
                                color: HydraTheme.muted
                                font.family: HydraTheme.fontMono
                                font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            }
                        }
                    }
                    Row {
                        spacing: 10
                        Rectangle {
                            width: 120; height: 30
                            radius: HydraMetrics.rTile
                            color: "transparent"
                            border.color: HydraHolo.primary
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "SAVE"
                                color: HydraHolo.primary
                                font.family: HydraTheme.fontUI
                                font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: workbenchFace.saveKeys()
                            }
                        }
                        Text {
                            text: workbenchFace.keysNote
                            color: HydraHolo.warning
                            width: 480
                            wrapMode: Text.WordWrap
                            font.family: HydraTheme.fontMono
                            font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: "VOICE — LIVE, NO RESTART"
                        color: HydraTheme.muted
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                        font.letterSpacing: Math.round(HydraHolo.fsMicro * 0.34 * HydraState.fontScale)
                    }
                    Row {
                        spacing: 8
                        Text {
                            text: "TTS"
                            color: HydraTheme.text
                            width: 110
                            font.family: HydraTheme.fontMono
                            font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: workbenchFace.voiceInfo.current === "" ? "—" : workbenchFace.voiceInfo.current
                            color: HydraHolo.primary
                            font.family: HydraTheme.fontMono
                            font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 76; height: 30
                            radius: HydraMetrics.rTile
                            color: "transparent"
                            border.color: HydraHolo.primary
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "CYCLE"
                                color: HydraHolo.primary
                                font.family: HydraTheme.fontUI
                                font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: workbenchFace.cycleVoice("next")
                            }
                        }
                        Text {
                            visible: workbenchFace.voiceNote !== ""
                            text: workbenchFace.voiceNote
                            color: HydraTheme.muted
                            width: 300
                            wrapMode: Text.WordWrap
                            font.family: HydraTheme.fontMono
                            font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    // available voice ids, current highlighted, tap to select
                    Flow {
                        width: settingsCol.width
                        spacing: 8
                        Repeater {
                            model: workbenchFace.voiceInfo.voiceIds
                            delegate: Text {
                                required property string modelData
                                text: modelData.toUpperCase()
                                color: workbenchFace.voiceInfo.current === modelData ? HydraHolo.primary : HydraTheme.muted
                                font.family: HydraTheme.fontMono
                                font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                                font.underline: workbenchFace.voiceInfo.current !== modelData
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: workbenchFace.cycleVoice(modelData)
                                }
                            }
                        }
                    }
                    Text {
                        text: "STT " + workbenchFace.voiceInfo.sttEngine + (workbenchFace.sttBase() !== "" ? " · " + workbenchFace.sttBase() : "")
                        color: HydraTheme.muted
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                    }
                    Row {
                        spacing: 8
                        Text {
                            text: "WAKE"
                            color: HydraTheme.text
                            width: 110
                            font.family: HydraTheme.fontMono
                            font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Repeater {
                            model: ListModel {
                                ListElement { label: "LOW"; val: 0.45 }
                                ListElement { label: "STD"; val: 0.65 }
                                ListElement { label: "HIGH"; val: 0.85 }
                            }
                            delegate: Rectangle {
                                required property string label
                                required property real val
                                width: 76; height: 30
                                radius: HydraMetrics.rTile
                                color: "transparent"
                                border.color: workbenchFace.voiceInfo.wake === val ? HydraHolo.primary : HydraMaterials.border
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: label
                                    color: workbenchFace.voiceInfo.wake === val ? HydraHolo.primary : HydraTheme.muted
                                    font.family: HydraTheme.fontUI
                                    font.pixelSize: Math.round(HydraHolo.fsMicro * HydraState.fontScale)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: workbenchFace.setWake(val)
                                }
                            }
                        }
                    } // settingsCol
                } // settings Flickable

                // routines/flows/agents/system: read-only lists from /api/<page>
                ListView {
                    id: pageList
                    anchors.fill: parent
                    visible: workbenchFace.workPage === "routines"
                           || workbenchFace.workPage === "flows"
                           || workbenchFace.workPage === "agents"
                    clip: true; spacing: 8
                    model: ListModel { id: pageModel }
                    delegate: Column {
                        required property string title
                        required property string sub
                        spacing: 2
                        Text { text: title; color: HydraTheme.text
                            font.family: HydraTheme.fontUI; font.pixelSize: Math.round(HydraHolo.fsBody * HydraState.fontScale) }
                        Text { text: sub; color: HydraTheme.muted; width: pageList.width
                            wrapMode: Text.WordWrap
                            font.family: HydraTheme.fontMono; font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale) }
                    }
                }
            }
            Component {
                id: systemPanel
                HydraHoloPanel {
                    title: "SYSTEM"
                    status: workbenchFace.sysStatus
                    state: workbenchFace.sysState
                    message: workbenchFace.sysMessage
                    ListView {
                        id: sysList
                        anchors.fill: parent
                        clip: true
                        spacing: 10
                        model: workbenchFace.sysModel
                        delegate: Column {
                            required property string slug
                            required property string desc
                            width: sysList.width
                            spacing: 2
                            Text {
                                text: slug
                                color: HydraHolo.primary
                                font.family: HydraTheme.fontMono
                                font.pixelSize: Math.round(HydraHolo.fsSm * HydraState.fontScale)
                            }
                            Text {
                                text: desc
                                color: HydraTheme.text
                                width: sysList.width
                                wrapMode: Text.WordWrap
                                font.family: HydraTheme.fontMono
                                font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            }
                        }
                    }
                }
            }
            Component {
                id: stepsPanel
                HydraHoloPanel {
                    title: "LIVE STEPS"
                    status: HydraAssistantApi.stepsModel.count + " ACTIVE"
                    state: HydraAssistantApi.stepsModel.count > 0 ? "content" : "empty"
                    message: "NO LIVE STEPS — ACTIONS APPEAR HERE AS HYDRA WORKS"
                    ListView {
                        id: stepsList
                        anchors.fill: parent
                        clip: true
                        spacing: 8
                        model: HydraAssistantApi.stepsModel
                        delegate: Row {
                            required property string body
                            spacing: 8
                            Rectangle {
                                width: 7; height: 7; radius: 3.5
                                color: HydraHolo.primary
                            }
                            Text {
                                text: body
                                color: HydraTheme.text
                                width: stepsList.width - 15
                                wrapMode: Text.WrapAnyWhere
                                font.family: HydraTheme.fontMono
                                font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
                            }
                        }
                    }
                }
            }

            Item {
                id: panelLayer
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: workbenchFace.openPanel !== ""

                // full-size dim — blocks the rail behind the panel and gives
                // click-outside-to-close (the card is the Loader above it)
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.45)
                    MouseArea { anchors.fill: parent; onClicked: workbenchFace.closePanel() }
                }

                Loader {
                    anchors.centerIn: parent
                    active: workbenchFace.openPanel !== ""
                    sourceComponent: workbenchFace.openPanel === "system" ? systemPanel : stepsPanel
                    onLoaded: {
                        if (item) item.closed.connect(workbenchFace.closePanel)
                        panelKeySink.forceActiveFocus()
                    }
                }

                // Esc dismisses the topmost (only) panel. The sink holds focus
                // while a panel is open; closePanel simply clears it.
                Item {
                    id: panelKeySink
                    focus: false
                    Keys.onEscapePressed: root.closeTop()
                }
            }
        }
    }
    }

    // last exchange, under the dock. The chat popup shows the reply on the
    // presence face; this band serves the docked pages. Hidden while an
    // overlay panel is open (the card covers the band) or chat popup is up.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        width: Math.min(parent.width - 120, 760)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: workbenchFace.openPanel === "" && root.dockPage !== "" && root.holoPopup !== "chat"
        text: HydraAssistantApi.reply
        color: HydraTheme.text
        font.family: HydraTheme.fontUI
        font.pixelSize: Math.round(HydraHolo.fsMd * HydraState.fontScale)
    }

    // docked chat page is transcript-only: replies go through the
    // presence-face chat panel (presence face, chat icon, top right).
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        visible: root.dockPage === "chat"
                 && workbenchFace.openPanel === ""
        text: "Reply from the presence face — open the chat panel"
        color: HydraTheme.muted
        font.family: HydraTheme.fontMono
        font.pixelSize: Math.round(HydraHolo.fsTiny * HydraState.fontScale)
    }

    // ── HUD chrome (identity / status / icon launchers / geometry) ──
    HydraJarvisHud {
        id: hud
        anchors.fill: parent
        stateName: HydraAssistantApi.stateName
        level: HydraAssistantApi.level
        online: HydraAssistantApi.online
        face: root.face
        dockPage: root.dockPage
        activePopup: root.holoPopup
    }

    Connections {
        target: hud
        function onPopupRequested(slug) { root.togglePopup(slug) }
        function onCloseDockRequested() { root.dockPage = "" }
        function onWindowModeRequested() { root.windowModeRequested() }
    }

    // Esc: fullscreen -> windowed first (never quits), then overlay
    // panel, then dock. The panelKeySink below only holds focus while a
    // panel is open, so this Shortcut covers the unfocused case.
    function closeTop() {
        if (root.isFullscreen) root.windowModeRequested()
        else if (workbenchFace.openPanel !== "") workbenchFace.closePanel()
        else if (root.dockPage !== "") root.dockPage = ""
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.uiOpen
        onActivated: root.closeTop()
    }

    // ── boot overlay: remounts per open (Loader unmount kills its timers) ──
    Loader {
        id: bootLoader
        anchors.fill: parent
        active: root._bootPending && root.uiOpen
        sourceComponent: HydraJarvisBoot {}
        onLoaded: {
            item.finished.connect(function() {
                root._bootPending = false
                bootLoader.active = false
            })
            item.start()
        }
    }
}
// cache-bust
