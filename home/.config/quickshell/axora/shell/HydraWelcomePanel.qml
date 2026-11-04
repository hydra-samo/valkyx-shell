// AXORA Welcome — the reference card.
//
// Part of a pair; see the other file for the other half:
//   AxoraWelcomeGreeter.qml — the first-run fullscreen screen
//   AxoraWelcomePanel.qml   — the always-available reference card
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

    visible: AxoraState.welcomePanelOpen
    focusable: AxoraState.welcomePanelOpen
    aboveWindows: true
    exclusiveZone: -1
    color: "transparent"

    implicitWidth: 860
    // Height fits the content. 640 was a guess that left ~170px of empty card
    // under the shorter column, which read as a layout bug rather than padding.
    // 700, not 640: with the info block in the right column the real content is
    // ~677. The old cap cropped the last switch. Bounded so it can never grow
    // past the 768px screen.
    implicitHeight: Math.min(700, head.height + 1 + cols.height + AxoraMetrics.xl * 2)

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
        target: AxoraState
        function onWelcomePanelOpenChanged() {
            if (AxoraState.welcomePanelOpen) {
                welcome.recenter()
                welcome.focusPoll.start()
                // uptime changes while the card is closed, so read the facts on
                // every open rather than once at shell load
                AxoraState.sysInfo.running = true
            }
        }
    }

    // ── THE GATE (one depth-1 visual child, no exceptions)
    FocusScope {
        id: welcomeBody
        anchors.fill: parent
        focus: AxoraState.welcomePanelOpen
        enabled: AxoraState.welcomePanelOpen
        opacity: AxoraState.welcomePanelOpen ? 1 : 0

        Keys.onEscapePressed: { AxoraState.welcomePanelOpen = false; event.accepted = true }

        Rectangle {
            anchors.fill: parent
            radius: AxoraMetrics.rPanel
            color: AxoraTheme.bgGlass
            border.width: 1
            border.color: AxoraTheme.accent

            // Click-outside-to-close: the card shrinks to let the click through.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: AxoraState.welcomePanelOpen = false
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
                    anchors.leftMargin: AxoraMetrics.xl
                    anchors.verticalCenter: parent.verticalCenter
                    source: "../data/axora-mark_v4_white.svg"
                    sourceSize.width: 30; sourceSize.height: 30
                    width: 30; height: 30
                }

                Text {
                    anchors.left: mark.right
                    anchors.leftMargin: AxoraMetrics.m
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AXORA LABS"
                    color: AxoraTheme.text
                    font.family: AxoraTheme.fontUI
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                }

                Text {
                    anchors.left: mark.right
                    anchors.leftMargin: AxoraMetrics.m
                    anchors.top: parent.top
                    anchors.topMargin: 26
                    text: "welcome"
                    color: AxoraTheme.muted
                    font.family: AxoraTheme.fontMono
                    font.pixelSize: 10
                }

                // the three tools, as buttons
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: AxoraMetrics.xl
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: AxoraMetrics.s

                    component ToolBtn: Rectangle {
                        id: tb
                        property string label: ""
                        property string cmd: ""
                        implicitWidth: tbText.width + AxoraMetrics.m * 2
                        implicitHeight: 26
                        radius: AxoraMetrics.rBtn
                        color: ma.containsMouse ? AxoraTheme.accent : "transparent"
                        border.width: 1
                        border.color: AxoraTheme.accent
                        Text {
                            id: tbText
                            anchors.centerIn: parent
                            text: tb.label
                            color: ma.containsMouse ? AxoraTheme.textOnAccent : AxoraTheme.accent
                            font.family: AxoraTheme.fontUI
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: AxoraState.exec(tb.cmd)
                        }
                    }

                    ToolBtn { label: "Doctor"; cmd: "kitty --hold " + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/axora-doctor" }
                    ToolBtn { label: "Update"; cmd: "kitty --hold " + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/axora-update" }
                }
            }

            Rectangle {
                id: rule
                anchors.top: head.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: AxoraTheme.line
            }

            // ── two columns
            Item {
                id: cols
                anchors.top: rule.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: AxoraMetrics.xl
                height: childrenRect.height

                // LEFT: system + keybinds
                Item {
                    id: leftCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    width: (parent.width - AxoraMetrics.xxl) / 2
                    // 22 for the section title, then one 22px row + 5px spacing
                    // per keybind. No reference to the right column's ids: a
                    // cross-column id link silently moved this title mid-list.
                    height: childrenRect.height

                    AxoraSection { text: "keybinds"; x: 0; y: 0 }


                    Column {
                        id: kbCol
                        x: 0
                        y: 22
                        width: parent.width
                        spacing: 5

                        // real binds, read out of the live config so this card
                        // can never drift from what Hyprland actually has
                        Repeater {
                            model: AxoraState.keybindList

                            Row {
                                required property var modelData
                                spacing: AxoraMetrics.m
                                width: leftCol.width
                                Text {
                                    width: 132
                                    text: modelData.keys
                                    color: AxoraTheme.accent
                                    font.family: AxoraTheme.fontMono
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width - 132 - AxoraMetrics.m
                                    text: modelData.what
                                    color: AxoraTheme.text
                                    font.family: AxoraTheme.fontUI
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                    AxoraSection {
                        text: "language"
                        x: 0
                        y: kbCol.y + kbCol.height + AxoraMetrics.xl
                    }

                    // language: the real xkb layout, switched through axora-im
                    Rectangle {
                        id: langRow
                        x: 0
                        y: kbCol.y + kbCol.height + AxoraMetrics.xl + 22
                        width: parent.width
                        height: 40
                        radius: AxoraMetrics.rBtn
                        color: "transparent"
                        border.width: 1
                        border.color: AxoraTheme.line

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: AxoraMetrics.m
                            anchors.verticalCenter: parent.verticalCenter
                            text: AxoraState.imLayout === "ara" ? "ع" : "EN"
                            color: AxoraTheme.accent
                            font.family: AxoraTheme.fontUI
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: AxoraMetrics.m + 30
                            anchors.verticalCenter: parent.verticalCenter
                            text: AxoraState.imLayout === "ara" ? "Arabic" : "English (US)"
                            color: AxoraTheme.text
                            font.family: AxoraTheme.fontUI
                            font.pixelSize: 12
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: AxoraMetrics.m
                            anchors.verticalCenter: parent.verticalCenter
                            text: "switch  ⇧"
                            color: AxoraTheme.muted
                            font.family: AxoraTheme.fontMono
                            font.pixelSize: 10
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AxoraState.imToggle.running = true
                        }
                    }

                }

                // RIGHT: appearance + toggles
                Item {
                    id: rightCol
                    anchors.top: parent.top
                    anchors.right: parent.right
                    width: (parent.width - AxoraMetrics.xxl) / 2
                    // childrenRect is the real bottom of the tallest child, so the
                    // column tracks the switch list without a hardcoded row height.
                    height: childrenRect.height
                    AxoraSection { text: "this machine"; x: 0; y: 0 }

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
                            spacing: AxoraMetrics.m
                            Text {
                                width: 96
                                text: kv.k
                                color: AxoraTheme.muted
                                font.family: AxoraTheme.fontMono
                                font.pixelSize: 11
                            }
                            Text {
                                text: kv.v
                                color: AxoraTheme.text
                                font.family: AxoraTheme.fontMono
                                font.pixelSize: 11
                            }
                        }

                        KV { k: "user";   v: AxoraState.userName }
                        KV { k: "host";   v: AxoraState.hostName }
                        KV { k: "kernel"; v: AxoraState.kernelName }
                        KV { k: "wm";     v: "Hyprland " + AxoraState.hyprVersion }
                        KV { k: "shell";  v: "axora shell (quickshell)" }
                        KV { k: "uptime"; v: AxoraState.uptimeText }
                    }

                    AxoraSection { text: "appearance"; x: 0; y: infoCol.y + infoCol.height + AxoraMetrics.xl }

                    // theme swatches — the pickers iterate themeNames (strings),
                    // never AxoraTheme.themes (a JS array-of-objects, which this
                    // Qt build renders as nothing at all)
                    Flow {
                        id: swatches
                        x: 0
                        y: infoCol.y + infoCol.height + AxoraMetrics.xl + 22
                        width: parent.width
                        spacing: AxoraMetrics.s

                        Repeater {
                            model: AxoraTheme.themeNames

                            Rectangle {
                                required property string modelData
                                required property int index
                                width: 96; height: 30
                                radius: AxoraMetrics.rBtn
                                color: "transparent"
                                border.width: AxoraState.themedName === modelData ? 2 : 1
                                border.color: AxoraTheme.accent

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: AxoraMetrics.m
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 12; height: 12
                                    radius: 6
                                    color: AxoraTheme.themeByName(modelData).accent
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: AxoraMetrics.m + 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    color: AxoraTheme.text
                                    font.family: AxoraTheme.fontUI
                                    font.pixelSize: 11
                                    font.weight: AxoraState.themedName === modelData ? Font.DemiBold : Font.Normal
                                }
                                // selection ring in accent = the active indicator,
                                // per the accent rules
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.rightMargin: AxoraMetrics.s
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6; height: 6
                                    radius: 3
                                    visible: AxoraState.themedName === modelData
                                    color: AxoraTheme.accent
                                }
                                MouseArea {
                                    id: swMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: AxoraState.applyTheme(modelData)
                                }
                            }
                        }
                    }


                    AxoraSection {
                        text: "what's on"
                        x: 0
                        y: swatches.y + swatches.height + AxoraMetrics.xl
                    }

                    Column {
                        x: 0
                        y: swatches.y + swatches.height + AxoraMetrics.xl + 22
                        width: parent.width
                        spacing: AxoraMetrics.s

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
                                color: AxoraTheme.text
                                font.family: AxoraTheme.fontUI
                                font.pixelSize: 12
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 190
                                anchors.verticalCenter: parent.verticalCenter
                                text: r2.note
                                color: AxoraTheme.muted
                                font.family: AxoraTheme.fontMono
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
                                border.color: r2.on ? AxoraTheme.accent : AxoraTheme.line

                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: r2.on ? AxoraTheme.accent : AxoraTheme.muted
                                    x: r2.on ? parent.width - width - 3 : 3
                                    y: (parent.height - height) / 2
                                    Behavior on x { NumberAnimation { duration: AxoraMotion.fast; easing.type: AxoraMotion.curveOut } }
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
                            on: AxoraState.blurEnabled
                            note: "translucency"
                            onToggled: AxoraState.toggleBlur()
                        }
                        Row2 {
                            label: "Greet on startup"
                            on: AxoraState.greetingEnabled
                            note: "hello at login"
                            // Assigns the STATE, never this row's own `on`: writing
                            // to `on` would break the binding above and leave the
                            // switch painted the wrong way after the next reload.
                            // onGreetingEnabledChanged saves it.
                            onToggled: AxoraState.greetingEnabled = !AxoraState.greetingEnabled
                        }
                        Row2 {
                            label: "Do not disturb"
                            on: AxoraState.isOn("dnd")
                            note: "notifications"
                            onToggled: AxoraState.toggleKey("dnd")
                        }
                        Row2 {
                            label: "Caffeine"
                            on: !AxoraState.isOn("caffeine")
                            note: "idle lock off"
                            onToggled: AxoraState.toggleKey("caffeine")
                        }
                    }
                }
            }
        }
    }
}
