// VALKYX TopHUD — complete DE top bar.
// Left: launcher | workspace pills | window title.
// Right: tray | wifi | bw | vol | bri | mic | bt | media | battery | bell | clock.
// Clickable modules open popup panels (calendar, monitor, audio, network).
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window
import "../core"

PanelWindow {
    id: hudRoot

    // top inset matches both sidebars (10px) so the rounded corners of the bar
    // and the sidebars share the same top line. Popups anchor below this.
    readonly property int hudTopInset: 10

    visible: ValkyxContext.rule(ValkyxState.context, "hud")
    anchors { top: true; left: true; right: true }
    margins { top: hudTopInset; left: 8; right: 8 }
    implicitWidth: Screen.width
    implicitHeight: ValkyxMetrics.hudH + hudTopInset
    color: "transparent"
    exclusiveZone: ValkyxMetrics.hudH



    // close all popups when the bar itself hides (fullscreen/game)
    onVisibleChanged: if (!visible) { calPop.visible = false; monPop.visible = false; audPop.visible = false; netPop.visible = false; medPop.visible = false; hudTip.visible = false }

    function openPopup(pop, item) {
        calPop.visible = false; monPop.visible = false; audPop.visible = false; netPop.visible = false; medPop.visible = false; valkyxPop.visible = false
        pop.openAt(item)
    }

    // ── popup panel: separate window anchored below the bar (Omarchy pattern) ──
    component HudPopup: PanelWindow {
        id: hp
        visible: false
        anchors.top: true
        margins { top: hudRoot.hudTopInset + ValkyxMetrics.hudH + 8 }
        exclusiveZone: 0
        focusable: true
        aboveWindows: true
        color: "transparent"
        property Item anchorItem: null
        function openAt(item) {
            anchorItem = item
            const g = item.mapToGlobal(0, 0)
            const sw = hp.screen ? hp.screen.width : 1366
            hp.anchors.left = true
            hp.anchors.right = false
            hp.margins.left = Math.max(4, Math.min(sw - hp.width - 4, g.x + item.width / 2 - hp.width / 2))
            visible = true
        }
        Shortcut { sequence: "Escape"; onActivated: hp.visible = false }
        Rectangle {
            anchors.fill: parent
            radius: ValkyxMetrics.rPanel
            color: ValkyxMaterials.panelGlass
            border.color: ValkyxMaterials.border
            border.width: 1
        }
    }

    // tiny helper: hoverable icon with optional tooltip + hover affordance
    component BarIcon: Item {
        id: biRoot
        property string icon: ""
        property string imageSource: ""
        property string tip: ""
        property color iconColor: ValkyxTheme.muted
        property color glow: "transparent"
        property bool danger: false
        property int glyphRotation: 0
        signal clicked()
        signal scrolled(int delta)
        width: biRoot.imageSource !== "" ? biImg.implicitWidth + 4 : (biRoot.glyphRotation % 180 !== 0 ? biTxt.implicitHeight + 4 : biTxt.implicitWidth + 4); height: parent.height
        Layout.fillHeight: true

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: "transparent"
            Behavior on color { ColorAnimation { duration: ValkyxMotion.instant } }
        }
        Image {
            id: biImg
            visible: biRoot.imageSource !== ""
            anchors.centerIn: parent
            source: biRoot.imageSource
            sourceSize: Qt.size(Math.round(16 * ValkyxState.fontScale), Math.round(16 * ValkyxState.fontScale))
            width: Math.round(16 * ValkyxState.fontScale); height: Math.round(16 * ValkyxState.fontScale)
            layer.enabled: biRoot.glow !== "transparent"
            layer.smooth: true
            layer.effect: MultiEffect {
                id: biFx
                shadowEnabled: biRoot.glow !== "transparent"
                shadowColor: biRoot.glow
                shadowOpacity: biH.containsMouse ? 0.9 : 0
                shadowBlur: 1.0
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                Behavior on shadowOpacity { NumberAnimation { duration: ValkyxMotion.fast; easing.type: Easing.OutCubic } }
            }
        }
        Text {
            id: biTxt
            visible: biRoot.imageSource === ""
            anchors.centerIn: parent
            text: biRoot.icon; color: biRoot.danger ? ValkyxTheme.danger : (biH.containsMouse ? ValkyxTheme.accent : biRoot.iconColor)
            font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(13 * ValkyxState.fontScale)
            rotation: biRoot.glyphRotation
        }
        MouseArea {
            id: biH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onEntered: if (biRoot.tip !== "") hudTip.show(biRoot.tip, biRoot)
            onExited: hudTip.hide()
            onClicked: biRoot.clicked()
            onWheel: (e) => biRoot.scrolled(e.angleDelta.y > 0 ? 1 : -1)
        }
    }

    // compact slider for the audio popup. The 4px bar this replaced had a 4px
    // hit area, so it was basically unclickable — the visible height is now
    // 10px (20% over) and the hit area is a separate 26px band centred on it,
    // so the row doesn't have to grow to make the control usable.
    component HudSlider: Rectangle {
        id: hs
        property real value: 0
        property color accent: ValkyxTheme.accent
        signal moved(real pct)
        height: 10; radius: 5; color: ValkyxTheme.tint(ValkyxTheme.muted, "26")
        Rectangle {
            width: Math.max(parent.height, parent.width * (hs.value / 100))
            height: parent.height; radius: parent.radius; color: hs.accent
            Behavior on width {
                NumberAnimation { duration: ValkyxMotion.fast; easing.type: Easing.OutCubic }
            }
        }
        MouseArea {
            anchors.centerIn: parent
            width: parent.width; height: 26
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: (m) => hs.moved(Math.max(0, Math.min(100, m.x / hs.width * 100)))
            onClicked: (m) => hs.moved(Math.max(0, Math.min(100, m.x / hs.width * 100)))
        }
    }

    // thin progress bar for the monitor popup
    component MiniBar: Rectangle {
        property real pct: 0
        property color barColor: ValkyxTheme.accent
        height: 4; radius: 2; color: ValkyxTheme.tint(ValkyxTheme.muted, "26")
        Rectangle { width: parent.width * (pct / 100); height: parent.height; radius: parent.radius; color: barColor }
    }

    // floating context menu for a running app in the taskbar
    component RunTaskMenu: PanelWindow {
        id: rt
        visible: false
        anchors.top: true
        exclusiveZone: 0
        focusable: true
        aboveWindows: true
        color: "transparent"
        implicitWidth: 190
        property real yOff: 0
        property string cls: ""
        property string label: ""

        function openFor(aCls, anchor) {
            cls = aCls
            label = ValkyxState.classIcons && aCls ? aCls : aCls
            const g = anchor.mapToGlobal(anchor.width / 2, anchor.height)
            rt.anchors.left = true; rt.anchors.right = false
            rt.margins.top = hudRoot.hudTopInset + ValkyxMetrics.hudH + 6
            rt.margins.left = Math.max(4, Math.min((rt.screen ? rt.screen.width : 1366) - rt.implicitWidth - 4, g.x - rt.implicitWidth / 2))
            visible = true
        }

        Shortcut { sequence: "Escape"; onActivated: rt.visible = false }
        onVisibleChanged: if (visible) { /* keep open */ }

        Rectangle {
            anchors.fill: parent
            radius: ValkyxMetrics.rPanel
            color: ValkyxMaterials.panelGlass
            border.color: ValkyxMaterials.border
            border.width: 1
        }
        Column {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 2
            Text {
                text: rt.cls
                color: ValkyxTheme.accent
                font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale); font.bold: true
                elide: Text.ElideRight; width: parent.width
            }
            Rectangle { width: parent.width; height: 1; color: ValkyxMaterials.border }
            MenuRow2 { label: "New Window"; enabled: true; trigger: function() { ValkyxState.launch(ValkyxState.commandForClass(rt.cls)); rt.visible = false } }
            MenuRow2 { label: "Close Window(s)"; enabled: true; trigger: function() { ValkyxState.closeClass(rt.cls); rt.visible = false } }
            MenuRow2 { label: "Quit"; enabled: true; trigger: function() { ValkyxState.quitClass(rt.cls); rt.visible = false } }
        }
    }

    component MenuRow2: Item {
        required property string label
        required property var trigger
        property bool enabled: true
        height: 24; width: parent ? parent.width : 180
        Rectangle {
            anchors.fill: parent
            radius: 5
            color: (h.containsMouse && parent.enabled) ? ValkyxMaterials.tileGlass : "transparent"
        }
        Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
               text: label; color: parent.enabled ? ValkyxTheme.text : ValkyxTheme.tint(ValkyxTheme.muted, "88")
               font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale) }
        MouseArea {
            id: h; anchors.fill: parent
            hoverEnabled: true; enabled: parent.enabled; cursorShape: Qt.PointingHandCursor
            onClicked: parent.trigger()
        }
    }

    RunTaskMenu { id: runTaskMenu }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: ValkyxMetrics.radiusXl
        color: ValkyxMaterials.hudGlass
        border.color: ValkyxMaterials.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8; anchors.rightMargin: 8
            spacing: 6

            // ── LEFT ──
            // launcher
            BarIcon {
                id: launcherItem
                imageSource: "file://StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/valkyx/data/valkyx-mark_v4_white.svg""
                iconColor: ValkyxTheme.accent
                glow: ValkyxTheme.accent
                tip: "Launcher (Super+Space)"
                onClicked: ValkyxState.launcherOpen = true
            }

            // media — small capsule: art thumb + title, click opens the media popup.
            // Only visible when something is playing.
            Item {
                id: mediaHost
                Layout.fillHeight: true
                visible: ValkyxState.mediaTitle.length > 0
                implicitWidth: mediaRow.width
                Rectangle {
                    anchors.fill: parent; radius: 6
                    color: (mediaInfoH.containsMouse || medPop.visible) ? ValkyxMaterials.surface2 : "transparent"
                    Behavior on color { ColorAnimation { duration: ValkyxMotion.instant } }
                }
                Row {
                    id: mediaRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    // art thumb (or music glyph) — clicking it (or the title) opens the popup
                    Rectangle {
                        id: mediaThumb
                        width: 22; height: 22; radius: 5
                        color: ValkyxTheme.tint(ValkyxTheme.muted, "22")
                        clip: true
                        Text {
                            anchors.centerIn: parent
                            text: "\uDB81\uDF5A"
                            color: ValkyxTheme.muted
                            font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                            visible: ValkyxState.mediaArt === ""
                        }
                        Image {
                            anchors.fill: parent
                            source: ValkyxState.mediaArt
                            sourceSize: Qt.size(44, 44)
                            fillMode: Image.PreserveAspectCrop
                            visible: ValkyxState.mediaArt !== ""
                        }
                        MouseArea { id: mediaInfoH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hudRoot.openPopup(medPop, mediaHost) }
                    }
                    // title — elided, plus compact time while playing
                    Item {
                        id: mediaTitleCol
                        anchors.verticalCenter: parent.verticalCenter
                        width: 110
                        height: titleTxt.implicitHeight + (ValkyxState.mediaLen > 0 ? Math.round(7 * ValkyxState.fontScale) : 0) + 3
                        Text {
                            id: titleTxt
                            width: parent.width
                            anchors.top: parent.top
                            text: ValkyxState.mediaTitle
                            color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                            elide: Text.ElideRight
                        }
                        Text {
                            id: timeTxt
                            width: parent.width
                            anchors.bottom: parent.bottom
                            text: medPop.timeStr(ValkyxState.mediaPos) + " / " + medPop.timeStr(ValkyxState.mediaLen)
                            color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(7 * ValkyxState.fontScale)
                            visible: ValkyxState.mediaLen > 0
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hudRoot.openPopup(medPop, mediaHost) }
                    }
                    // prev / play-pause / next — accent when active
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uDB81\uDCAB"; color: ValkyxTheme.muted
                        font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                        MouseArea { id: mPrevH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.mediaPrev() }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ValkyxState.mediaPlaying ? "\uDB80\uDFE4" : "\uDB81\uDC0A"
                        color: mediaPlayH.containsMouse ? ValkyxTheme.accent : (ValkyxState.mediaPlaying ? ValkyxTheme.accent : ValkyxTheme.muted)
                        font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(11 * ValkyxState.fontScale)
                        MouseArea { id: mediaPlayH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.mediaTogglePlay() }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uDB81\uDCAC"; color: ValkyxTheme.muted
                        font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                        MouseArea { id: mNextH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.mediaNext() }
                    }
                }
            }

            // ── CENTER: workspace widget — one big active pill + one faint
            // secondary numeral. Wheel pans the 2-slot window across the 6
            // workspaces without switching; clicking either slot switches to it.
            Rectangle { Layout.fillWidth: true; height: 1; color: "transparent" }

            Item {
                id: wsWidget
                Layout.fillHeight: true
                implicitWidth: wsRow.width
                height: parent.height

                // window pan position (0..5 = which workspaces the big pill shows)
                property int viewPos: ValkyxState.activeWsIndex > 0 ? ValkyxState.activeWsIndex - 1 : 0
                readonly property int bigWs: viewPos + 1
                readonly property int nextWs: bigWs === 6 ? 1 : bigWs + 1

                // when the real active workspace changes (keybind/click), snap
                // the window back onto it so the big pill always leads with it
                Connections {
                    target: ValkyxState
                    onActiveWsIndexChanged: {
                        if (ValkyxState.activeWsIndex > 0)
                            wsWidget.viewPos = ValkyxState.activeWsIndex - 1
                    }
                }

                // only big pill shows app icons (from existing wsWindows map)
                readonly property var bigClasses: (ValkyxState.wsWindows && ValkyxState.wsWindows[wsKey(bigWs)]) || []
                function wsKey(i) {
                    const nm = ValkyxState.wsNames[i - 1]
                    return nm ? ("0" + i + " " + nm) : String(i)
                }

                function pan(d) {
                    viewPos = Math.max(0, Math.min(5, viewPos + d))
                }

                Row {
                    id: wsRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // big pill — the workspace the window is centered on
                    Rectangle {
                        width: 66
                        height: 26
                        radius: 13
                        color: (ValkyxState.activeWsIndex === wsWidget.bigWs) ? ValkyxTheme.accent : (bigH.containsMouse ? ValkyxMaterials.surface1 : ValkyxMaterials.surface2)
                        border.color: (ValkyxState.activeWsIndex === wsWidget.bigWs) ? ValkyxMaterials.borderActive : (bigH.containsMouse ? ValkyxTheme.accent : ValkyxMaterials.borderFaint)
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: String(wsWidget.bigWs)
                                color: (ValkyxState.activeWsIndex === wsWidget.bigWs) ? ValkyxTheme.textOnAccent : (bigH.containsMouse ? ValkyxTheme.accent : ValkyxTheme.muted)
                                font.family: ValkyxTheme.fontMono
                                font.pixelSize: Math.round(12 * ValkyxState.fontScale)
                                font.bold: true
                            }
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Repeater {
                                    model: wsWidget.bigClasses.slice(0, 3)
                                    delegate: Image {
                                        required property string modelData
                                        width: 8; height: 8; smooth: true; mipmap: true
                                        sourceSize: Qt.size(22, 22)
                                        source: (ValkyxState.classIcons && ValkyxState.classIcons[modelData]) ||
                                                ("file://StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/valkyx-icons/"" + ValkyxState.themedName + "/window.png")
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: bigH
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ValkyxState.goWorkspace(wsWidget.bigWs)
                            onWheel: (e) => wsWidget.pan(e.angleDelta.y > 0 ? -1 : 1)
                        }
                    }

                    // secondary faint numeral — the next slot in the window
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: secH.containsMouse ? ValkyxMaterials.surface1 : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: String(wsWidget.nextWs)
                            color: secH.containsMouse ? ValkyxTheme.accent : ValkyxTheme.tint(ValkyxTheme.muted, "66")
                            font.family: ValkyxTheme.fontMono
                            font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                        }
                        MouseArea {
                            id: secH
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ValkyxState.goWorkspace(wsWidget.nextWs)
                            onWheel: (e) => wsWidget.pan(e.angleDelta.y > 0 ? -1 : 1)
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "transparent" }

            // system tray (nm-applet, bluetooth, etc.) — filtered to exclude wifi/bt (handled by custom items)
            Repeater {
                model: SystemTray.items
                delegate: Item {
                    required property var modelData
                    width: 22; height: parent.height
                    Layout.fillHeight: true
                    // filter out nm-applet (wifi) and bluetooth — we have custom items
                    visible: modelData.id !== "Fcitx" &&   // keyboard layout → imItem
                             !(modelData.icon && (modelData.icon.indexOf("wifi") >= 0 || modelData.icon.indexOf("network") >= 0 || modelData.icon.indexOf("bluetooth") >= 0 || modelData.icon.indexOf("bt") >= 0)) &&
                             !(modelData.title && (modelData.title.toLowerCase().indexOf("wifi") >= 0 || modelData.title.toLowerCase().indexOf("network") >= 0 || modelData.title.toLowerCase().indexOf("bluetooth") >= 0 || modelData.title.toLowerCase().indexOf("bt") >= 0))
                    Rectangle {
                        anchors.fill: parent; radius: 4
                        color: "transparent"
                        Behavior on color { ColorAnimation { duration: ValkyxMotion.instant } }
                    }
                    Image {
                        anchors.centerIn: parent
                        source: modelData.icon.indexOf("/") >= 0 || modelData.icon.startsWith("file:") ? modelData.icon : "image://theme/" + modelData.icon
                        sourceSize: Qt.size(16, 16)
                    }
                    MouseArea {
                        id: trH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) {
                                const p = trH.mapToItem(hudRoot.contentItem, m.x, m.y)
                                modelData.display(hudRoot, p.x, p.y)
                            } else {
                                modelData.activate()
                            }
                        }
                        onPressAndHold: modelData.secondaryActivate()
                        onWheel: (w) => modelData.scroll(w.angleDelta.y > 0 ? 1 : -1, false)
                    }
                }
            }

            // wifi → click opens network popup (icon reflects signal quality)
            BarIcon {
                id: wifiItem
                // arc-fan signal glyph (md-wifi_strength_1..4) via ValkyxState.wifiIcon
                icon: !ValkyxState.isOn("wifi") ? "\uDB81\uDDAA" : ValkyxState.wifiIcon(ValkyxState.wifiSig)
                iconColor: !ValkyxState.isOn("wifi") ? ValkyxTheme.danger :
                           ValkyxState.netLine.indexOf("offline") >= 0 ? ValkyxTheme.muted :
                           ValkyxState.wifiSig >= 50 ? ValkyxTheme.accent : ValkyxTheme.danger
                tip: ValkyxState.isOn("wifi") ? (ValkyxState.wifiSsid || ValkyxState.netLine) + "  " + ValkyxState.wifiSig + "%" : "WiFi off"
                onClicked: hudRoot.openPopup(netPop, wifiItem)
            }

            // volume → click opens audio popup
            BarIcon {
                id: volItem
                icon: ValkyxState.volPct === 0 ? "\uDB81\uDD81" : ValkyxState.volPct < 33 ? "\uDB81\uDD7F" : ValkyxState.volPct < 66 ? "\uDB81\uDD80" : "\uDB81\uDD7E"
                tip: "Vol " + Math.round(ValkyxState.volPct) + "%"
                onClicked: hudRoot.openPopup(audPop, volItem)
                onScrolled: ValkyxState.exec("pamixer " + (delta > 0 ? "-i 5" : "-d 5"))
            }

            // brightness — fa-sun_o classic sun
            BarIcon {
                icon: "\uDB81\uDDA8"
                tip: "Bri " + Math.round(ValkyxState.briPct) + "%"
                onClicked: ValkyxState.exec("brightnessctl -q s 50%")
                onScrolled: ValkyxState.exec("brightnessctl -q s " + (delta > 0 ? "+5%" : "5%-"))
            }

            // mic — always visible: red mic-off when muted, dim mic when live
            BarIcon {
                icon: ValkyxState.micMuted ? "\uDB80\uDF6D" : "\uDB80\uDF6C"
                danger: ValkyxState.micMuted
                tip: ValkyxState.micMuted ? "Mic muted — click to unmute" : "Mic live — click to mute"
                onClicked: ValkyxState.toggleMic()
            }

            // bluetooth — proper icon
            BarIcon {
                icon: "\uDB80\uDCAF"
                iconColor: ValkyxState.isOn("bt") ? ValkyxTheme.accent : ValkyxTheme.tint(ValkyxTheme.muted, "55")
                tip: ValkyxState.isOn("bt") ? "BT on" : "BT off"
                onClicked: ValkyxState.toggleKey("bt")
            }

            // input method — one always-visible item, always in accent
            BarIcon {
                id: imItem
                icon: ValkyxState.imLayout === "ara" ? "ع" : "EN"
                iconColor: ValkyxTheme.accent
                tip: "Keyboard: " + (ValkyxState.imLayout === "ara" ? "Arabic" : "English") + "  (Scroll Lock · Ctrl+Space · click · scroll)"
                onClicked: ValkyxState.imToggle.running = true
                onScrolled: ValkyxState.imToggle.running = true
            }

            // battery
            BarIcon {
                visible: ValkyxState.batteryPct >= 0
                icon: ValkyxState.batteryCharging ? "\uDB80\uDC84" :
                      ValkyxState.batteryPct > 75 ? "\uDB80\uDC79" :
                      ValkyxState.batteryPct > 50 ? "\uDB84\uDEA3" :
                      ValkyxState.batteryPct > 25 ? "\uDB80\uDC7E" : "\uDB84\uDEA1"
                glyphRotation: 90
                iconColor: ValkyxState.batteryPct < 15 && !ValkyxState.batteryCharging ? ValkyxTheme.danger : ValkyxTheme.muted
                tip: Math.round(ValkyxState.batteryPct) + "%" + (ValkyxState.batteryCharging ? " charging" : "") +
                     (ValkyxState.batWatts >= 0 ? "  " + (ValkyxState.batteryCharging ? "+" : "-") + ValkyxState.batWatts.toFixed(1) + "W" : "")
            }

            // clock + date → click opens calendar
            Item {
                id: clockItem
                width: clockTxt.implicitWidth + 8; height: parent.height
                Layout.fillHeight: true
                Rectangle {
                    anchors.fill: parent; radius: 4
                    color: "transparent"
                    Behavior on color { ColorAnimation { duration: ValkyxMotion.instant } }
                }
                SystemClock { id: hudClock; precision: SystemClock.Minutes }
                Text {
                    id: clockTxt
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(hudClock.date, "ddd d MMM  HH:mm")
                    color: clockH.containsMouse ? ValkyxTheme.accent : ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(11 * ValkyxState.fontScale)
                }
                MouseArea { id: clockH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hudRoot.openPopup(calPop, clockItem) }
            }

            }
    }

    // ══════════════ POPUPS ══════════════

    // ── calendar ──
    HudPopup {
        id: calPop
        implicitWidth: 224
        property date calDate: new Date()
        function calCells() {
            const y = calDate.getFullYear(), m = calDate.getMonth()
            const startDow = new Date(y, m, 1).getDay()
            const days = new Date(y, m + 1, 0).getDate()
            const cells = []
            for (let i = 0; i < startDow; i++) cells.push(0)
            for (let d = 1; d <= days; d++) cells.push(d)
            while (cells.length % 7 !== 0) cells.push(0)
            return cells
        }
        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Text {
                    text: "\uDB80\uDD41"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: calPop.calDate = new Date(calPop.calDate.getFullYear(), calPop.calDate.getMonth() - 1, 1) }
                }
                Text {
                    text: Qt.formatDate(calPop.calDate, "MMMM yyyy")
                    color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale); font.bold: true
                }
                Text {
                    text: "\uDB80\uDD42"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: calPop.calDate = new Date(calPop.calDate.getFullYear(), calPop.calDate.getMonth() + 1, 1) }
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2
                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    Text { width: 28; height: 16; horizontalAlignment: Text.AlignHCenter; text: modelData; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(8 * ValkyxState.fontScale) }
                }
            }
            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 7; spacing: 2
                Repeater {
                    model: calPop.calCells()
                    Rectangle {
                        required property int modelData
                        property bool isToday: modelData !== 0 && modelData === new Date().getDate() &&
                                               calPop.calDate.getMonth() === new Date().getMonth() &&
                                               calPop.calDate.getFullYear() === new Date().getFullYear()
                        width: 28; height: 22; radius: 4
                        color: modelData === 0 ? "transparent" : (isToday ? ValkyxTheme.tint(ValkyxTheme.muted, "33") : "transparent")
                        border.color: isToday ? ValkyxTheme.tint(ValkyxTheme.muted, "55") : "transparent"; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData === 0 ? "" : modelData
                            color: isToday ? ValkyxTheme.accent : ValkyxTheme.text
                            font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(9 * ValkyxState.fontScale); font.bold: isToday
                        }
                        MouseArea { id: cellH; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }
        }
    }

    // ── system monitor ──
    HudPopup {
        id: monPop
        implicitWidth: 240
        property var procs: []
        Process {
            id: procScan
            command: ["sh", "-c", "ps -eo comm,%cpu,%mem --sort=-%cpu | head -6 | tail -5"]
            stdout: StdioCollector { onStreamFinished: monPop.procs = text.trim().split("\n") }
        }
        onVisibleChanged: if (visible) procScan.running = true
        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            Row { spacing: 8; Text { text: "CPU"; width: 34; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale) } }
            MiniBar { width: parent.width - 42; pct: ValkyxState.cpuPct; barColor: ValkyxState.cpuPct > 80 ? ValkyxTheme.danger : ValkyxTheme.accent }
            Row { spacing: 8; Text { text: "RAM"; width: 34; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale) } }
            MiniBar { width: parent.width - 42; pct: ValkyxState.memPct; barColor: ValkyxState.memPct > 80 ? ValkyxTheme.danger : ValkyxTheme.accent }
            Row { spacing: 8; Text { text: "DISK"; width: 34; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale) } }
            MiniBar { width: parent.width - 42; pct: ValkyxState.diskPct; barColor: ValkyxState.diskPct > 85 ? ValkyxTheme.danger : ValkyxTheme.accent }
            Rectangle { width: parent.width; height: 1; color: ValkyxMaterials.border }
            Text { text: "TOP PROCESSES"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale); font.bold: true }
            Repeater {
                model: monPop.procs
                Row {
                    required property string modelData
                    property var parts: modelData.trim().split(/\s+/)
                    width: parent.width
                    spacing: 8
                    Text { text: parts[0] || ""; width: parent.width - 70; elide: Text.ElideRight; color: ValkyxTheme.text; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(9 * ValkyxState.fontScale) }
                    Text { text: (parts[1] || "") + "%"; width: 32; horizontalAlignment: Text.AlignRight; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(9 * ValkyxState.fontScale) }
                    Text { text: (parts[2] || "") + "%"; width: 32; horizontalAlignment: Text.AlignRight; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(9 * ValkyxState.fontScale) }
                }
            }
        }
    }

    // ── audio ──
    HudPopup {
        id: audPop
        implicitWidth: 250
        implicitHeight: audCol.implicitHeight + 20
        onVisibleChanged: if (visible) { ValkyxState.audioScan.running = true }
        Column {
            id: audCol
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            Text {
                text: audPop.currentSinkLabel() !== "" ? audPop.currentSinkLabel() : "Audio"
                color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale); font.bold: true
                elide: Text.ElideRight; width: parent.width
            }
            Row {
                width: parent.width
                spacing: 8
                Text { text: "\uDB81\uDD7E"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale) }
                HudSlider {
                    width: parent.width - 60; value: ValkyxState.volPct
                    onMoved: ValkyxState.setVolume(pct)
                }
                Text { text: Math.round(ValkyxState.volPct) + "%"; width: 30; horizontalAlignment: Text.AlignRight; color: ValkyxTheme.text; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(9 * ValkyxState.fontScale) }
            }
            Rectangle {
                width: parent.width; height: 24; radius: 6
                color: "transparent"
                border.color: ValkyxState.volPct === 0 ? ValkyxTheme.tint(ValkyxTheme.danger, "66") : ValkyxMaterials.border; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: ValkyxState.volPct === 0 ? "\uDB81\uDD81  Unmute" : "\uDB81\uDD81  Mute"
                    color: ValkyxState.volPct === 0 ? ValkyxTheme.danger : (muteH.containsMouse ? ValkyxTheme.accent : ValkyxTheme.text)
                    font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                }
                MouseArea { id: muteH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.exec("pamixer -t") }
            }
            Rectangle {
                width: parent.width; height: 24; radius: 6
                color: "transparent"
                border.color: ValkyxState.micMuted ? ValkyxTheme.tint(ValkyxTheme.danger, "66") : ValkyxMaterials.border; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: ValkyxState.micMuted ? "\uDB80\uDF6D  Mic muted — tap to unmute" : "\uDB80\uDF6C  Mic live — tap to mute"
                    color: ValkyxState.micMuted ? ValkyxTheme.danger : (micH.containsMouse ? ValkyxTheme.accent : ValkyxTheme.text)
                    font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                }
                MouseArea { id: micH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.toggleMic() }
            }

            // ── device picker ──
            Text { text: "Output"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale); font.bold: true }
            Repeater {
                model: ValkyxState.audioSinks
                Rectangle {
                    required property var modelData
                    width: parent.width; height: 24; radius: 6
                    color: arow.containsMouse ? ValkyxMaterials.surface2 : (modelData.default ? ValkyxTheme.tint(ValkyxTheme.accent, "22") : "transparent")
                    MouseArea {
                        id: arow; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: ValkyxState.setAudioOutput(modelData.id)
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 6; leftPadding: 6
                        width: parent.width
                        Text {
                            text: modelData.default ? "\uDB80\uDD2C" : "\uDB81\uDD7E"
                            color: modelData.default ? ValkyxTheme.accent : ValkyxTheme.muted
                            font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                        }
                        Text {
                            width: parent.width - 66
                            text: modelData.label; elide: Text.ElideRight
                            color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                        }
                    }
                }
            }
            Text { text: "Input"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale); font.bold: true }
            Repeater {
                model: ValkyxState.audioSources
                Rectangle {
                    required property var modelData
                    width: parent.width; height: 24; radius: 6
                    color: irow.containsMouse ? ValkyxMaterials.surface2 : (modelData.default ? ValkyxTheme.tint(ValkyxTheme.accent, "22") : "transparent")
                    MouseArea {
                        id: irow; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: ValkyxState.setAudioInput(modelData.id)
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 6; leftPadding: 6
                        width: parent.width
                        Text {
                            text: modelData.default ? "\uDB80\uDD2C" : "\uDB80\uDF6C"
                            color: modelData.default ? ValkyxTheme.accent : ValkyxTheme.muted
                            font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                        }
                        Text {
                            width: parent.width - 66
                            text: modelData.label; elide: Text.ElideRight
                            color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                        }
                    }
                }
            }
        }
        function currentSinkLabel() {
            for (let i = 0; i < ValkyxState.audioSinks.length; i++)
                if (ValkyxState.audioSinks[i].default) return ValkyxState.audioSinks[i].label
            return ""
        }
    }

    // ── media player ──
    HudPopup {
        id: medPop
        implicitWidth: 300
        implicitHeight: medCol.implicitHeight + 20
        onVisibleChanged: if (visible) { ValkyxState.mediaGet.running = true; openP = true }
        property bool openP: false
        function timeStr(sec) {
            sec = Math.max(0, Math.floor(sec || 0))
            const m = Math.floor(sec / 60), s = sec % 60
            return m + ":" + (s < 10 ? "0" : "") + s
        }
        Column {
            id: medCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            // cover art — big, with music-glyph fallback
            Rectangle {
                id: medCover
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(180, parent.width); height: 180
                radius: ValkyxMetrics.rPanel
                color: ValkyxTheme.tint(ValkyxTheme.muted, "22")
                clip: true
                Text {
                    anchors.centerIn: parent
                    text: "\uDB81\uDF5A"
                    color: ValkyxTheme.tint(ValkyxTheme.muted, "88")
                    font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(56 * ValkyxState.fontScale)
                    visible: ValkyxState.mediaArt === ""
                }
                Image {
                    anchors.fill: parent
                    source: ValkyxState.mediaArt
                    sourceSize: Qt.size(360, 360)
                    fillMode: Image.PreserveAspectCrop
                    visible: ValkyxState.mediaArt !== ""
                }
            }
            // title + artist
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                text: ValkyxState.mediaTitle.length > 0 ? ValkyxState.mediaTitle : "Nothing playing"
                color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * ValkyxState.fontScale); font.bold: true
            }
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                text: ValkyxState.mediaArtist
                color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
            }
            // seek bar + times
            Row {
                width: parent.width
                spacing: 6
                Text {
                    width: 42; text: medPop.timeStr(ValkyxState.mediaPos)
                    color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                }
                HudSlider {
                    width: parent.width - 96; anchors.verticalCenter: parent.verticalCenter
                    value: ValkyxState.mediaLen > 0 ? ValkyxState.mediaPos / ValkyxState.mediaLen * 100 : 0
                    onMoved: ValkyxState.mediaSeek(pct)
                }
                Text {
                    width: 42; horizontalAlignment: Text.AlignRight; text: medPop.timeStr(ValkyxState.mediaLen)
                    color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                }
            }
            // transport controls
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uDB81\uDCAB"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(14 * ValkyxState.fontScale)
                    MouseArea { id: mdPrev; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.mediaPrev() }
                }
                Rectangle {
                    width: 34; height: 34; radius: 17
                    color: mdPlay.containsMouse ? ValkyxTheme.tint(ValkyxTheme.accent, "33") : ValkyxTheme.tint(ValkyxTheme.accent, "22")
                    Text {
                        anchors.centerIn: parent
                        text: ValkyxState.mediaPlaying ? "\uDB80\uDFE4" : "\uDB81\uDC0A"
                        color: ValkyxTheme.accent; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(15 * ValkyxState.fontScale)
                    }
                    MouseArea { id: mdPlay; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.mediaTogglePlay() }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uDB81\uDCAC"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(14 * ValkyxState.fontScale)
                    MouseArea { id: mdNext; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.mediaNext() }
                }
            }
        }
    }

    // ── network ──
    HudPopup {
        id: netPop
        implicitWidth: 240
        onVisibleChanged: if (visible) ValkyxState.refreshWifi()
        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            Row {
                width: parent.width
                spacing: 8
                Text { text: "WiFi"; color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale); font.bold: true }
                Rectangle { width: 4; height: 1; color: "transparent" }
                Text {
                    text: ValkyxState.isOn("wifi") ? "ON" : "OFF"
                    color: ValkyxState.isOn("wifi") ? ValkyxTheme.accent : ValkyxTheme.danger
                    font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(8 * ValkyxState.fontScale); font.bold: true
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.toggleKey("wifi") }
                }
                Rectangle { Layout.fillWidth: true; width: parent.width - 120; height: 1; color: "transparent" }
                Text {
                    text: "\uDB81\uDC50"; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.rescanWifi() }
                }
            }
            Rectangle { width: parent.width; height: 1; color: ValkyxMaterials.border }
            Repeater {
                model: ValkyxState.wifiList
                Rectangle {
                    required property var modelData
                    width: parent.width; height: 24; radius: 6
                    color: "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 6
                        text: ValkyxState.wifiIcon(modelData.sig) + " " + modelData.ssid
                        color: modelData.use ? ValkyxTheme.accent : (netH.containsMouse ? ValkyxTheme.accent : ValkyxTheme.text)
                        font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                        elide: Text.ElideRight; width: parent.width - 70
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right; anchors.rightMargin: 6
                        text: (modelData.sec !== "" && modelData.sec !== "--" ? "\uDB80\uDF3E " : "") + modelData.sig + "%"
                        color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                    }
                    MouseArea {
                        id: netH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: ValkyxState.exec("valkyx-wifi-connect \"" + modelData.ssid + "\" \"" + modelData.sec + "\"")
                    }
                }
            }
        }
    }

    // ── floating tooltip: separate always-on-top window below the bar.
    // Keeps label bubbles from masking neighboring icons; shadow adds contrast
    // over busy wallpapers. Driven by BarIcon/hwItem hover signals.
    PanelWindow {
        id: hudTip
        visible: false
        aboveWindows: true
        exclusiveZone: 0
        focusable: false
        color: "transparent"
        anchors.top: true
        implicitWidth: tipBoxTxt.implicitWidth + 18
        implicitHeight: 26
        property string tipText: ""
        // set the text first, then measure + place on the NEXT frame: reading
        // implicitWidth in the same tick clamps against the previous tip's width
        // (a long tip then overflows the screen edge).
        function show(text, item) {
            tipText = text
            const g = item.mapToGlobal(item.width / 2, item.height / 2)
            hudTip.anchors.left = true; hudTip.anchors.right = false
            Qt.callLater(() => {
                const sw = hudTip.screen ? hudTip.screen.width : 1366
                hudTip.margins.top = g.y + 6
                hudTip.margins.left = Math.max(4, Math.min(sw - hudTip.implicitWidth - 4, g.x - hudTip.implicitWidth / 2))
            })
            visible = true
        }
        function hide() { visible = false }
        Rectangle {
            anchors.fill: parent
            radius: 7
            // solid fieldFill, not tileGlass: a 26px label must stay readable
            // over any window — glass takes the background's color (blue box).
            color: ValkyxTheme.fieldFill
            border.color: ValkyxMaterials.border
            border.width: 1
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#000000B0"
                shadowOpacity: 0.9
                shadowBlur: 0.4
                shadowVerticalOffset: 2
            }
            Text {
                id: tipBoxTxt
                anchors.centerIn: parent
                text: hudTip.tipText
                color: ValkyxTheme.text
                font.family: ValkyxTheme.fontUI
                font.pixelSize: Math.round(10 * ValkyxState.fontScale)
            }
        }
    }
}