// AxoraHoloCameraPopup — viewport + narration line.
// Live: GET /api/camera via AxoraAssistantApi._request, fetched on open.
// Returns {"image": "<base64-jpeg>"} or {"error": "..."}; the viewport
// paints the frame as a data: URL where the placeholder sits, with
// capturing/error/offline states carried in camState/camMessage.
import QtQuick
import QtMultimedia
import "../core"

AxoraHoloPanel {
    id: panel
    title: "CAMERA"
    status: panel.camState === "content" ? (panel.liveOk ? ("LIVE VIDEO" + (panel.fmtText !== "" ? " · " + panel.fmtText : "")) : "GET /api/camera · LIVE") : ""
    state: panel.camState
    message: panel.camMessage

    // Maximize: fills the window center like the tapes' fullscreen camera;
    // the ring stays mounted at the bottom, widgets overlay the feed.
    property bool maximized: false
    width: maximized ? root.width - 36 : 620
    height: maximized ? root.height - 130 : 460

    property string cameraSource: ""
    property bool hasFrames: false
    property string camState: "loading"
    property string camMessage: "OPENING LIVE CAMERA"
    // Live video first: holds the device only while this popup exists
    // (Loader destroys it on close). HTTP snapshots are the fallback when
    // the live feed errors or never delivers a frame. liveOk flips only on
    // real frames (contentRect goes non-empty), not on intent.
    property bool liveOk: liveView.contentRect.width > 0
    CaptureSession {
        camera: liveCam
        videoOutput: liveView
    }
    Camera {
        id: liveCam
        active: true
        onErrorChanged: if (liveCam.error !== Camera.NoError) fetchCamera()
    }
    // Smooth 30fps: ask for the device's fastest format (this camera does
    // 30fps up to 720p MJPG; Qt defaults lower). Applied once before the
    // first frame; never touches a running feed.
    property bool fmtApplied: false
    property string fmtText: ""
    MediaDevices { id: mediaDevs }
    function applyFastFormat() {
        if (panel.fmtApplied) return
        const dev = mediaDevs.defaultVideoInput || (mediaDevs.videoInputs.length ? mediaDevs.videoInputs[0] : null)
        if (!dev) return
        if (!dev.videoFormats.length) return
        let best = dev.videoFormats[0]
        for (let i = 1; i < dev.videoFormats.length; i++) {
            const f = dev.videoFormats[i]
            if (f.maxFrameRate > best.maxFrameRate
                || (f.maxFrameRate === best.maxFrameRate
                    && f.resolution.width * f.resolution.height > best.resolution.width * best.resolution.height))
                best = f
        }
        panel.fmtApplied = true
        panel.fmtText = best.resolution.width + "x" + best.resolution.height + "@" + Math.round(best.maxFrameRate)
        liveCam.cameraFormat = best
        liveCam.active = false
        liveCam.active = true
    }
    Connections {
        target: mediaDevs
        function onVideoInputsChanged() { applyFastFormat() }
    }
    // Enumeration can arrive late (backend thread); retry briefly. One late
    // restart costs a sub-second freeze, then 30fps forever. Gives up so a
    // missing camera still falls through to the HTTP path.
    property int fmtTries: 0
    Timer {
        id: fmtPoll
        interval: 800
        repeat: true
        running: !panel.fmtApplied && panel.fmtTries < 8 && panel.camState === "loading"
        onTriggered: { panel.fmtTries++; applyFastFormat() }
    }
    Timer {
        id: liveWatchdog
        interval: 6000
        running: !panel.liveOk && (panel.camState === "loading")
        onTriggered: if (!panel.liveOk) fetchCamera()
    }
    onLiveOkChanged: if (panel.liveOk) {
        panel.camWatchdog.stop()
        liveWatchdog.stop()
        camRetry.stop()
        panel.camState = "content"
        panel.camMessage = ""
    }
    property Timer camWatchdog: Timer {
        interval: 8000
        repeat: false
        running: false
        onTriggered: {
            if (panel.camState === "loading") {
                panel.camState = "error"
                panel.camMessage = "NO RESPONSE AFTER 8S — API DOWN OR UNREACHABLE"
            }
        }
    }
    property int camTries: 0
    property int camFails: 0
    // Persistent feed: refresh every 3s while the card shows a frame.
    // Quiet path never touches camState (no loading flicker); 3 straight
    // failures surface the error instead of looping forever.
    Timer {
        id: camLive
        interval: 3000
        repeat: true
        running: !panel.liveOk && panel.camState === "content"
        onTriggered: fetchQuiet()
    }
    function fetchQuiet() {
        if (panel.liveOk || !AxoraAssistantApi.online) return
        AxoraAssistantApi._request("GET", "/api/camera", null, (obj) => {
            if (obj && obj.image) {
                panel.camFails = 0
                panel.cameraSource = "data:image/jpeg;base64," + obj.image
                panel.hasFrames = true
            } else if (++panel.camFails >= 3) {
                panel.camState = "error"
                panel.camMessage = "CAMERA FEED LOST"
            }
        })
    }
    Timer {
        id: camRetry
        interval: 1500
        onTriggered: fetchCamera()
    }
    function fetchAgain() { fetchCamera() }
    function fetchCamera() {
        if (panel.liveOk) return
        panel.camState = "loading"
        panel.camMessage = ""
        panel.hasFrames = false
        panel.camWatchdog.restart()
        if (!AxoraAssistantApi.online) {
            // Boot race: popup forced open before the first poll answers.
            // Retry a few times before declaring offline (real users opening
            // later never hit this; probes that open at load always do).
            if (panel.camTries < 4) {
                panel.camTries++
                camRetry.restart()
                return
            }
            panel.camWatchdog.stop()
            panel.camState = "offline"
            panel.camMessage = "API NOT REACHABLE — RETRY ONCE THE ASSISTANT SERVICE ANSWERS"
            return
        }
        panel.camTries = 0
        AxoraAssistantApi._request("GET", "/api/camera", null, (obj) => {
            panel.camWatchdog.stop()
            if (obj && obj.image) {
                panel.cameraSource = "data:image/jpeg;base64," + obj.image
                panel.hasFrames = true
                panel.camState = "content"
                panel.camMessage = ""
            } else if (obj && obj.error) {
                panel.camState = "error"
                panel.camMessage = String(obj.error).toUpperCase()
            } else {
                panel.camState = "error"
                panel.camMessage = "CAMERA RETURNED NO FRAME"
            }
        })
    }
        // Boot race: opened before the first poll answers, `online` is false
    // and the fetch instantly errors. Re-fetch on the false->true flip —
    // no retry counters, no fixed waits.
    Connections {
        target: AxoraAssistantApi
        function onOnlineChanged() { if (AxoraAssistantApi.online) fetchAgain() }
    }

Component.onCompleted: applyFastFormat()
// Release the device before QML teardown cascades — an active capture
// during exit leaves the multimedia thread racing object destruction.
Component.onDestruction: {
    fmtPoll.stop()
    camLive.stop()
    liveWatchdog.stop()
    liveCam.active = false
}

    Column {
        anchors.fill: parent
        anchors.topMargin: 52
        anchors.bottomMargin: 36
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12

        Text {
            text: "VIEWPORT"
            color: AxoraTheme.muted
            font.family: AxoraTheme.fontMono
            font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
            font.letterSpacing: 2
        }
        Text {
            x: parent.width - width
            text: panel.maximized ? "MINIMIZE" : "MAXIMIZE"
            color: maxHover.containsMouse ? AxoraHolo.primary : AxoraTheme.muted
            font.family: AxoraTheme.fontMono
            font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
            font.letterSpacing: 2
            font.underline: maxHover.containsMouse
            MouseArea {
                id: maxHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: panel.maximized = !panel.maximized
            }
        }

        Rectangle {
            width: parent.width
            height: panel.maximized ? 380 : 250
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.45)
            border.color: Qt.rgba(1, 1, 1, 0.22)
            border.width: 1
            clip: true

            // HUD corner brackets — exactly TWO: top-left + bottom-right
            Repeater {
                model: 2
                delegate: Item {
                    width: 12; height: 12
                    x: (index % 2 === 0) ? 6 : parent.width - 18
                    y: (index === 0) ? 6 : parent.height - 18
                    Rectangle { width: 12; height: 2; color: AxoraHolo.primary; x: 0; y: (index === 0) ? 0 : 10 }
                    Rectangle { width: 2; height: 12; color: AxoraHolo.primary; x: (index % 2 === 0) ? 0 : 10; y: 0 }
                }
            }

            // live video replaces the placeholder when the camera is active;
            // HTTP frames show only when live failed and snapshots arrived.
            VideoOutput {
                id: liveView
                anchors.fill: parent
                visible: panel.liveOk
                fillMode: VideoOutput.PreserveAspectCrop
                mirrored: true
            }
            Image {
                anchors.fill: parent
                visible: !panel.liveOk && panel.hasFrames
                source: panel.cameraSource
                fillMode: Image.PreserveAspectCrop
            }
            Column {
                anchors.centerIn: parent
                spacing: 6
                visible: !panel.liveOk && !panel.hasFrames
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: panel.camState === "loading" ? "opening live camera…" : panel.camState === "offline" ? "Camera offline" : panel.camState === "content" ? "" : "Camera error"
                    color: AxoraTheme.text
                    font.family: AxoraTheme.fontUI
                    font.pixelSize: Math.round(AxoraHolo.fsBody * AxoraState.fontScale)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: panel.camState === "loading" ? "GET /api/camera" : panel.camMessage !== "" ? panel.camMessage : (panel.liveOk ? "LIVE VIDEO" : "No camera backend configured")
                    color: AxoraTheme.muted
                    font.family: AxoraTheme.fontMono
                    font.pixelSize: Math.round(AxoraHolo.fsTiny * AxoraState.fontScale)
                }
            }
        }

        Text {
            text: "NARRATION"
            color: AxoraTheme.muted
            font.family: AxoraTheme.fontMono
            font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
            font.letterSpacing: 2
        }
        Text {
            text: panel.camState === "loading" ? "Opening the live camera…" : panel.camState === "content" ? (panel.liveOk ? "Live video from the on-box camera." : "Live frame from GET /api/camera.") : panel.camMessage !== "" ? panel.camMessage.charAt(0) + panel.camMessage.slice(1).toLowerCase() + "." : "Camera offline — no camera backend."
            color: AxoraTheme.text
            width: parent.width
            wrapMode: Text.WordWrap
            font.family: AxoraTheme.fontUI
            font.pixelSize: Math.round(AxoraHolo.fsBody * AxoraState.fontScale)
        }
    }
}
