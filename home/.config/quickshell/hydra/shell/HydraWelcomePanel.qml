// VALKYX Welcome — the reference card.
//
// Part of a pair; see the other file for the other half:
//   ValkyxWelcomeGreeter.qml — the first-run fullscreen screen
//   ValkyxWelcomePanel.qml   — the always-available reference card
//
// They are two files because a QML document may only have ONE root object:
// keeping both PanelWindows in one file is a hard "Syntax error" and the shell
// refuses to start at all.

// ═══════════════════════════════════════════════════════════════════════════
// Panel — the reference card. Always available, never greets.
// ═══════════════════════════════════════════════════════════════════════════

import Quickshell
import Quickshell.Io
import QtQuick
import "../core"
import "../core/components"

PanelWindow {
    id: welcome

    visible: ValkyxState.welcomePanelOpen
    focusable: ValkyxState.welcomePanelOpen
    aboveWindows: true
    exclusiveZone: -1
    color: "transparent"

    implicitWidth: 860
    // Height fits the content. 640 was a guess that left ~170px of empty card
    // under the shorter column, which read as a layout bug rather than padding.
    // 700, not 640: with the info block in the right column the real content is
    // ~677. The old cap cropped the last switch. Bounded so it can never grow
    // past the 768px screen.
    implicitHeight: Math.min(700, head.height + 1 + cols.height + ValkyxMetrics.xl * 2)

    property real winX: 0
    property real winY: 0

    function recenter() {
        const sw = welcome.screen ? welcome.screen.width : 1366
        const sh = welcome.screen ? welcome.screen.height : 768
        welcome.winX = Math.max(0, Math.round((sw - welcome.width) / 2))
        welcome.winY = Math.max(0, Math.round((sh - welcome.height) / 2))
    }
    onScreenChanged: recenter()
    Component.onCompleted: recenter()
    margins { top: welcome.winY; left: welcome.winX }

    property Timer focusPoll: Timer {
        interval: 120; repeat: true
        onTriggered: { welcomeBody.forceActiveFocus(); if (welcomeBody.activeFocus) stop() }
    }

    Connections {
        target: ValkyxState
        function onWelcomePanelOpenChanged() {
            if (ValkyxState.welcomePanelOpen) {
                welcome.recenter()
                welcome.focusPoll.start()
                // uptime changes while the card is closed, so read the facts on
                // every open rather than once at shell load
                ValkyxState.sysInfo.running = true
            }
        }
    }

    // ── THE GATE (one depth-1 visual child, no exceptions)
    FocusScope {
        id: welcomeBody
        anchors.fill: parent
        focus: ValkyxState.welcomePanelOpen
        enabled: ValkyxState.welcomePanelOpen
        opacity: ValkyxState.welcomePanelOpen ? 1 : 0

        Keys.onEscapePressed: { ValkyxState.welcomePanelOpen = false; event.accepted = true }

        Rectangle {
            anchors.fill: parent
            radius: ValkyxMetrics.rPanel
            color: ValkyxTheme.bgGlass
            border.width: 1
            border.color: ValkyxTheme.accent

            // Click-outside-to-close: the card shrinks to let the click through.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: ValkyxState.welcomePanelOpen = false
            }

            // ── header
            Item {
                id: head
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 68
                anchors.margins: 0

                Image {
                    id: mark
                    anchors.left: parent.left
                    anchors.leftMargin: ValkyxMetrics.xl
                    anchors.verticalCenter: parent.verticalCenter
                    source: "../data/valkyx-mark_v4_white.svg"
                    sourceSize.width: 30; sourceSize.height: 30
                    width: 30; height: 30
                }

                Text {
                    anchors.left: mark.right
                    anchors.leftMargin: ValkyxMetrics.m
                    anchors.verticalCenter: parent.verticalCenter
                    text: "VALKYX LABS"
                    color: ValkyxTheme.text
                    font.family: ValkyxTheme.fontUI
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                }

                Text {
                    anchors.left: mark.right
                    anchors.leftMargin: ValkyxMetrics.m
                    anchors.top: parent.top
                    anchors.topMargin: 26
                    text: "welcome"
                    color: ValkyxTheme.muted
                    font.family: ValkyxTheme.fontMono
                    font.pixelSize: 10
                }

                // the three tools, as buttons
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: ValkyxMetrics.xl
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ValkyxMetrics.s

                    component ToolBtn: Rectangle {
                        id: tb
                        property string label: ""
                        property string cmd: ""
                        implicitWidth: tbText.width + ValkyxMetrics.m * 2
                        implicitHeight: 26
                        radius: ValkyxMetrics.rBtn
                        color: ma.containsMouse ? ValkyxTheme.accent : "transparent"
                        border.width: 1
                        border.color: ValkyxTheme.accent
                        Text {
                            id: tbText
                            anchors.centerIn: parent
                            text: tb.label
                            color: ma.containsMouse ? ValkyxTheme.textOnAccent : ValkyxTheme.accent
                            font.family: ValkyxTheme.fontUI
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: ValkyxState.exec(tb.cmd)
                        }
                    }

                    ToolBtn { label: "Doctor"; cmd: "kitty --hold " + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-doctor" }
                    ToolBtn { label: "Update"; cmd: "kitty --hold " + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-update" }
                }
            }

            Rectangle {
                id: rule
                anchors.top: head.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: ValkyxTheme.line
            }

            // ── two columns
            Item {
                id: cols
                anchors.top: rule.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: ValkyxMetrics.xl
                height: childrenRect.height

                // LEFT: system + keybinds
                Item {
                    id: leftCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    width: (parent.width - ValkyxMetrics.xxl) / 2
                    // 22 for the section title, then one 22px row + 5px spacing
                    // per keybind. No reference to the right column's ids: a
                    // cross-column id link silently moved this title mid-list.
                    height: childrenRect.height

                    ValkyxSection { text: "keybinds"; x: 0; y: 0 }


                    Column {
                        id: kbCol
                        x: 0
                        y: 22
                        width: parent.width
                        spacing: 5

                        // real binds, read out of the live config so this card
                        // can never drift from what Hyprland actually has
                        Repeater {
                            model: ValkyxState.keybindList

                            Row {
                                required property var modelData
                                spacing: ValkyxMetrics.m
                                width: leftCol.width
                                Text {
                                    width: 132
                                    text: modelData.keys
                                    color: ValkyxTheme.accent
                                    font.family: ValkyxTheme.fontMono
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width - 132 - ValkyxMetrics.m
                                    text: modelData.what
                                    color: ValkyxTheme.text
                                    font.family: ValkyxTheme.fontUI
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                    ValkyxSection {
                        text: "language"
                        x: 0
                        y: kbCol.y + kbCol.height + ValkyxMetrics.xl
                    }

                    // language: the real xkb layout, switched through valkyx-im
                    Rectangle {
                        id: langRow
                        x: 0
                        y: kbCol.y + kbCol.height + ValkyxMetrics.xl + 22
                        width: parent.width
                        height: 40
                        radius: ValkyxMetrics.rBtn
                        color: "transparent"
                        border.width: 1
                        border.color: ValkyxTheme.line

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: ValkyxMetrics.m
                            anchors.verticalCenter: parent.verticalCenter
                            text: ValkyxState.imLayout === "ara" ? "ع" : "EN"
                            color: ValkyxTheme.accent
                            font.family: ValkyxTheme.fontUI
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: ValkyxMetrics.m + 30
                            anchors.verticalCenter: parent.verticalCenter
                            text: ValkyxState.imLayout === "ara" ? "Arabic" : "English (US)"
                            color: ValkyxTheme.text
                            font.family: ValkyxTheme.fontUI
                            font.pixelSize: 12
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: ValkyxMetrics.m
                            anchors.verticalCenter: parent.verticalCenter
                            text: "switch  ⇧"
                            color: ValkyxTheme.muted
                            font.family: ValkyxTheme.fontMono
                            font.pixelSize: 10
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ValkyxState.imToggle.running = true
                        }
                    }

                }

                // RIGHT: appearance + toggles
                Item {
                    id: rightCol
                    anchors.top: parent.top
                    anchors.right: parent.right
                    width: (parent.width - ValkyxMetrics.xxl) / 2
                    // childrenRect is the real bottom of the tallest child, so the
                    // column tracks the switch list without a hardcoded row height.
                    height: childrenRect.height
                    ValkyxSection { text: "this machine"; x: 0; y: 0 }

                    Column {
                        id: infoCol
                        x: 0
                        y: 22
                        width: parent.width
                        spacing: 5

                        component KV: Row {
                            id: kv
                            property string k: ""
                            property string v: ""
                            spacing: ValkyxMetrics.m
                            Text {
                                width: 96
                                text: kv.k
                                color: ValkyxTheme.muted
                                font.family: ValkyxTheme.fontMono
                                font.pixelSize: 11
                            }
                            Text {
                                text: kv.v
                                color: ValkyxTheme.text
                                font.family: ValkyxTheme.fontMono
                                font.pixelSize: 11
                            }
                        }

                        KV { k: "user";   v: ValkyxState.userName }
                        KV { k: "host";   v: ValkyxState.hostName }
                        KV { k: "kernel"; v: ValkyxState.kernelName }
                        KV { k: "wm";     v: "Hyprland " + ValkyxState.hyprVersion }
                        KV { k: "shell";  v: "valkyx shell (quickshell)" }
                        KV { k: "uptime"; v: ValkyxState.uptimeText }
                    }

                    ValkyxSection { text: "appearance"; x: 0; y: infoCol.y + infoCol.height + ValkyxMetrics.xl }

                    // theme swatches — the pickers iterate themeNames (strings),
                    // never ValkyxTheme.themes (a JS array-of-objects, which this
                    // Qt build renders as nothing at all)
                    Flow {
                        id: swatches
                        x: 0
                        y: infoCol.y + infoCol.height + ValkyxMetrics.xl + 22
                        width: parent.width
                        spacing: ValkyxMetrics.s

                        Repeater {
                            model: ValkyxTheme.themeNames

                            Rectangle {
                                required property string modelData
                                required property int index
                                width: 96; height: 30
                                radius: ValkyxMetrics.rBtn
                                color: "transparent"
                                border.width: ValkyxState.themedName === modelData ? 2 : 1
                                border.color: ValkyxTheme.accent

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: ValkyxMetrics.m
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 12; height: 12
                                    radius: 6
                                    color: ValkyxTheme.themeByName(modelData).accent
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: ValkyxMetrics.m + 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    color: ValkyxTheme.text
                                    font.family: ValkyxTheme.fontUI
                                    font.pixelSize: 11
                                    font.weight: ValkyxState.themedName === modelData ? Font.DemiBold : Font.Normal
                                }
                                // selection ring in accent = the active indicator,
                                // per the accent rules
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.rightMargin: ValkyxMetrics.s
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6; height: 6
                                    radius: 3
                                    visible: ValkyxState.themedName === modelData
                                    color: ValkyxTheme.accent
                                }
                                MouseArea {
                                    id: swMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: ValkyxState.applyTheme(modelData)
                                }
                            }
                        }
                    }


                    ValkyxSection {
                        text: "what's on"
                        x: 0
                        y: swatches.y + swatches.height + ValkyxMetrics.xl
                    }

                    Column {
                        x: 0
                        y: swatches.y + swatches.height + ValkyxMetrics.xl + 22
                        width: parent.width
                        spacing: ValkyxMetrics.s

                        // every switch drives a REAL setting. No decorative
                        // toggles: a switch that does nothing is a lie.
                        component Row2: Item {
                            id: r2
                            property string label: ""
                            property bool on: false
                            property string note: ""
                            // Emitted by the switch; each row decides what it means.
                            // (An inline component's functions cannot be
                            // overridden per-instance — a signal can.)
                            signal toggled()
                            width: swatches.width
                            height: 26

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: r2.label
                                color: ValkyxTheme.text
                                font.family: ValkyxTheme.fontUI
                                font.pixelSize: 12
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 190
                                anchors.verticalCenter: parent.verticalCenter
                                text: r2.note
                                color: ValkyxTheme.muted
                                font.family: ValkyxTheme.fontMono
                                font.pixelSize: 10
                            }

                            // switch: solid accent when on, per the accent rules
                            Rectangle {
                                id: sw
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 38; height: 20
                                radius: 10
                                color: "transparent"
                                border.width: 1
                                border.color: r2.on ? ValkyxTheme.accent : ValkyxTheme.line

                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: r2.on ? ValkyxTheme.accent : ValkyxTheme.muted
                                    x: r2.on ? parent.width - width - 3 : 3
                                    y: (parent.height - height) / 2
                                    Behavior on x { NumberAnimation { duration: ValkyxMotion.fast; easing.type: ValkyxMotion.curveOut } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: r2.toggled()
                                }
                            }
                        }

                        // Every switch here is wired to something real: click it and the
                        // machine actually changes. Blur and DND act now; Caffeine
                        // acts on idle.
                        Row2 {
                            label: "Blur"
                            on: ValkyxState.blurEnabled
                            note: "translucency"
                            onToggled: ValkyxState.toggleBlur()
                        }
                        Row2 {
                            label: "Greet on startup"
                            on: ValkyxState.greetingEnabled
                            note: "hello at login"
                            // Assigns the STATE, never this row's own `on`: writing
                            // to `on` would break the binding above and leave the
                            // switch painted the wrong way after the next reload.
                            // onGreetingEnabledChanged saves it.
                            onToggled: ValkyxState.greetingEnabled = !ValkyxState.greetingEnabled
                        }
                        Row2 {
                            label: "Do not disturb"
                            on: ValkyxState.isOn("dnd")
                            note: "notifications"
                            onToggled: ValkyxState.toggleKey("dnd")
                        }
                        Row2 {
                            label: "Caffeine"
                            on: !ValkyxState.isOn("caffeine")
                            note: "idle lock off"
                            onToggled: ValkyxState.toggleKey("caffeine")
                        }
                    }
                }
            }
        }
    }
}
