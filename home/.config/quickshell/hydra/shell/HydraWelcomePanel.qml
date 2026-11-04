// HYDRA Welcome — the reference card.
//
// Part of a pair; see the other file for the other half:
//   HydraWelcomeGreeter.qml — the first-run fullscreen screen
//   HydraWelcomePanel.qml   — the always-available reference card
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

    visible: HydraState.welcomePanelOpen
    focusable: HydraState.welcomePanelOpen
    aboveWindows: true
    exclusiveZone: -1
    color: "transparent"

    implicitWidth: 860
    // Height fits the content. 640 was a guess that left ~170px of empty card
    // under the shorter column, which read as a layout bug rather than padding.
    // 700, not 640: with the info block in the right column the real content is
    // ~677. The old cap cropped the last switch. Bounded so it can never grow
    // past the 768px screen.
    implicitHeight: Math.min(700, head.height + 1 + cols.height + HydraMetrics.xl * 2)

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
        target: HydraState
        function onWelcomePanelOpenChanged() {
            if (HydraState.welcomePanelOpen) {
                welcome.recenter()
                welcome.focusPoll.start()
                // uptime changes while the card is closed, so read the facts on
                // every open rather than once at shell load
                HydraState.sysInfo.running = true
            }
        }
    }

    // ── THE GATE (one depth-1 visual child, no exceptions)
    FocusScope {
        id: welcomeBody
        anchors.fill: parent
        focus: HydraState.welcomePanelOpen
        enabled: HydraState.welcomePanelOpen
        opacity: HydraState.welcomePanelOpen ? 1 : 0

        Keys.onEscapePressed: { HydraState.welcomePanelOpen = false; event.accepted = true }

        Rectangle {
            anchors.fill: parent
            radius: HydraMetrics.rPanel
            color: HydraTheme.bgGlass
            border.width: 1
            border.color: HydraTheme.accent

            // Click-outside-to-close: the card shrinks to let the click through.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: HydraState.welcomePanelOpen = false
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
                    anchors.leftMargin: HydraMetrics.xl
                    anchors.verticalCenter: parent.verticalCenter
                    source: "../data/hydra-mark_v4_white.svg"
                    sourceSize.width: 30; sourceSize.height: 30
                    width: 30; height: 30
                }

                Text {
                    anchors.left: mark.right
                    anchors.leftMargin: HydraMetrics.m
                    anchors.verticalCenter: parent.verticalCenter
                    text: "HYDRA SAMO LABS"
                    color: HydraTheme.text
                    font.family: HydraTheme.fontUI
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                }

                Text {
                    anchors.left: mark.right
                    anchors.leftMargin: HydraMetrics.m
                    anchors.top: parent.top
                    anchors.topMargin: 26
                    text: "welcome"
                    color: HydraTheme.muted
                    font.family: HydraTheme.fontMono
                    font.pixelSize: 10
                }

                // the three tools, as buttons
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: HydraMetrics.xl
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: HydraMetrics.s

                    component ToolBtn: Rectangle {
                        id: tb
                        property string label: ""
                        property string cmd: ""
                        implicitWidth: tbText.width + HydraMetrics.m * 2
                        implicitHeight: 26
                        radius: HydraMetrics.rBtn
                        color: ma.containsMouse ? HydraTheme.accent : "transparent"
                        border.width: 1
                        border.color: HydraTheme.accent
                        Text {
                            id: tbText
                            anchors.centerIn: parent
                            text: tb.label
                            color: ma.containsMouse ? HydraTheme.textOnAccent : HydraTheme.accent
                            font.family: HydraTheme.fontUI
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: HydraState.exec(tb.cmd)
                        }
                    }

                    ToolBtn { label: "Doctor"; cmd: "kitty --hold " + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/hydra-doctor" }
                    ToolBtn { label: "Update"; cmd: "kitty --hold " + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/hydra-update" }
                }
            }

            Rectangle {
                id: rule
                anchors.top: head.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: HydraTheme.line
            }

            // ── two columns
            Item {
                id: cols
                anchors.top: rule.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: HydraMetrics.xl
                height: childrenRect.height

                // LEFT: system + keybinds
                Item {
                    id: leftCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    width: (parent.width - HydraMetrics.xxl) / 2
                    // 22 for the section title, then one 22px row + 5px spacing
                    // per keybind. No reference to the right column's ids: a
                    // cross-column id link silently moved this title mid-list.
                    height: childrenRect.height

                    HydraSection { text: "keybinds"; x: 0; y: 0 }


                    Column {
                        id: kbCol
                        x: 0
                        y: 22
                        width: parent.width
                        spacing: 5

                        // real binds, read out of the live config so this card
                        // can never drift from what Hyprland actually has
                        Repeater {
                            model: HydraState.keybindList

                            Row {
                                required property var modelData
                                spacing: HydraMetrics.m
                                width: leftCol.width
                                Text {
                                    width: 132
                                    text: modelData.keys
                                    color: HydraTheme.accent
                                    font.family: HydraTheme.fontMono
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width - 132 - HydraMetrics.m
                                    text: modelData.what
                                    color: HydraTheme.text
                                    font.family: HydraTheme.fontUI
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                    HydraSection {
                        text: "language"
                        x: 0
                        y: kbCol.y + kbCol.height + HydraMetrics.xl
                    }

                    // language: the real xkb layout, switched through hydra-im
                    Rectangle {
                        id: langRow
                        x: 0
                        y: kbCol.y + kbCol.height + HydraMetrics.xl + 22
                        width: parent.width
                        height: 40
                        radius: HydraMetrics.rBtn
                        color: "transparent"
                        border.width: 1
                        border.color: HydraTheme.line

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: HydraMetrics.m
                            anchors.verticalCenter: parent.verticalCenter
                            text: HydraState.imLayout === "ara" ? "ع" : "EN"
                            color: HydraTheme.accent
                            font.family: HydraTheme.fontUI
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: HydraMetrics.m + 30
                            anchors.verticalCenter: parent.verticalCenter
                            text: HydraState.imLayout === "ara" ? "Arabic" : "English (US)"
                            color: HydraTheme.text
                            font.family: HydraTheme.fontUI
                            font.pixelSize: 12
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: HydraMetrics.m
                            anchors.verticalCenter: parent.verticalCenter
                            text: "switch  ⇧"
                            color: HydraTheme.muted
                            font.family: HydraTheme.fontMono
                            font.pixelSize: 10
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: HydraState.imToggle.running = true
                        }
                    }

                }

                // RIGHT: appearance + toggles
                Item {
                    id: rightCol
                    anchors.top: parent.top
                    anchors.right: parent.right
                    width: (parent.width - HydraMetrics.xxl) / 2
                    // childrenRect is the real bottom of the tallest child, so the
                    // column tracks the switch list without a hardcoded row height.
                    height: childrenRect.height
                    HydraSection { text: "this machine"; x: 0; y: 0 }

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
                            spacing: HydraMetrics.m
                            Text {
                                width: 96
                                text: kv.k
                                color: HydraTheme.muted
                                font.family: HydraTheme.fontMono
                                font.pixelSize: 11
                            }
                            Text {
                                text: kv.v
                                color: HydraTheme.text
                                font.family: HydraTheme.fontMono
                                font.pixelSize: 11
                            }
                        }

                        KV { k: "user";   v: HydraState.userName }
                        KV { k: "host";   v: HydraState.hostName }
                        KV { k: "kernel"; v: HydraState.kernelName }
                        KV { k: "wm";     v: "Hyprland " + HydraState.hyprVersion }
                        KV { k: "shell";  v: "hydra shell (quickshell)" }
                        KV { k: "uptime"; v: HydraState.uptimeText }
                    }

                    HydraSection { text: "appearance"; x: 0; y: infoCol.y + infoCol.height + HydraMetrics.xl }

                    // theme swatches — the pickers iterate themeNames (strings),
                    // never HydraTheme.themes (a JS array-of-objects, which this
                    // Qt build renders as nothing at all)
                    Flow {
                        id: swatches
                        x: 0
                        y: infoCol.y + infoCol.height + HydraMetrics.xl + 22
                        width: parent.width
                        spacing: HydraMetrics.s

                        Repeater {
                            model: HydraTheme.themeNames

                            Rectangle {
                                required property string modelData
                                required property int index
                                width: 96; height: 30
                                radius: HydraMetrics.rBtn
                                color: "transparent"
                                border.width: HydraState.themedName === modelData ? 2 : 1
                                border.color: HydraTheme.accent

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: HydraMetrics.m
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 12; height: 12
                                    radius: 6
                                    color: HydraTheme.themeByName(modelData).accent
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: HydraMetrics.m + 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    color: HydraTheme.text
                                    font.family: HydraTheme.fontUI
                                    font.pixelSize: 11
                                    font.weight: HydraState.themedName === modelData ? Font.DemiBold : Font.Normal
                                }
                                // selection ring in accent = the active indicator,
                                // per the accent rules
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.rightMargin: HydraMetrics.s
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6; height: 6
                                    radius: 3
                                    visible: HydraState.themedName === modelData
                                    color: HydraTheme.accent
                                }
                                MouseArea {
                                    id: swMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: HydraState.applyTheme(modelData)
                                }
                            }
                        }
                    }


                    HydraSection {
                        text: "what's on"
                        x: 0
                        y: swatches.y + swatches.height + HydraMetrics.xl
                    }

                    Column {
                        x: 0
                        y: swatches.y + swatches.height + HydraMetrics.xl + 22
                        width: parent.width
                        spacing: HydraMetrics.s

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
                                color: HydraTheme.text
                                font.family: HydraTheme.fontUI
                                font.pixelSize: 12
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 190
                                anchors.verticalCenter: parent.verticalCenter
                                text: r2.note
                                color: HydraTheme.muted
                                font.family: HydraTheme.fontMono
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
                                border.color: r2.on ? HydraTheme.accent : HydraTheme.line

                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: r2.on ? HydraTheme.accent : HydraTheme.muted
                                    x: r2.on ? parent.width - width - 3 : 3
                                    y: (parent.height - height) / 2
                                    Behavior on x { NumberAnimation { duration: HydraMotion.fast; easing.type: HydraMotion.curveOut } }
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
                            on: HydraState.blurEnabled
                            note: "translucency"
                            onToggled: HydraState.toggleBlur()
                        }
                        Row2 {
                            label: "Greet on startup"
                            on: HydraState.greetingEnabled
                            note: "hello at login"
                            // Assigns the STATE, never this row's own `on`: writing
                            // to `on` would break the binding above and leave the
                            // switch painted the wrong way after the next reload.
                            // onGreetingEnabledChanged saves it.
                            onToggled: HydraState.greetingEnabled = !HydraState.greetingEnabled
                        }
                        Row2 {
                            label: "Do not disturb"
                            on: HydraState.isOn("dnd")
                            note: "notifications"
                            onToggled: HydraState.toggleKey("dnd")
                        }
                        Row2 {
                            label: "Caffeine"
                            on: !HydraState.isOn("caffeine")
                            note: "idle lock off"
                            onToggled: HydraState.toggleKey("caffeine")
                        }
                    }
                }
            }
        }
    }
}
