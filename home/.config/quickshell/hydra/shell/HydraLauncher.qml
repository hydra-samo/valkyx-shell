// VALKYX Launcher — floating command surface, shell-native.
// Replaces fuzzel: same rounded-rectangle panel, keyboard-native search,
// app icons, and full accent reactivity through ValkyxTheme.
// Data + launch logic live in valkyx-launch (--list-json / --run).
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../core"

PanelWindow {
    id: launcher
    visible: ValkyxState.launcherOpen
    focusable: true
    aboveWindows: true
    exclusiveZone: -1
    color: "transparent"

    // Centered horizontally, held in the upper third — the same footprint the
    // old fuzzel panel used, as a rounded rectangle (rPanel radius).
    property real winX: 0
    property real winY: 0
    property real panelW: 0
    function gear() {
        const sw = launcher.screen ? launcher.screen.width : 1366
        const sh = launcher.screen ? launcher.screen.height : 768
        panelW = Math.round(sw * 0.38)
        launcher.winX = Math.max(0, Math.round((sw - panelW) / 2))
        launcher.winY = Math.max(0, Math.round(sh * 0.22))
    }
    onScreenChanged: gear()
    onVisibleChanged: { if (visible) { gear(); open(); focusPoll.start() } else { ValkyxState.launcherOpen = false; focusPoll.stop() } }
    // Re-assert keyboard focus on a retry timer: layershell re-maps can land AFTER
    // Qt.callLater fires (esp. right after boot), so a one-shot grab is dropped and
    // the launcher goes keyboard-dead until a click. Poll while visible, stop once
    // focus actually sticks.
    property Timer focusPoll: Timer {
        interval: 120; repeat: true
        onTriggered: {
            input.forceActiveFocus()
            if (input.activeFocus) stop()
        }
    }
    onSectionChanged: if (visible) open()   // section swap while open → re-pull data
    // accent switch while open → re-pull so themed glyph icons follow
    Connections {
        target: ValkyxState
        function onThemeNameChanged() { if (visible) open() }
    }
    margins { left: launcher.winX; top: launcher.winY }
    implicitWidth: panelW
    implicitHeight: 460

    // ── data: JSON from valkyx-launch --list-json [theme] [section] ──
    property var allEntries: []
    property string query: ""
    property int current: -1
    property bool dataReady: false
    // active section: "" = everything, else kind filter from the IPC open call
    property string section: ""
    property string sectionTitle: ""
    ListModel { id: listModel }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text)
                    launcher.allEntries = arr
                    launcher.dataReady = true
                    launcher.refresh()
                } catch (e) {
                    console.log("[launcher] bad JSON: " + e)
                }
            }
        }
    }

    function flatten() {
        if (!dataReady) return []
        if (!query) return allEntries
        const q = query.toLowerCase()
        const out = []
        for (const e of allEntries) {
            if (e.name.toLowerCase().indexOf(q) >= 0) out.push(e)
        }
        return out
    }
    function refresh() {
        current = -1
        listModel.clear()
        for (const e of flatten()) listModel.append(e)
        if (listModel.count > 0) current = 0
    }
    function open() {
        query = ""
        input.text = ""
        current = -1
        dataReady = false
        listModel.clear()
        listProc.command = ["valkyx-launch", "--list-json", ValkyxState.themedName, section]
        listProc.running = true
        input.forceActiveFocus()
    }
    function openSection(s) {
        section = s
        sectionTitle = s === "game" ? "GAMES" : s === "clip" ? "CLIPBOARD" : s === "dir" ? "PROJECTS" : s === "emoji" ? "EMOJI" : ""
        if (ValkyxState.launcherOpen) open()
        else ValkyxState.launcherOpen = true
    }
    function close() {
        ValkyxState.launcherOpen = false
    }
    function activate() {
        if (current < 0 || current >= listModel.count) return
        const e = listModel.get(current)
        ValkyxState.exec("valkyx-launch --run \"" + e.run.replace(/"/g, '\\"') + "\"")
        close()
    }
    // Debug: test if close alone works
    function testClose() {
        close()
    }
    function move(d) {
        if (listModel.count === 0) return
        current = (current + d + listModel.count) % listModel.count
    }
    // TEST HOOK (valkyx-ui-test): the ACTUAL highlighted row, driven by
    // lv.currentIndex — NOT launcher.current. This is what catches binding-
    // destruction: if a handler assigned to lv.currentIndex and killed the
    // `currentIndex: launcher.current` binding, launcher.current still moves
    // but the highlight (lv.currentIndex) stays frozen. Reading lv.currentIndex
    // here exposes that divergence deterministically.
    function selectedName(): string {
        const idx = lv.currentIndex
        if (idx < 0 || idx >= listModel.count) return "none"
        return listModel.get(idx).name
    }

// open morph: scale 0.96→1 + fade 0→1, anchored to the top (dropdown feel).
    FocusScope {
        id: launcherBody
        anchors.fill: parent
        focus: true
        transformOrigin: Item.Top
        scale: 1
        opacity: 1
        Behavior on scale { NumberAnimation { duration: ValkyxMotion.base; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: ValkyxMotion.base; easing.type: Easing.OutCubic } }
        Keys.onEscapePressed: close()
        Keys.onUpPressed: { launcher.move(-1); event.accepted = true }
        Keys.onDownPressed: { launcher.move(1); event.accepted = true }
        Keys.onReturnPressed: { launcher.activate(); event.accepted = true }
        Keys.onEnterPressed: { launcher.activate(); event.accepted = true }
        onVisibleChanged: {
            if (visible) {
                scale = 0.96
                opacity = 0
                Qt.callLater(function() {
                    scale = 1
                    opacity = 1
                    launcherBody.forceActiveFocus()
                })
            } else {
                scale = 1
                opacity = 1
            }
        }

        Rectangle {
            id: launcherBg
            anchors.fill: parent
            radius: ValkyxMetrics.rPanel
            color: ValkyxMaterials.panelGlass
            border.color: ValkyxMaterials.border
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ValkyxMetrics.m
            spacing: ValkyxMetrics.s

            // ── search field ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: ValkyxMetrics.rBtn
                color: ValkyxMaterials.surface2
                border.color: input.activeFocus ? ValkyxTheme.accent : ValkyxMaterials.borderFaint
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    spacing: 10
                    Text {
                        text: "\uDB80\uDF49"
                        color: input.activeFocus ? ValkyxTheme.accent : ValkyxTheme.muted
                        font.family: ValkyxTheme.fontMono
                        font.pixelSize: Math.round(14 * ValkyxState.fontScale)
                    }
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: ValkyxTheme.text
                        font.family: ValkyxTheme.fontUI
                        font.pixelSize: Math.round(15 * ValkyxState.fontScale)
                        selectByMouse: true
                        // cursor only blinks while actually typing — no idle flicker
                        cursorVisible: text.length > 0
                        onTextChanged: { launcher.query = text; launcher.refresh() }
                        Keys.onEscapePressed: launcher.close()
                        Keys.onUpPressed: { launcher.move(-1); event.accepted = true }
                        Keys.onDownPressed: { launcher.move(1); event.accepted = true }
                        Keys.onReturnPressed: { launcher.activate(); event.accepted = true }
                        Keys.onEnterPressed: { launcher.activate(); event.accepted = true }
                    }
                    Text {
                        text: listModel.count + " results"
                        color: ValkyxTheme.muted
                        font.family: ValkyxTheme.fontUI
                        font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                    }
                }
            }

            // ── section title (games / clipboard / projects pickers) ──
            RowLayout {
                Layout.fillWidth: true
                visible: sectionTitle !== ""
                spacing: ValkyxMetrics.s
                Text {
                    text: sectionTitle
                    color: ValkyxTheme.accent
                    font.family: ValkyxTheme.fontMono
                    font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: ValkyxTheme.tint(ValkyxTheme.accent, "44")
                }
            }

            // ── results list ──
            ListView {
                id: lv
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: listModel
                clip: true
                spacing: 2
                // currentIndex is BOUND to launcher.current. Do NOT assign to it
                // in onCountChanged — that would destroy the binding and freeze
                // the highlight on row 0 (arrow navigation would appear dead).
                // refresh() already resets launcher.current to 0 after repopulating.
                currentIndex: launcher.current

                delegate: Item {
                    required property int index
                    required property string kind
                    required property string name
                    required property string icon
                    required property string run
                    width: lv.width
                    height: 44

                    Rectangle {
                        anchors.fill: parent
                        radius: ValkyxMetrics.rBtn
                        color: lv.currentIndex === index ? ValkyxMaterials.surface2 : "transparent"
                        border.color: lv.currentIndex === index ? ValkyxMaterials.borderFaint : "transparent"
                        border.width: 1

                        // left-edge accent bar on the selected row (illogical-impulse pattern)
                        Rectangle {
                            visible: lv.currentIndex === index
                            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                            width: 3
                            color: ValkyxTheme.accent
                            radius: 2
                        }

                        // app icon
                        Image {
                            anchors.left: parent.left
                            anchors.leftMargin: ValkyxMetrics.m
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26; height: 26
                            source: icon
                            fillMode: Image.PreserveAspectFit
                            sourceSize { width: 26; height: 26 }
                        }

                        // name
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: ValkyxMetrics.l + 40
                            anchors.verticalCenter: parent.verticalCenter
                            text: name
                            color: lv.currentIndex === index ? ValkyxTheme.text : ValkyxTheme.muted
                            font.family: ValkyxTheme.fontUI
                            font.pixelSize: Math.round(13 * ValkyxState.fontScale)
                            elide: Text.ElideRight
                            width: parent.width - ValkyxMetrics.l - 40 - ValkyxMetrics.l
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { launcher.current = index; launcher.activate() }
                        }
                    }
                }

                // empty state
                Text {
                    anchors.centerIn: parent
                    visible: listModel.count === 0
                    text: launcher.query ? "no results" : "loading…"
                    color: ValkyxTheme.muted
                    font.family: ValkyxTheme.fontUI
                    font.pixelSize: Math.round(13 * ValkyxState.fontScale)
                }
            }

            // ── footer hints ──
            RowLayout {
                Layout.fillWidth: true
                spacing: ValkyxMetrics.l
                Text { text: "↵ launch"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale) }
                Text { text: "↑↓ navigate"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale) }
                Text { text: "esc close"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale) }
                Item { Layout.fillWidth: true }
                Text {
                    text: "valkyx › "
                    color: ValkyxTheme.accent
                    font.family: ValkyxTheme.fontMono
                    font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                }
            }
        }
    }
}