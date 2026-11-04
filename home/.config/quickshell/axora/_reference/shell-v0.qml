//@ pragma UseQApplication
// ============================================================
// AXORA SHELL v2 — settings · notifications · wifi · osd · dock
// Brand: #00A86B on near-black green · Space Grotesk · quiet
// Toggle panel: Super+S  (qs -c axora ipc call panel toggle)
// ============================================================
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
    id: root

    // ---------------- brand tokens ----------------
    readonly property string accent: "#00A86B"
    readonly property string accentDim: "#0e3d2b"
    readonly property string bg: "#e60a1210"
    readonly property string surface: "#101614"
    readonly property string field: "#161d1a"
    readonly property string textC: "#e6eae8"
    readonly property string muted: "#8a938f"
    readonly property string danger: "#c96a6a"
    readonly property string line: "#1e2422"
    readonly property string fontName: "Space Grotesk"

    property bool panelOpen: false
    property int panelTab: 0                 // 0=settings 1=notifications
    property var states: ({})
    property real volPct: 0
    property real briPct: 50
    property bool micMuted: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string netLine: "…"
    property var wifiList: []
    property var notifList: []               // [{app, summary}]
    property string osdMode: ""              // "vol" | "bri" | ""
    property real osdValue: 0

    IpcHandler {
        target: "panel"
        function toggle(): void { root.panelOpen = !root.panelOpen }
        function open(): void { root.panelTab = 0; root.panelOpen = true }
        function close(): void { root.panelOpen = false }
        function notifications(): void { root.panelTab = 1; root.panelOpen = true }
    }

    // ---------------- definitions ----------------
    readonly property var toggles: [
        { key: "wifi",  label: "Wi-Fi",          glyph: "⇅",
          on: "nmcli radio wifi on",             off: "nmcli radio wifi off" },
        { key: "bt",    label: "Bluetooth",      glyph: "ᛒ",
          on: "bluetoothctl power on",           off: "bluetoothctl power off" },
        { key: "dnd",   label: "Do Not Disturb", glyph: "☾",
          on: "makoctl mode -a do-not-disturb",  off: "makoctl mode -r do-not-disturb" },
        { key: "night", label: "Night Light",    glyph: "◐",
          on: "setsid gammastep -O 3500K >/dev/null 2>&1 &", off: "pkill -x gammastep" }
    ]
    function isOn(key) { return states[key] === "enabled" }

    readonly property var workspaces: [
        { num: "01", label: "studio" }, { num: "02", label: "create" },
        { num: "03", label: "code" },   { num: "04", label: "research" },
        { num: "05", label: "personal" },{ num: "06", label: "game" }
    ]

    readonly property var dockApps: [
        { name: "terminal", label: "Terminal", icon: Qt.resolvedUrl("icons/terminal.svg"), cmd: "ptyxis",          cls: "org.gnome.Ptyxis" },
        { name: "web",      label: "Helium",   icon: Qt.resolvedUrl("icons/web.png"),      cmd: "helium-browser",    cls: "helium-browser" },
        { name: "files",    label: "Files",    icon: Qt.resolvedUrl("icons/files.svg"),    cmd: "nautilus",          cls: "org.gnome.Nautilus" },
        { name: "editor",   label: "Editor",   icon: Qt.resolvedUrl("icons/editor.png"),   cmd: "antigravity",       cls: "antigravity" },
        { name: "blender",  label: "Blender",  icon: Qt.resolvedUrl("icons/blender.svg"),  cmd: "blender",           cls: "blender" },
        { name: "resolve",  label: "Resolve",  icon: Qt.resolvedUrl("icons/resolve.png"),  cmd: "davinci-resolve",   cls: "resolve" }
    ]

    // ---------------- command runner ----------------
    property int _execSeq: 0
    Process {
        id: runner
        property string todo: ""
        onTodoChanged: { if (todo.length) { command = ["sh", "-c", todo]; running = true } }
    }
    function exec(cmd) { _execSeq++; runner.todo = cmd + " #seq" + _execSeq }

    // ---------------- unified state poller ----------------
    Process {
        id: stateGet
        command: ["sh", "-c",
            "echo wifi:$(nmcli radio wifi 2>/dev/null)" + "\n" +
            "echo bt:$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo enabled || echo disabled)" + "\n" +
            "echo dnd:$(makoctl mode 2>/dev/null | grep -q dnd && echo enabled || echo disabled)" + "\n" +
            "echo night:$(pgrep -x gammastep >/dev/null && echo enabled || echo disabled)" + "\n" +
            "echo ws:$(hyprctl activeworkspace | grep -oE '\\([0-9]+' | tr -d '(')" + "\n" +
            "echo dock_terminal:$(pgrep -f org.gnome.Ptyxis >/dev/null && echo on || echo off)" + "\n" +
            "echo dock_web:$(pgrep -f helium-browser >/dev/null && echo on || echo off)" + "\n" +
            "echo dock_files:$(pgrep -x nautilus >/dev/null && echo on || echo off)" + "\n" +
            "echo dock_editor:$(pgrep -f antigravity >/dev/null && echo on || echo off)" + "\n" +
            "echo dock_blender:$(pgrep -x blender >/dev/null && echo on || echo off)" + "\n" +
            "echo dock_resolve:$(pgrep -f '/opt/resolve' >/dev/null && echo on || echo off)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const patch = {}
                text.trim().split("\n").forEach(line => {
                    const i = line.indexOf(":")
                    if (i > 0) patch[line.slice(0, i)] = line.slice(i + 1)
                })
                root.states = Object.assign({}, root.states, patch)
            }
        }
    }
    Timer { interval: 4000; running: true; repeat: true; onTriggered: stateGet.running = true }
    Component.onCompleted: stateGet.running = true

    function toggleKey(key) {
        for (let i = 0; i < toggles.length; i++) {
            if (toggles[i].key === key) {
                exec(isOn(key) ? toggles[i].off : toggles[i].on)
                refreshLater.restart()
                return
            }
        }
    }
    Timer { id: refreshLater; interval: 900; onTriggered: stateGet.running = true }

    // ---------------- value getters ----------------
    Process {
        id: volGet
        command: ["sh", "-c", "pamixer --get-volume"]
        stdout: StdioCollector { onStreamFinished: root.volPct = parseInt(text.trim() || "0") }
    }
    Process {
        id: briGet
        command: ["sh", "-c", "echo $(( $(brightnessctl get) * 100 / $(brightnessctl max) ))"]
        stdout: StdioCollector { onStreamFinished: root.briPct = parseInt(text.trim() || "50") }
    }
    Process {
        id: micGet
        command: ["sh", "-c", "pamixer --default-source --get-mute"]
        stdout: StdioCollector { onStreamFinished: root.micMuted = (text.trim() === "true") }
    }
    Process {
        id: mediaGet
        command: ["sh", "-c", "t=$(playerctl metadata title 2>/dev/null); a=$(playerctl metadata artist 2>/dev/null); printf '%s\\n%s' \"$t\" \"$a\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                root.mediaTitle = lines[0] || ""
                root.mediaArtist = lines[1] || ""
            }
        }
    }
    Process {
        id: netGet
        command: ["sh", "-c", "s=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2-); ip=$(hostname -I 2>/dev/null | awk '{print $1}'); printf '%s · %s' \"${s:-offline}\" \"${ip:-no ip}\""]
        stdout: StdioCollector { onStreamFinished: root.netLine = text.trim() }
    }
    // wifi networks
    Process {
        id: wifiScan
        command: ["sh", "-c", "nmcli -t -f in-use,ssid,signal,security dev wifi list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                text.trim().split("\n").forEach(line => {
                    const p = line.split(":")
                    if (p.length >= 3 && p[1] !== "") out.push({ use: p[0] === "*", ssid: p[1], sig: parseInt(p[2]), sec: p[3] || "" })
                })
                root.wifiList = out
            }
        }
    }
    // notifications history
    Process {
        id: notifGet
        command: ["sh", "-c", "makoctl history 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                const blocks = text.trim().split(/\n(?=Notification )/)
                blocks.forEach(b => {
                    if (!b.startsWith("Notification")) return
                    const sum = b.split("\n")[0].replace(/^Notification \d+:\s*/, "")
                    const am = b.match(/App name:\s*(.+)/)
                    out.push({ app: am ? am[1].trim() : "", summary: sum })
                })
                root.notifList = out
            }
        }
    }
    function refreshPanelValues() { volGet.running = true; briGet.running = true; micGet.running = true; mediaGet.running = true; netGet.running = true }
    function refreshWifi() { wifiScan.running = true }
    function refreshNotifs() { notifGet.running = true }
    onPanelOpenChanged: {
        if (panelOpen) {
            refreshPanelValues()
            if (panelTab === 1) refreshNotifs()
            if (panelTab === 0) refreshWifi()
        }
    }
    onPanelTabChanged: {
        if (panelOpen) {
            if (panelTab === 1) refreshNotifs()
            if (panelTab === 0) refreshWifi()
        }
    }

    // ---------------- OSD triggers ----------------
    property real _prevVol: -1
    property real _prevBri: -1
    onVolPctChanged: {
        if (_prevVol >= 0 && Math.abs(volPct - _prevVol) >= 1) { osdMode = "vol"; osdValue = volPct; osdHide.restart() }
        _prevVol = volPct
    }
    onBriPctChanged: {
        if (_prevBri >= 0 && Math.abs(briPct - _prevBri) >= 1) { osdMode = "bri"; osdValue = briPct; osdHide.restart() }
        _prevBri = briPct
    }
    Timer { id: osdHide; interval: 1400; onTriggered: root.osdMode = "" }

    // ================= SETTINGS SIDEBAR =================
    PanelWindow {
        visible: root.panelOpen
        anchors { top: true; right: true; bottom: true }
        margins { top: 30; right: 6; bottom: 56 }
        implicitWidth: 344
        color: "transparent"
        exclusiveZone: -1

        Rectangle {
            anchors.fill: parent
            color: root.bg
            border.color: root.line
            border.width: 1
            radius: 14
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // header
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "AXORA"
                        color: root.accent
                        font.family: root.fontName
                        font.pixelSize: 15
                        font.letterSpacing: 4
                        font.bold: true
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28; height: 28; radius: 8
                        color: closeMa.containsMouse ? root.accentDim : root.field
                        Text { anchors.centerIn: parent; text: "✕"; color: root.muted; font.pixelSize: 13 }
                        MouseArea {
                            id: closeMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.panelOpen = false
                        }
                    }
                }

                // tabs
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: ["SETTINGS", "NOTIFICATIONS"]
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool active: root.panelTab === index
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            radius: 8
                            color: active ? root.accentDim : "transparent"
                            border.color: active ? root.accent : root.line
                            Text {
                                anchors.centerIn: parent
                                text: modelData + (index === 1 && root.notifList.length > 0 ? "  ·" + root.notifList.length : "")
                                color: active ? root.accent : root.muted
                                font.family: root.fontName
                                font.pixelSize: 11
                                font.letterSpacing: 2
                                font.bold: active
                            }
                            TapHandler { cursorShape: Qt.PointingHandCursor; onTapped: root.panelTab = index }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: root.line }

                // ======== TAB: SETTINGS ========
                ColumnLayout {
                    visible: root.panelTab === 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    GridLayout {
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10
                        Layout.fillWidth: true
                        Repeater {
                            model: root.toggles
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool on: root.isOn(modelData.key)
                                Layout.fillWidth: true
                                Layout.preferredHeight: 62
                                radius: 12
                                color: root.surface
                                border.color: on ? root.accent : root.line
                                border.width: 1
                                Column {
                                    anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3
                                    Text { text: modelData.glyph; color: root.accent; font.pixelSize: 15 }
                                    Text { text: modelData.label; color: root.textC; font.family: root.fontName; font.pixelSize: 12 }
                                }
                                Rectangle {
                                    anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                    width: 40; height: 20; radius: 10
                                    color: on ? root.accent : root.field
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: on ? parent.width - width - 3 : 3
                                        width: 14; height: 14; radius: 7
                                        color: on ? "#04140d" : root.muted
                                        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                    }
                                }
                                TapHandler { cursorShape: Qt.PointingHandCursor; onTapped: root.toggleKey(modelData.key) }
                            }
                        }
                    }

                    // workspaces
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { text: "WS"; color: root.muted; font.family: root.fontName; font.pixelSize: 11; font.letterSpacing: 2 }
                        Repeater {
                            model: root.workspaces
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool cur: root.states["ws"] === modelData.num
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 8
                                color: cur ? root.accentDim : root.field
                                border.color: cur ? root.accent : root.line
                                Text { anchors.centerIn: parent; text: modelData.num; color: cur ? root.accent : root.muted; font.family: root.fontName; font.pixelSize: 11; font.bold: cur }
                                TapHandler {
                                    cursorShape: Qt.PointingHandCursor
                                    onTapped: root.exec("hyprctl dispatch workspace name:" + modelData.num + " " + modelData.label)
                                }
                            }
                        }
                    }

                    // sliders
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "VOL"; color: root.muted; font.family: root.fontName; font.pixelSize: 11; font.letterSpacing: 2; Layout.preferredWidth: 30 }
                            Slider {
                                id: volSlider
                                Layout.fillWidth: true
                                from: 0; to: 100
                                value: root.volPct
                                onMoved: { root.volPct = value; root.exec("pamixer -v " + Math.round(value)) }
                                background: Rectangle {
                                    x: volSlider.leftPadding; y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                                    width: volSlider.availableWidth; height: 5; radius: 3; color: root.field
                                    Rectangle { width: volSlider.visualPosition * parent.width; height: parent.height; radius: 3; color: root.accent }
                                }
                                handle: Rectangle {
                                    x: volSlider.leftPadding + volSlider.visualPosition * volSlider.availableWidth - width / 2
                                    y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                                    width: 15; height: 15; radius: 8; color: root.textC
                                }
                            }
                            Text { text: Math.round(volSlider.value) + "%"; color: root.textC; font.family: root.fontName; font.pixelSize: 11; Layout.preferredWidth: 36 }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "BRI"; color: root.muted; font.family: root.fontName; font.pixelSize: 11; font.letterSpacing: 2; Layout.preferredWidth: 30 }
                            Slider {
                                id: briSlider
                                Layout.fillWidth: true
                                from: 1; to: 100
                                value: root.briPct
                                onMoved: { root.briPct = value; root.exec("brightnessctl -q s " + Math.round(value) + "%") }
                                background: Rectangle {
                                    x: briSlider.leftPadding; y: briSlider.topPadding + briSlider.availableHeight / 2 - height / 2
                                    width: briSlider.availableWidth; height: 5; radius: 3; color: root.field
                                    Rectangle { width: briSlider.visualPosition * parent.width; height: parent.height; radius: 3; color: root.accent }
                                }
                                handle: Rectangle {
                                    x: briSlider.leftPadding + briSlider.visualPosition * briSlider.availableWidth - width / 2
                                    y: briSlider.topPadding + briSlider.availableHeight / 2 - height / 2
                                    width: 15; height: 15; radius: 8; color: root.textC
                                }
                            }
                            Text { text: Math.round(briSlider.value) + "%"; color: root.textC; font.family: root.fontName; font.pixelSize: 11; Layout.preferredWidth: 36 }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: 10
                            color: root.surface
                            Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "MICROPHONE"; color: root.muted; font.family: root.fontName; font.pixelSize: 11; font.letterSpacing: 2 }
                            Rectangle {
                                anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                width: 74; height: 24; radius: 8
                                color: root.micMuted ? root.danger : root.accentDim
                                Text { anchors.centerIn: parent; text: root.micMuted ? "MUTED" : "LIVE"; color: root.textC; font.family: root.fontName; font.pixelSize: 10 }
                                TapHandler { cursorShape: Qt.PointingHandCursor; onTapped: { root.exec("pamixer --default-source -t"); root.refreshPanelValues() } }
                            }
                        }
                    }

                    // media card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        radius: 12
                        color: root.surface
                        visible: root.mediaTitle !== "" && root.mediaTitle !== "(unknown)"
                        Column {
                            anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 84
                            Text { width: parent.width; elide: Text.ElideRight; text: root.mediaTitle; color: root.textC; font.family: root.fontName; font.pixelSize: 12; font.bold: true }
                            Text { width: parent.width; elide: Text.ElideRight; text: root.mediaArtist; color: root.muted; font.family: root.fontName; font.pixelSize: 11 }
                        }
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            width: 38; height: 38; radius: 19; color: root.accentDim
                            Text { anchors.centerIn: parent; text: "▶"; color: root.accent; font.pixelSize: 14 }
                            TapHandler { cursorShape: Qt.PointingHandCursor; onTapped: { root.exec("playerctl play-pause"); root.refreshPanelValues() } }
                        }
                    }

                    // wifi picker
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "NETWORKS"; color: root.muted; font.family: root.fontName; font.pixelSize: 11; font.letterSpacing: 2 }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 64; height: 22; radius: 7
                                color: rescanMa.containsMouse ? root.accentDim : root.field
                                border.color: root.line
                                Text { anchors.centerIn: parent; text: "RESCAN"; color: root.muted; font.family: root.fontName; font.pixelSize: 9; font.letterSpacing: 1 }
                                MouseArea { id: rescanMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.exec("nmcli dev wifi rescan"); refreshLater2.restart() } }
                            }
                        }
                        Repeater {
                            model: root.wifiList
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: 8
                                color: wifiMa.containsMouse ? root.accentDim : root.surface
                                border.color: modelData.use ? root.accent : "transparent"
                                Text {
                                    anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                    text: (modelData.use ? "●  " : "   ") + modelData.ssid
                                    color: modelData.use ? root.accent : root.textC
                                    font.family: root.fontName; font.pixelSize: 11
                                }
                                Text {
                                    anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                    text: (modelData.sec !== "" ? "🔒 " : "") + modelData.sig + "%"
                                    color: root.muted; font.family: root.fontName; font.pixelSize: 10
                                }
                                MouseArea {
                                    id: wifiMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.exec("axora-wifi-connect '" + modelData.ssid.replace(/'/g, "") + "' '" + modelData.sec + "'")
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                    Text {
                        Layout.fillWidth: true; elide: Text.ElideRight
                        text: root.netLine; color: root.muted; font.family: root.fontName; font.pixelSize: 10
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: [
                                { label: "Lock", cmd: "hyprlock" },
                                { label: "Shot", cmd: "axora-screenshot region" },
                                { label: "Settings", cmd: "gnome-control-center" },
                                { label: "Power", cmd: "axora-power-menu" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 10
                                color: footMa.containsMouse ? root.accentDim : root.field
                                border.color: root.line
                                Text { anchors.centerIn: parent; text: modelData.label; color: root.textC; font.family: root.fontName; font.pixelSize: 11 }
                                MouseArea {
                                    id: footMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.exec("setsid " + modelData.cmd + " >/dev/null 2>&1 &")
                                }
                            }
                        }
                    }
                }

                // ======== TAB: NOTIFICATIONS ========
                ColumnLayout {
                    visible: root.panelTab === 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "HISTORY"; color: root.muted; font.family: root.fontName; font.pixelSize: 11; font.letterSpacing: 2 }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 92; height: 24; radius: 7
                            color: clrMa.containsMouse ? root.danger : root.field
                            border.color: root.line
                            Text { anchors.centerIn: parent; text: "CLEAR ALL"; color: root.textC; font.family: root.fontName; font.pixelSize: 9; font.letterSpacing: 1 }
                            MouseArea { id: clrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.exec("makoctl clear"); refreshLater2.restart() } }
                        }
                    }

                    // DND inline
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 10
                        color: root.surface
                        border.color: root.isOn("dnd") ? root.accent : root.line
                        Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "☾  Do Not Disturb"; color: root.textC; font.family: root.fontName; font.pixelSize: 12 }
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            width: 40; height: 20; radius: 10
                            color: root.isOn("dnd") ? root.accent : root.field
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.isOn("dnd") ? parent.width - width - 3 : 3
                                width: 14; height: 14; radius: 7
                                color: root.isOn("dnd") ? "#04140d" : root.muted
                                Behavior on x { NumberAnimation { duration: 140 } }
                            }
                        }
                        TapHandler { cursorShape: Qt.PointingHandCursor; onTapped: root.toggleKey("dnd") }
                    }

                    // history list
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        Repeater {
                            model: root.notifList
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                radius: 10
                                color: root.surface
                                border.color: root.line
                                Column {
                                    anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: parent.width - 24
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.summary; color: root.textC; font.family: root.fontName; font.pixelSize: 11; font.bold: true }
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.app; color: root.muted; font.family: root.fontName; font.pixelSize: 10 }
                                }
                            }
                        }
                        Text {
                            visible: root.notifList.length === 0
                            Layout.alignment: Qt.AlignHCenter
                            text: "no notifications"
                            color: root.muted; font.family: root.fontName; font.pixelSize: 11
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
            }

            Timer { interval: 4000; running: root.panelOpen && root.panelTab === 1; repeat: true; onTriggered: root.refreshNotifs() }
            Timer { id: refreshLater2; interval: 1600; onTriggered: { root.refreshWifi(); root.refreshNotifs(); root.stateGetRefresh() } }
        }
    }

    function stateGetRefresh() { stateGet.running = true }

    // ================= OSD =================
    PanelWindow {
        visible: root.osdMode !== ""
        anchors { bottom: true }
        margins { bottom: 72 }
        implicitWidth: 220
        implicitHeight: 54
        color: "transparent"
        exclusiveZone: -1

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: root.bg
            border.color: root.line
            Row {
                anchors.centerIn: parent
                spacing: 12
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.osdMode === "vol" ? "◉" : "☀"
                    color: root.accent; font.pixelSize: 18
                }
                Rectangle {
                    width: 120; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.field
                    Rectangle { width: root.osdValue / 100 * parent.width; height: parent.height; radius: 3; color: root.accent }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.osdValue) + "%"
                    color: root.textC; font.family: root.fontName; font.pixelSize: 12
                }
            }
        }
    }

    // ================= DOCK =================
    PanelWindow {
        anchors { bottom: true }
        margins { bottom: 4 }
        implicitWidth: dockRow.implicitWidth + 24
        implicitHeight: 56
        color: "transparent"
        exclusiveZone: -1

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: root.bg
            border.color: root.line
            border.width: 1

            Row {
                id: dockRow
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: root.dockApps
                    delegate: Item {
                        required property var modelData
                        width: 46; height: 46
                        readonly property bool running: root.states["dock_" + modelData.name] === "on"

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: tileMa.containsMouse ? root.accentDim : "transparent"

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 32
                                source: modelData.icon
                                asynchronous: true
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                width: 5; height: 5; radius: 2.5
                                color: parent.parent.running ? root.accent : "transparent"
                            }

                            MouseArea {
                                id: tileMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (parent.parent.running)
                                        root.exec("hyprctl dispatch focuswindow class:^(" + modelData.cls + ")$")
                                    else
                                        root.exec("setsid " + modelData.cmd + " >/dev/null 2>&1 &")
                                }
                            }

                            ToolTip.visible: tileMa.containsMouse
                            ToolTip.delay: 400
                            ToolTip.text: modelData.label
                        }
                    }
                }
            }
        }
    }
}
