// AxoraApprovalPopup — standalone approval card. The panel holo is gone and
// the window only shows approvals while open, so pending actions need their
// own surface: this card maps whenever the backend holds a pending tool call,
// with Approve (emerald) / Ignore (muted). Token path first (/api/confirm),
// legacy /api/approve fallback — same contract as the window overlay.
// Window rules: visible+focusable follow state exactly (a mapped-but-closed
// layershell surface keeps the pointer grab and dead-locks the desktop).
import QtQuick
import Quickshell
import "../core"

PanelWindow {
    id: root
    property bool hasPending: AxoraAssistantApi.pendingModel.count > 0
    visible: hasPending
    focusable: hasPending
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: 460
    implicitHeight: 250

    // The main shell has no other polling driver since the panel holo died
    // (Ui drives it only inside the window). Without this the pendingModel
    // never fills and this card never fires.
    Component.onCompleted: AxoraAssistantApi.setPolling(true)

    // token receipt per pending name (GET /api/state), refreshed whenever
    // the set changes. Shown truncated — a receipt, never the secret.
    property var confirmMeta: ({})
    property int _tick: 0
    function refreshMeta() {
        AxoraAssistantApi._request("GET", "/api/state", null, (obj) => {
            const m = {}
            for (const p of (obj && obj.pending) || []) {
                if (p.token) m[p.name] = { token: p.token, expires_at: p.expires_at || 0 }
            }
            root.confirmMeta = m
        })
    }
    onHasPendingChanged: if (hasPending) refreshMeta()
    function remainFor(name) {
        root._tick
        const m = root.confirmMeta[name]
        if (!m) return -1
        return Math.max(0, Math.round(m.expires_at - Date.now() / 1000))
    }
    Timer { interval: 1000; repeat: true; running: root.hasPending; onTriggered: root._tick++ }

    function firstPending() {
        if (AxoraAssistantApi.pendingModel.count === 0) return null
        return AxoraAssistantApi.pendingModel.get(0)
    }
    function doApprove() {
        const p = firstPending()
        if (!p) return
        const m = root.confirmMeta[p.name]
        if (m && m.token) AxoraAssistantApi._request("POST", "/api/confirm", { token: m.token, verdict: "approve" }, () => AxoraAssistantApi.refresh())
        else AxoraAssistantApi.approve(p.name, p.args)
    }
    function doIgnore() {
        const p = firstPending()
        if (!p) return
        const m = root.confirmMeta[p.name]
        if (m && m.token) AxoraAssistantApi._request("POST", "/api/confirm", { token: m.token, verdict: "hold" }, () => AxoraAssistantApi.refresh())
        else AxoraAssistantApi.hold(p.name)
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: AxoraHolo.bg
        border.color: AxoraHolo.warning
        border.width: 1
        // HUD corner brackets — exactly TWO: top-left + bottom-right
        Repeater {
            model: 2
            delegate: Item {
                width: 14; height: 14
                x: (index % 2 === 0) ? 5 : parent.width - 19
                y: (index === 0) ? 5 : parent.height - 19
                Rectangle { width: 14; height: 2; color: AxoraHolo.warning; x: 0; y: (index === 0) ? 0 : 12 }
                Rectangle { width: 2; height: 14; color: AxoraHolo.warning; x: (index % 2 === 0) ? 0 : 12; y: 0 }
            }
        }
        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 8
            Text {
                text: "APPROVAL REQUIRED" + (AxoraAssistantApi.pendingModel.count > 1 ? " · " + AxoraAssistantApi.pendingModel.count : "")
                color: AxoraHolo.warning
                font.family: AxoraTheme.fontMono
                font.pixelSize: Math.round(AxoraHolo.fsSm * AxoraState.fontScale)
                font.letterSpacing: 3
            }
            Text {
                text: {
                    const p = root.hasPending ? AxoraAssistantApi.pendingModel.get(0) : null
                    return p ? p.name : ""
                }
                color: AxoraTheme.text
                font.family: AxoraTheme.fontMono
                font.pixelSize: Math.round(AxoraHolo.fsBody * AxoraState.fontScale)
            }
            Text {
                text: {
                    const p = root.hasPending ? AxoraAssistantApi.pendingModel.get(0) : null
                    if (!p) return ""
                    try { return JSON.stringify(p.args).slice(0, 90) } catch (e) { return "" }
                }
                color: AxoraTheme.muted
                font.family: AxoraTheme.fontMono
                font.pixelSize: Math.round(AxoraHolo.fsTiny * AxoraState.fontScale)
                wrapMode: Text.WordWrap
                width: parent.width
            }
            Text {
                text: {
                    const p = root.hasPending ? AxoraAssistantApi.pendingModel.get(0) : null
                    if (!p) return ""
                    const r = root.remainFor(p.name)
                    return r >= 0 ? "TOKEN " + r + "s" : "LEGACY — NO TOKEN"
                }
                color: AxoraTheme.muted
                font.family: AxoraTheme.fontMono
                font.pixelSize: Math.round(AxoraHolo.fsMicro * AxoraState.fontScale)
            }
            Row {
                spacing: 12
                Item {
                    width: 130; height: 34
                    Rectangle { anchors.fill: parent; radius: 8; color: AxoraHolo.primary }
                    Text { anchors.centerIn: parent; text: "APPROVE"; color: "#050807"; font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(AxoraHolo.fsSm * AxoraState.fontScale); font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: root.doApprove() }
                }
                Item {
                    width: 130; height: 34
                    Rectangle { anchors.fill: parent; radius: 8; color: "transparent"; border.color: AxoraMaterials.border; border.width: 1 }
                    Text { anchors.centerIn: parent; text: "IGNORE"; color: AxoraTheme.text; font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(AxoraHolo.fsSm * AxoraState.fontScale) }
                    MouseArea { anchors.fill: parent; onClicked: root.doIgnore() }
                }
            }
        }
    }
}
