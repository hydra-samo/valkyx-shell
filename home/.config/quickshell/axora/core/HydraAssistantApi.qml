// AxoraAssistantApi — ONE data channel for the holo window.
// Voice presence (sub-250ms) rides the state file; everything else is the
// /api/state snapshot polled at 1 Hz while the window is open.
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: api
    property string stateName: "idle"
    property real level: 0
    property string reply: ""
    property string apiBase: ""
    property string token: ""
    property bool tokenReady: false
    // false until the first /api/state poll answers; a 401 or network failure
    // leaves it false so the presence face can dim into an offline ring.
    // Debounced: one failed poll (backend busy mid-turn, tailscale blip) must
    // not flap the whole HUD to OFFLINE — needs 3 consecutive misses (~3s).
    property bool online: false
    property int _misses: 0

    property ListModel historyModel: ListModel {}
    property ListModel stepsModel: ListModel {}
    property ListModel pendingModel: ListModel {}
    property ListModel memoryModel: ListModel {}
    property var _fillSeen: ({})

    // resolve tailnet IP once (server binds it, never loopback)
    property Process _ipResolver: Process {
        running: true
        command: ["tailscale", "ip", "-4"]
        stdout: SplitParser {
            onRead: (line) => {
                const ip = line.trim()
                if (ip.length > 0 && api.apiBase === "")
                    api.apiBase = "http://" + ip + ":8446"
            }
        }
    }
    property Process _tokenReader: Process {
        running: true
        command: ["cat", StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/state/axora/remote-token"]
        stdout: SplitParser {
            onRead: (line) => {
                api.token = line.trim()
                api.tokenReady = api.token.length > 0
            }
        }
    }

    // presence state file (the fast path) — one-shot cat + StdioCollector,
    // the tree's proven idiom (a long-running sh|stdout loop delivers stale
    // lines in this build; the pre-brace-fix hang was cat's stdio buffer)
    property Timer _statePoll: Timer {
        interval: 250
        repeat: true
        running: true
        onTriggered: api._stateRead.running = true
    }
    property Process _stateRead: Process {
        command: ["cat", "/run/user/1000/axora-assistant.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim()
                if (line.length === 0) return
                try {
                    const j = JSON.parse(line)
                    const fresh = (Date.now() / 1000 - (j.ts || 0)) < 5
                    api.stateName = fresh ? (j.state || "idle") : "idle"
                    api.level = fresh ? (j.level || 0) : 0
                    if (j.reply && fresh) api.reply = j.reply
                } catch (e) {}
            }
        }
    }

    function _fill(model, rows, fields) {
        // Skip no-op rebuilds: clear()+append every poll churns every
        // delegate's entry object 1Hz, which re-arms per-line animations
        // (decoder scramble) and re-lays lists for zero new data.
        const sig = (rows || []).length + "|" + JSON.stringify((rows || []).slice(-1))
        const key = model === historyModel ? "h" : model === stepsModel ? "s"
            : model === pendingModel ? "p" : "m"
        if (api._fillSeen[key] === sig) return
        api._fillSeen[key] = sig
        model.clear()
        for (const r of rows || []) {
            const o = {}
            for (const f of fields) {
                if (f === "body") o[f] = r.text !== undefined ? r.text : ""
                else o[f] = r[f] !== undefined ? r[f] : ""
            }
            model.append(o)
        }
    }

    property bool polling: false

    // Poller is `running: true` from declaration (NOT dynamically started):
    // a repeating Timer started via start()/running= after the singleton is
    // live fires once and never re-fires in this Quickshell build, whereas a
    // `running: true` declaration timer repeats reliably (cf. _statePoll).
    // The gate lives in refresh() so no request is made while the window is shut.
    property Timer poller: Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: api.refresh()
    }

    function setPolling(on) {
        api.polling = on
    }

    function refresh() {
        if (!api.polling) return
        _request("GET", "/api/state", null, (obj) => {
            _fill(historyModel, obj.history, ["kind", "body", "ts"])
            _fill(stepsModel, obj.steps, ["kind", "body", "ts"])
            _fill(pendingModel, obj.pending, ["name", "args"])
            _fill(memoryModel, obj.memory, ["kind", "body", "ts"])
            // amber state: nothing publishes needs-approval to the state file,
            // so surface it here; the 250ms tail restores the real state when clear
            if (obj.pending && obj.pending.length > 0)
                api.stateName = "needs-approval"
        })
    }
    function chat(text) {
        // surface the typed turn on the presence transcript immediately; the
        // voice path sets reply via the state file, typed turns have no state
        // file line, so echo here or the presence face stays stale.
        api.reply = "➤ " + text
        _request("POST", "/api/chat", { text: text }, (obj) => {
            api.refresh()
            if (obj && obj.text) api.reply = obj.text
        })
    }
    function approve(name, args) {
        _request("POST", "/api/approve", { name: name, args: args || {} }, (obj) => { api.refresh() })
    }
    function hold(name) {
        _request("POST", "/api/approve", { name: name, args: {}, allow: false }, (obj) => { api.refresh() })
    }

    function _request(method, path, body, cb) {
        if (api.apiBase === "" || !api.tokenReady) return
        const xhr = new XMLHttpRequest()
        xhr.open(method, api.apiBase + path)
        xhr.setRequestHeader("X-Axora-Token", api.token)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status > 0) {
                api._misses = 0
                api.online = true
            } else if (++api._misses >= 3) {
                api.online = false
            }
            // token was rotated server-side → re-read it here, no shell restart
            // needed; the 1 Hz poller retries the request with the fresh token.
            if (api.online && xhr.status === 401) {
                api.tokenReady = false
                api.token = ""
                api._tokenReader.running = true
            }
            if (xhr.status === 200 && cb) {
                try { cb(JSON.parse(xhr.responseText)) } catch (e) {}
            }
        }
        xhr.send(body ? JSON.stringify(body) : null)
    }
}