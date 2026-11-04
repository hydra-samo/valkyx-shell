// AXORA Sidebar — control center, iNiR-style.
// Floating island (16px margins, 24px radius, 360 wide), ghost/borderless cards,
// generous 24px internal padding, soft pill sliders. All functional capsules kept:
// quick toggles, brightness/volume, theme, workspace, wifi/bt/caffeine drawers,
// power profile, power menu.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import "../core"

PanelWindow {
    id: root

    visible: AxoraState.panelOpen
    anchors { right: true; top: true; bottom: true }
    // iNiR floating island — generous margin off the edge
    margins { top: 16; bottom: 16; right: 16 }

    implicitWidth: AxoraMetrics.sidebarW
    exclusiveZone: AxoraMetrics.sidebarW + 16
    color: "transparent"
    focusable: true

    property bool exiting: false
    property bool netOpen: false
    property bool btOpen: false
    property bool cafOpen: false
    property bool tsOpen: false
    function close() { exiting = true; AxoraState.panelOpen = false }
    onVisibleChanged: if (visible) { exiting = false; AxoraState.refreshNotifs() }

    function tsSubtitle() {
        if (!AxoraState.tsUp) return "Off"
        const on = AxoraState.tsPeers.filter(p => p.online).length
        const tot = AxoraState.tsPeers.length
        return !tot ? AxoraState.tsSelfIp : "self " + AxoraState.tsSelfName + "  " + AxoraState.tsSelfIp + "  ·  " + on + "/" + tot + " online"
    }

    function caffeineLabel() {
        const m = AxoraState.caffeineMin
        if (m === -1) return "On (never idle)"
        if (m === 0) return "Off"
        return "On for " + m + " min"
    }

    // ── iOS-style switch (accent on-state track, follows theme/wallpaper accent) ──
    component TogglePill: Rectangle {
        property bool on: false
        signal toggled()
        width: 44; height: 24; radius: 12
        color: on ? AxoraTheme.accent : AxoraTheme.tint(AxoraTheme.muted, "2e")
        border.color: on ? AxoraMaterials.borderActive : "transparent"; border.width: 1
        Rectangle {
            x: on ? width - 21 : 2; width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: AxoraTheme.text
        }
        MouseArea { anchors.fill: parent; onClicked: toggled(); cursorShape: Qt.PointingHandCursor }
    }

    // ── soft pill slider (iNiR): full-width 40px pill, neutral fill ──
    component PillSlider: Rectangle {
        id: slider
        property string glyph: ""
        property bool glyphClickable: false
        property bool glyphOpen: false
        property real value: 0
        signal moved(real pct)
        signal glyphClicked()
        // 44 = PillCapsule height, so the sliders read as part of the sidebar
        // rather than as two unrelated fat lines. 20% over the old 36.
        height: 44
        radius: 22
        color: AxoraMaterials.surface0
        Rectangle {
            width: Math.max(parent.height, parent.width * (slider.value / 100))
            height: parent.height; radius: parent.radius
            color: AxoraTheme.accent
            // The value is optimistic (setVolume/setBrightness write volPct before
            // the command lands), so without this the fill SNAPS to the new width
            // and then jitters back when the 1s poller corrects it.
            Behavior on width {
                NumberAnimation { duration: AxoraMotion.fast; easing.type: Easing.OutCubic }
            }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: AxoraMetrics.m + 2; anchors.rightMargin: AxoraMetrics.m
            Text {
                text: slider.glyphOpen ? "\uDB80\uDD40" : slider.glyph
                font.family: AxoraTheme.fontMono
                font.pixelSize: Math.round(15 * AxoraState.fontScale)
                color: AxoraTheme.textOnAccent
                rotation: slider.glyphOpen ? 180 : 0
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(slider.value) + "%"
                font.family: AxoraTheme.fontUI
                font.pixelSize: Math.round(11 * AxoraState.fontScale)
                color: AxoraTheme.muted
            }
        }
        MouseArea {
            x: 0; y: 0; width: 40; height: parent.height; z: 2
            visible: slider.glyphClickable
            cursorShape: Qt.PointingHandCursor
            onClicked: slider.glyphClicked()
        }
        MouseArea {
            anchors.fill: parent; preventStealing: true
            onPositionChanged: (mouse) => { slider.moved(Math.max(0, Math.min(100, mouse.x / parent.width * 100))) }
            onClicked: (mouse) => { if (!slider.glyphClickable || mouse.x > 40) slider.moved(Math.max(0, Math.min(100, mouse.x / parent.width * 100))) }
        }
    }

    // ── ghost capsule module: icon | title+status | control, no border ──
    component CapsuleModule: Item {
        id: cap
        property string icon: ""
        property color iconColor: AxoraTheme.muted
        property string title: ""
        property string subtitle: ""
        property bool subVisible: subtitle.length > 0
        property bool loud: false
        default property alias content: controlArea.data
        implicitHeight: 56
        width: parent ? parent.width : 340
        Rectangle {
            anchors.fill: parent
            radius: AxoraMetrics.radiusMd
            color: AxoraMaterials.surface2
            Rectangle {
                visible: cap.loud
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: 3
                color: AxoraTheme.accent
                radius: 2
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: AxoraMetrics.m; anchors.rightMargin: AxoraMetrics.m
                spacing: AxoraMetrics.s
                Item {
                    Layout.preferredWidth: 30; Layout.preferredHeight: 24
                    Text {
                        anchors.centerIn: parent; text: cap.icon
                        color: cap.loud ? AxoraTheme.accent : cap.iconColor
                        font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(15 * AxoraState.fontScale)
                    }
                }
                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: cap.title; color: AxoraTheme.text
                        font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(10 * AxoraState.fontScale)
                    }
                    Text {
                        visible: cap.subVisible
                        text: cap.subtitle; color: AxoraTheme.muted; elide: Text.ElideRight
                        width: parent.width
                        font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                    }
                }
                Row {
                    id: controlArea
                    Layout.preferredWidth: 172
                    spacing: AxoraMetrics.xs
                }
            }
        }
    }

    // ── GNOME-style capsule: pill body = toggle, right glyph zone (separated) = open drawer ──
    component PillCapsule: Rectangle {
        id: pill
        property string icon: ""
        property string label: ""
        property string drawerGlyph: "\uDB80\uDD40"
        property bool active: false       // toggle/key on
        property bool isOpen: false
        signal toggled
        signal clicked
        height: 44; radius: 17
        color: active ? AxoraTheme.accent : AxoraMaterials.surface2
        border.color: isOpen ? AxoraMaterials.borderActive : "transparent"; border.width: 1
        // vertical separator dividing the toggle zone (left) from the glyph/drawer zone (right)
        Rectangle {
            anchors.top: parent.top; anchors.bottom: parent.bottom
            anchors.topMargin: 8; anchors.bottomMargin: 8
            x: pill.width - 28
            width: 1
            z: 2
            color: "transparent"
        }
        RowLayout {
            anchors.fill: parent; spacing: 2
            Text {
                Layout.leftMargin: 10
                text: pill.icon; color: pill.active ? AxoraTheme.textOnAccent : AxoraTheme.text
                font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(12 * AxoraState.fontScale)
            }
            Text {
                Layout.fillWidth: true
                text: pill.label; elide: Text.ElideRight
                color: pill.active ? AxoraTheme.textOnAccent : AxoraTheme.muted
                font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale)
            }
            Text {
                Layout.rightMargin: 8
                text: pill.drawerGlyph
                color: pill.isOpen ? AxoraTheme.textOnAccent : (pill.active ? AxoraTheme.textOnAccent : AxoraTheme.muted)
                font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(11 * AxoraState.fontScale)
                rotation: pill.isOpen ? 180 : 0
            }
        }
        MouseArea {
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (mouse.x > width - 26) pill.clicked()   // right glyph zone = open/close drawer
                else pill.toggled()                         // pill body = toggle network
            }
        }
    }

    // ── the floating island body ──
    Rectangle {
        id: panelBody
        anchors.fill: parent
        radius: AxoraMetrics.radiusXl
        color: AxoraMaterials.panelGlass
        border.color: AxoraMaterials.borderFaint
        border.width: 1
        focus: true
        Keys.onEscapePressed: root.close()
        transformOrigin: Item.Right
        scale: 1
        opacity: 1
        Behavior on scale { NumberAnimation { duration: AxoraMotion.panel; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: AxoraMotion.panel; easing.type: Easing.OutCubic } }
        onVisibleChanged: {
            if (visible) {
                scale = 0.95
                opacity = 0
                Qt.callLater(function() { scale = 1; opacity = 1 })
            } else {
                scale = 1
                opacity = 1
            }
        }

        // ── header: iNiR hero card (full-width, clipped to panel top radius) ──
        // Reference: banner bleeds edge-to-edge with a bottom gradient ramp; the
        // avatar overlaps the banner edge; identity + actions sit in a footer band
        // BELOW the banner so text never floats raw on the artwork.
        Rectangle {
            id: heroCard
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: heroBannerH + 48
            radius: AxoraMetrics.radiusXl
            color: "transparent"
            clip: true
            readonly property int heroBannerH: 96

            // wallpaper banner — full bleed, clipped by the card's top radius
            Rectangle {
                id: heroBanner
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: heroCard.heroBannerH
                radius: AxoraMetrics.radiusXl
                color: AxoraTheme.field
                Image {
                    id: heroImg
                    anchors.fill: parent
                    source: (function() {
                        const p = AxoraState.activeMediaPath
                        if (!p) return ""
                        return WallpaperStore.kindOf(p) === "image"
                            ? "file://" + p
                            : "file://" + WallpaperStore.cachedPosterPath(p)
                    })()
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    visible: false
                }
                // round-clip the cover to the panel radius (Qt clip is rectangular only)
                Item {
                    id: heroMask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false
                    Rectangle {
                        anchors.fill: parent
                        radius: AxoraMetrics.radiusXl
                        color: "white"
                    }
                }
                MultiEffect {
                    anchors.fill: parent
                    source: heroImg
                    maskEnabled: true
                    maskSource: heroMask
                }
                // landing-zone gradient ramp — gives the avatar + footer text a dark base
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 36
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(0,0,0,0.0) }
                        GradientStop { position: 1; color: Qt.rgba(0,0,0,0.6) }
                    }
                }
            }

            // footer rail — identity band below the banner (on panel bg, always legible)
            Item {
                id: footerRail
                anchors { left: parent.left; right: parent.right; top: heroBanner.bottom }
                height: 48
            }

            // brand — axora cobra logo, vertically centered with the name/subtitle block
            Rectangle {
                id: heroAvatar
                x: AxoraMetrics.m
                anchors.verticalCenter: footerRail.verticalCenter
                width: 34; height: 34
                color: "transparent"
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorizationColor: AxoraTheme.accent
                    colorization: 1.0
                }
                Image {
                    anchors.fill: parent
                    anchors.margins: 3
                    source: "file://StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/hypr/assets/axora-logo.png""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false
                }
            }

            // identity — bold name + username·context·uptime, right of avatar in the footer
            Column {
                x: AxoraMetrics.m + 34 + AxoraMetrics.s
                anchors.verticalCenter: footerRail.verticalCenter
                width: parent.width - (AxoraMetrics.m + 34 + AxoraMetrics.s) - 70
                spacing: 2
                Text { text: "AXORA"; color: AxoraTheme.text; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(14 * AxoraState.fontScale); font.bold: true; elide: Text.ElideRight; width: parent.width }
                Text { text: AxoraState.uptimeLine; color: AxoraTheme.muted; font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(9 * AxoraState.fontScale); elide: Text.ElideRight; width: parent.width }
            }

            // header actions — power + settings, right-aligned in the footer band
            Row {
                anchors.right: parent.right; anchors.rightMargin: AxoraMetrics.s
                anchors.verticalCenter: footerRail.verticalCenter
                spacing: AxoraMetrics.s
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: powHead.containsMouse ? AxoraMaterials.surface2 : "transparent"
                    Behavior on color { ColorAnimation { duration: AxoraMotion.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "\uDB81\uDC25"
                        font.family: AxoraTheme.fontMono
                        font.pixelSize: Math.round(12 * AxoraState.fontScale)
                        color: AxoraTheme.muted
                    }
                    MouseArea {
                        id: powHead
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.close(); AxoraState.powerOpen = true }
                    }
                }
                Rectangle {
                    id: gearBtn
                    width: 26; height: 26; radius: 13
                    color: gearHover.containsMouse ? AxoraMaterials.surface2 : "transparent"
                    Behavior on color { ColorAnimation { duration: AxoraMotion.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "\uDB81\uDC93"
                        font.family: AxoraTheme.fontMono
                        font.pixelSize: Math.round(12 * AxoraState.fontScale)
                        color: AxoraTheme.muted
                    }
                    MouseArea {
                        id: gearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.close(); AxoraState.settingsOpen = true }
                    }
                }
            }

            // live wallpaper refresh — nudge the Image when the poster regenerates
            Connections {
                target: WallpaperStore
                function onPosterGenerated(path) {
                    if (path === WallpaperStore.cachedPosterPath(AxoraState.activeMediaPath)) {
                        const s = heroImg.source
                        heroImg.source = ""
                        heroImg.source = s
                    }
                }
            }
        }

        Flickable {
            id: bodyFlic
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: heroCard.bottom
            anchors.leftMargin: AxoraMetrics.xl   // iNiR signature: 24px internal padding
            anchors.rightMargin: AxoraMetrics.xl
            anchors.bottomMargin: AxoraMetrics.xl
            anchors.topMargin: AxoraMetrics.l
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: bodyCol.implicitHeight

            Column {
                id: bodyCol
                width: parent.width
                spacing: AxoraMetrics.l

                // ── quick pills: Wi-Fi / Bluetooth / Caffeine + one shared drawer ──
                Column {
                    width: parent.width
                    spacing: AxoraMetrics.s

                    Row {
                        width: parent.width
                        spacing: AxoraMetrics.s
                        PillCapsule {
                            width: (parent.width - 3 * AxoraMetrics.s) / 4
                            icon: AxoraState.isOn("wifi") ? AxoraState.wifiIcon(AxoraState.wifiSig) : "\uDB81\uDDAA"; label: "Wi-Fi"
                            active: AxoraState.isOn("wifi")
                            isOpen: netOpen
                            onToggled: AxoraState.toggleKey("wifi")
                            onClicked: { netOpen = !netOpen; btOpen = false; cafOpen = false; if (netOpen) AxoraState.refreshWifi() }
                        }
                        PillCapsule {
                            width: (parent.width - 3 * AxoraMetrics.s) / 4
                            icon: "\uDB80\uDCAF"; label: "Bluetooth"
                            active: AxoraState.isOn("bt")
                            isOpen: btOpen
                            onToggled: AxoraState.toggleKey("bt")
                            onClicked: { btOpen = !btOpen; netOpen = false; cafOpen = false; if (btOpen) AxoraState.refreshBt() }
                        }
                        PillCapsule {
                            width: (parent.width - 3 * AxoraMetrics.s) / 4
                            icon: "󰅶"; label: "Caffeine"
                            active: AxoraState.caffeineMin !== 0
                            isOpen: cafOpen
                            onToggled: AxoraState.setCaffeine(AxoraState.caffeineMin !== 0 ? 0 : -1)
                            onClicked: { cafOpen = !cafOpen; netOpen = false; btOpen = false }
                        }
                        PillCapsule {
                            width: (parent.width - 3 * AxoraMetrics.s) / 4
                            icon: "\uDB80\uDE96"; label: "Game"
                            active: AxoraState.gameModeOn
                            drawerGlyph: ""
                            onToggled: AxoraState.toggleGameMode()
                            onClicked: AxoraState.toggleGameMode()
                        }
                    }

                    // shared drawer — one small card dropping below the pills
                    Item {
                        width: parent.width
                        height: (netOpen ? netDrawer.height : btOpen ? btDrawer.height : cafOpen ? cafDrawer.height : 0)
                        clip: true
                        Rectangle {
                            id: netDrawer
                            width: parent.width; height: Math.max(40, Math.min(116, 6 + AxoraState.wifiList.length * 27) + 8)
                            visible: netOpen
                            radius: AxoraMetrics.radiusMd
                            color: AxoraMaterials.surface2
                            ListView {
                                anchors.fill: parent; anchors.margins: 4
                                model: AxoraState.wifiList
                                clip: true
                                delegate: Rectangle {
                                    id: wifiRow
                                    required property var modelData
                                    width: ListView.view.width; height: 27; radius: 7
                                    color: rowH.containsMouse ? AxoraMaterials.surface0 : (modelData.use ? AxoraTheme.accentDim : "transparent")
                                    MouseArea { id: rowH; anchors.fill: parent; hoverEnabled: true; onClicked: AxoraState.exec("axora-wifi-connect \"" + modelData.ssid + "\" \"" + modelData.sec + "\""); cursorShape: Qt.PointingHandCursor }
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                        Text {
                                            text: modelData.use ? "\uDB80\uDD2C" : (modelData.sec ? "\uDB80\uDF3E" : "\uDB81\uDDA9")
                                            color: modelData.use ? AxoraTheme.accent : AxoraTheme.muted
                                            font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(10 * AxoraState.fontScale)
                                        }
                                        Text {
                                            text: modelData.ssid; elide: Text.ElideMiddle
                                            color: AxoraTheme.text
                                            font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                                        }
                                        Text {
                                            text: AxoraState.wifiIcon(modelData.sig)
                                            color: AxoraTheme.muted; font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(9 * AxoraState.fontScale)
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: AxoraState.wifiList.length === 0
                                anchors.centerIn: parent; text: "Scanning…"
                                color: AxoraTheme.muted; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                            }
                        }
                        Rectangle {
                            id: btDrawer
                            width: parent.width; height: Math.max(40, Math.min(116, 6 + AxoraState.btDevices.length * 27) + 8)
                            visible: btOpen
                            radius: AxoraMetrics.radiusMd
                            color: AxoraMaterials.surface2
                            ListView {
                                anchors.fill: parent; anchors.margins: 4
                                model: AxoraState.btDevices
                                clip: true
                                delegate: Rectangle {
                                    id: btRow
                                    required property var modelData
                                    width: ListView.view.width; height: 27; radius: 7
                                    color: rowBh.containsMouse ? AxoraMaterials.surface0 : (modelData.connected ? AxoraTheme.accentDim : "transparent")
                                    MouseArea { id: rowBh; anchors.fill: parent; hoverEnabled: true; onClicked: AxoraState.toggleBtDevice(modelData.mac, modelData.connected); cursorShape: Qt.PointingHandCursor }
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                        Text {
                                            text: modelData.connected ? "\uDB80\uDD2C" : "\uDB80\uDCAF"
                                            color: modelData.connected ? AxoraTheme.accent : AxoraTheme.muted
                                            font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(10 * AxoraState.fontScale)
                                        }
                                        Text {
                                            text: modelData.name; elide: Text.ElideMiddle; color: AxoraTheme.text
                                            font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: AxoraState.btDevices.length === 0
                                anchors.centerIn: parent; text: "No paired devices"
                                color: AxoraTheme.muted; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                            }
                        }
                        Rectangle {
                            id: cafDrawer
                            width: parent.width; height: 36
                            visible: cafOpen
                            radius: AxoraMetrics.radiusMd
                            color: AxoraMaterials.surface2
                            Row {
                                anchors.fill: parent; anchors.margins: 3
                                spacing: 4
                                Repeater {
                                    model: [
                                        { min: -1, label: "Forever" }, { min: 5, label: "5m" }, { min: 15, label: "15m" },
                                        { min: 30, label: "30m" }, { min: 60, label: "60m" }, { min: 0, label: "Off" }
                                    ]
                                    Rectangle {
                                        required property var modelData
                                        width: (parent.width - 5 * 4) / 6; height: 26; radius: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: hC.containsMouse ? AxoraMaterials.surface0 : (AxoraState.caffeineMin === modelData.min ? AxoraTheme.accentDim : "transparent")
                                        border.color: AxoraState.caffeineMin === modelData.min ? AxoraMaterials.borderActive : "transparent"; border.width: 1
                                        Text { anchors.centerIn: parent; text: modelData.label; color: AxoraState.caffeineMin === modelData.min ? AxoraTheme.text : AxoraTheme.muted; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale) }
                                        MouseArea { id: hC; anchors.fill: parent; hoverEnabled: true; onClicked: AxoraState.setCaffeine(modelData.min); cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── audio & display (soft pill sliders + audio I/O drawer) ──
                Column {
                    width: parent.width
                    spacing: AxoraMetrics.s

                    Rectangle {
                        width: parent.width
                        height: sliderCol.implicitHeight + 2 * AxoraMetrics.m
                        radius: AxoraMetrics.radiusMd
                        color: AxoraMaterials.surface2
                        property bool audioOpen: false
                        Behavior on height { NumberAnimation { duration: AxoraMotion.transition; easing.type: Easing.OutCubic } }

                        Column {
                            id: sliderCol
                            anchors.fill: parent
                            anchors.margins: AxoraMetrics.m
                            spacing: AxoraMetrics.m

                            PillSlider {
                                width: parent.width
                                glyph: "\uDB81\uDDA8"
                                value: AxoraState.briPct
                                onMoved: (pct) => AxoraState.setBrightness(pct)
                            }
                            PillSlider {
                                width: parent.width
                                glyph: AxoraState.volPct === 0 ? "\uDB81\uDD81" : AxoraState.volPct < 33 ? "\uDB81\uDD7F" : AxoraState.volPct < 66 ? "\uDB81\uDD80" : "\uDB81\uDD7E"
                                value: AxoraState.volPct
                                glyphClickable: true
                                glyphOpen: parent.parent.audioOpen
                                onGlyphClicked: parent.parent.audioOpen = !parent.parent.audioOpen
                                onMoved: (pct) => AxoraState.setVolume(pct)
                            }

                            // audio I/O drawer — drops from the volume glyph (no standalone card)
                            Column {
                                visible: parent.parent.audioOpen
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: AxoraState.audioSinks
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width; height: 26; radius: 7
                                        color: rowS.containsMouse ? AxoraMaterials.surface0 : (modelData.default ? AxoraTheme.accentDim : "transparent")
                                        MouseArea {
                                            id: rowS; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { parent.parent.parent.parent.audioOpen = false; AxoraState.setAudioOutput(modelData.id) }
                                        }
                                        Row {
                                            width: parent.width
                                            anchors.verticalCenter: parent.verticalCenter; spacing: 6; leftPadding: 6
                                            Text {
                                                text: modelData.default ? "\uDB80\uDD2C" : "\uDB81\uDD7E"
                                                color: modelData.default ? AxoraTheme.accent : AxoraTheme.muted
                                                font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(10 * AxoraState.fontScale)
                                            }
                                            Text {
                                                width: parent.width - 66
                                                text: modelData.label; elide: Text.ElideMiddle
                                                color: AxoraTheme.text; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                                            }
                                        }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "transparent" }
                                Text {
                                    text: "Input"; color: AxoraTheme.muted
                                    font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale); font.bold: true
                                }
                                Repeater {
                                    model: AxoraState.audioSources
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width; height: 26; radius: 7
                                        color: rowI.containsMouse ? AxoraMaterials.surface0 : (modelData.default ? AxoraTheme.accentDim : "transparent")
                                        MouseArea {
                                            id: rowI; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { parent.parent.parent.parent.audioOpen = false; AxoraState.setAudioInput(modelData.id) }
                                        }
                                        Row {
                                            width: parent.width
                                            anchors.verticalCenter: parent.verticalCenter; spacing: 6; leftPadding: 6
                                            Text {
                                                text: modelData.default ? "\uDB80\uDD2C" : "\uDB80\uDF6C"
                                                color: modelData.default ? AxoraTheme.accent : AxoraTheme.muted
                                                font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(10 * AxoraState.fontScale)
                                            }
                                            Text {
                                                width: parent.width - 66
                                                text: modelData.label; elide: Text.ElideMiddle
                                                color: AxoraTheme.text; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // ── notifications (inline, tappable rows — jump to their app/dir) ──
                Column {
                    width: parent.width
                    spacing: AxoraMetrics.s

                    // header — left: bell + title | right: count badge + clear
                    Item {
                        width: parent.width; height: 24

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 7
                            Text {
                                text: "\uDB80\uDC9A"; color: AxoraTheme.accent
                                font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(12 * AxoraState.fontScale)
                            }
                            Text {
                                text: "Notifications"; color: AxoraTheme.text
                                font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(10 * AxoraState.fontScale); font.bold: true
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Rectangle {
                                visible: AxoraState.notifList.length > 0
                                width: 20; height: 20; radius: 10
                                color: AxoraTheme.accent
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: AxoraState.notifList.length
                                    color: AxoraTheme.textOnAccent
                                    font.family: AxoraTheme.fontMono; font.bold: true
                                    font.pixelSize: Math.round(9 * AxoraState.fontScale)
                                }
                            }
                            Item {
                                width: 20; height: 20
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uDB80\uDD56"; color: clearH.containsMouse ? AxoraTheme.accent : AxoraTheme.muted
                                    font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(11 * AxoraState.fontScale)
                                    Behavior on color { ColorAnimation { duration: AxoraMotion.fast } }
                                }
                                MouseArea { id: clearH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: AxoraState.clearNotifs() }
                            }
                        }
                    }

                    Repeater {
                        model: AxoraState.notifList.slice(0, 4)
                        Item {
                            required property var modelData
                            required property int index
                            width: parent.width; height: 36

                            Rectangle {
                                id: nBg
                                anchors.fill: parent; radius: 8
                                color: rowN.containsMouse ? AxoraMaterials.surface2 : AxoraMaterials.surface0
                                Behavior on color { ColorAnimation { duration: AxoraMotion.fast } }
                            }
                            MouseArea {
                                id: rowN
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AxoraState.openNotification(index)
                            }
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 6; anchors.rightMargin: 6
                                spacing: 8
                                Rectangle {
                                    width: 24; height: 24; radius: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: AxoraMaterials.surface0
                                    Text {
                                        anchors.centerIn: parent
                                        text: (modelData.app || "?").charAt(0).toUpperCase()
                                        color: AxoraTheme.accent
                                        font.family: AxoraTheme.fontUI; font.bold: true
                                        font.pixelSize: Math.round(10 * AxoraState.fontScale)
                                    }
                                }
                                Column {
                                    width: parent.width - 32
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        text: modelData.app || "System"; elide: Text.ElideRight
                                        color: AxoraTheme.accent; font.family: AxoraTheme.fontUI; font.bold: true
                                        font.pixelSize: Math.round(8 * AxoraState.fontScale)
                                    }
                                    Text {
                                        text: modelData.summary; elide: Text.ElideRight
                                        color: AxoraTheme.text; font.family: AxoraTheme.fontUI
                                        font.pixelSize: Math.round(9 * AxoraState.fontScale); maximumLineCount: 1
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: AxoraState.notifList.length === 0
                        text: "All clear"; color: AxoraTheme.muted
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale)
                        padding: 6
                    }
                    Text {
                        visible: AxoraState.notifList.length > 4
                        text: "+ " + (AxoraState.notifList.length - 4) + " more"; color: AxoraTheme.muted
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                        padding: 4
                    }
                }

                // ── tailscale (click the header to draw down the peer list; toggle mesh) ──
                Rectangle {
                    width: parent.width
                    height: tsCol.implicitHeight + 2 * AxoraMetrics.m
                    radius: AxoraMetrics.radiusMd
                    color: AxoraMaterials.surface2
                    Column {
                        id: tsCol
                        anchors.fill: parent
                        anchors.margins: AxoraMetrics.m
                        spacing: AxoraMetrics.xs

                        Item {
                            width: parent.width
                            height: tsHead.implicitHeight
                            RowLayout {
                                id: tsHead
                                width: parent.width
                                spacing: AxoraMetrics.s
                                Item {
                                    Layout.preferredWidth: 22; Layout.preferredHeight: 18
                                    Text {
                                        anchors.centerIn: parent; text: "\uDB81\uDC8B"
                                        color: !AxoraState.tsUp ? AxoraTheme.danger :
                                               AxoraState.tsPeers.some(p => p.online) ? AxoraTheme.accent : AxoraTheme.muted
                                        font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(15 * AxoraState.fontScale)
                                    }
                                }
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Tailscale"; color: AxoraTheme.text
                                        font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(10 * AxoraState.fontScale)
                                    }
                                    Text {
                                        text: tsSubtitle(); color: AxoraTheme.muted; elide: Text.ElideRight
                                        width: parent.width
                                        font.pixelSize: Math.round(8 * AxoraState.fontScale); font.family: AxoraTheme.fontUI
                                    }
                                }
                                Text {
                                    text: "\uDB80\uDD40"; color: AxoraTheme.muted
                                    font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(11 * AxoraState.fontScale)
                                    rotation: tsOpen ? 180 : 0
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: tsOpen = !tsOpen
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        Item {
                            width: parent.width; height: 1
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                            }
                            visible: tsOpen
                        }
                        Repeater {
                            model: AxoraState.tsPeers
                            visible: tsOpen
                            Row {
                                required property var modelData
                                width: parent.width
                                height: 22
                                spacing: 6
                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.online ? AxoraTheme.accent : AxoraTheme.tint(AxoraTheme.muted, "66")
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 150
                                    text: modelData.name
                                    color: modelData.online ? AxoraTheme.text : AxoraTheme.muted
                                    font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale)
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 46
                                    text: modelData.online ? "" : "off"
                                    horizontalAlignment: Text.AlignRight
                                    color: AxoraTheme.muted
                                    font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 66
                                    horizontalAlignment: Text.AlignRight
                                    text: modelData.ip
                                    color: AxoraTheme.tint(AxoraTheme.muted, "99")
                                    font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        Text {
                            visible: tsOpen && AxoraState.tsPeers.length === 0
                            text: "No peers"; color: AxoraTheme.muted
                            font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                        }
                        RowLayout {
                            width: parent.width
                            visible: tsOpen
                            spacing: AxoraMetrics.s
                            Text {
                                text: "Mesh"; color: AxoraState.tsUp ? AxoraTheme.accent : AxoraTheme.muted
                                font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale); font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            TogglePill {
                                on: AxoraState.tsUp
                                onToggled: AxoraState.setTailscale(!AxoraState.tsUp)
                            }
                        }
                    }
                }


                // ── Power profile row ──
            CapsuleModule {
                width: parent.width
                // subtitle = the profile the CPU is ACTUALLY running. On battery the daemon
                // forces "battery" regardless of the saved choice, so showing the saved
                // value here would be wrong. Highlight stays on the saved choice so you
                // can still see which AC profile comes back when you plug in.
                icon: "\uDB81\uDCC5"; title: "Power profile"
                subtitle: (AxoraState.acSource === "battery" && AxoraState.powerProfileLive !== AxoraState.powerProfile
                        ? AxoraState.powerProfileLive + " (on battery)"
                        : AxoraState.powerProfileLive)
                Row {
                    spacing: AxoraMetrics.s
                    Repeater {
                        model: [
                            { key: "power-saver", label: "Silent" },
                            { key: "balanced", label: "Balanced" },
                            { key: "performance", label: "Perf" }
                        ]
                        Rectangle {
                            required property var modelData
                            readonly property bool active: AxoraState.powerProfile === modelData.key
                            width: 52; height: 24; radius: 8
                            color: hP.containsMouse ? AxoraMaterials.surface0 : (active ? AxoraMaterials.surface0 : "transparent")
                            border.color: active ? AxoraMaterials.borderActive : "transparent"; border.width: 1
                            Text { anchors.centerIn: parent; text: modelData.label; color: active ? AxoraTheme.text : AxoraTheme.muted; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale) }
                            MouseArea { id: hP; anchors.fill: parent; hoverEnabled: true; onClicked: AxoraState.setPowerProfile(modelData.key); cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

        }
    }
    }
}