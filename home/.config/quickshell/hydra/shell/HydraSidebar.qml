// HYDRA Sidebar — control center, iNiR-style.
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

    visible: HydraState.panelOpen
    anchors { right: true; top: true; bottom: true }
    // iNiR floating island — generous margin off the edge
    margins { top: 16; bottom: 16; right: 16 }

    implicitWidth: HydraMetrics.sidebarW
    exclusiveZone: HydraMetrics.sidebarW + 16
    color: "transparent"
    focusable: true

    property bool exiting: false
    property bool netOpen: false
    property bool btOpen: false
    property bool cafOpen: false
    property bool tsOpen: false
    function close() { exiting = true; HydraState.panelOpen = false }
    onVisibleChanged: if (visible) { exiting = false; HydraState.refreshNotifs() }

    function tsSubtitle() {
        if (!HydraState.tsUp) return "Off"
        const on = HydraState.tsPeers.filter(p => p.online).length
        const tot = HydraState.tsPeers.length
        return !tot ? HydraState.tsSelfIp : "self " + HydraState.tsSelfName + "  " + HydraState.tsSelfIp + "  ·  " + on + "/" + tot + " online"
    }

    function caffeineLabel() {
        const m = HydraState.caffeineMin
        if (m === -1) return "On (never idle)"
        if (m === 0) return "Off"
        return "On for " + m + " min"
    }

    // ── iOS-style switch (accent on-state track, follows theme/wallpaper accent) ──
    component TogglePill: Rectangle {
        property bool on: false
        signal toggled()
        width: 44; height: 24; radius: 12
        color: on ? HydraTheme.accent : HydraTheme.tint(HydraTheme.muted, "2e")
        border.color: on ? HydraMaterials.borderActive : "transparent"; border.width: 1
        Rectangle {
            x: on ? width - 21 : 2; width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: HydraTheme.text
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
        color: HydraMaterials.surface0
        Rectangle {
            width: Math.max(parent.height, parent.width * (slider.value / 100))
            height: parent.height; radius: parent.radius
            color: HydraTheme.accent
            // The value is optimistic (setVolume/setBrightness write volPct before
            // the command lands), so without this the fill SNAPS to the new width
            // and then jitters back when the 1s poller corrects it.
            Behavior on width {
                NumberAnimation { duration: HydraMotion.fast; easing.type: Easing.OutCubic }
            }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: HydraMetrics.m + 2; anchors.rightMargin: HydraMetrics.m
            Text {
                text: slider.glyphOpen ? "\uDB80\uDD40" : slider.glyph
                font.family: HydraTheme.fontMono
                font.pixelSize: Math.round(15 * HydraState.fontScale)
                color: HydraTheme.textOnAccent
                rotation: slider.glyphOpen ? 180 : 0
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(slider.value) + "%"
                font.family: HydraTheme.fontUI
                font.pixelSize: Math.round(11 * HydraState.fontScale)
                color: HydraTheme.muted
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
        property color iconColor: HydraTheme.muted
        property string title: ""
        property string subtitle: ""
        property bool subVisible: subtitle.length > 0
        property bool loud: false
        default property alias content: controlArea.data
        implicitHeight: 56
        width: parent ? parent.width : 340
        Rectangle {
            anchors.fill: parent
            radius: HydraMetrics.radiusMd
            color: HydraMaterials.surface2
            Rectangle {
                visible: cap.loud
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: 3
                color: HydraTheme.accent
                radius: 2
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: HydraMetrics.m; anchors.rightMargin: HydraMetrics.m
                spacing: HydraMetrics.s
                Item {
                    Layout.preferredWidth: 30; Layout.preferredHeight: 24
                    Text {
                        anchors.centerIn: parent; text: cap.icon
                        color: cap.loud ? HydraTheme.accent : cap.iconColor
                        font.family: HydraTheme.fontMono; font.pixelSize: Math.round(15 * HydraState.fontScale)
                    }
                }
                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: cap.title; color: HydraTheme.text
                        font.family: HydraTheme.fontUI; font.pixelSize: Math.round(10 * HydraState.fontScale)
                    }
                    Text {
                        visible: cap.subVisible
                        text: cap.subtitle; color: HydraTheme.muted; elide: Text.ElideRight
                        width: parent.width
                        font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
                    }
                }
                Row {
                    id: controlArea
                    Layout.preferredWidth: 172
                    spacing: HydraMetrics.xs
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
        color: active ? HydraTheme.accent : HydraMaterials.surface2
        border.color: isOpen ? HydraMaterials.borderActive : "transparent"; border.width: 1
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
                text: pill.icon; color: pill.active ? HydraTheme.textOnAccent : HydraTheme.text
                font.family: HydraTheme.fontMono; font.pixelSize: Math.round(12 * HydraState.fontScale)
            }
            Text {
                Layout.fillWidth: true
                text: pill.label; elide: Text.ElideRight
                color: pill.active ? HydraTheme.textOnAccent : HydraTheme.muted
                font.family: HydraTheme.fontUI; font.pixelSize: Math.round(9 * HydraState.fontScale)
            }
            Text {
                Layout.rightMargin: 8
                text: pill.drawerGlyph
                color: pill.isOpen ? HydraTheme.textOnAccent : (pill.active ? HydraTheme.textOnAccent : HydraTheme.muted)
                font.family: HydraTheme.fontMono; font.pixelSize: Math.round(11 * HydraState.fontScale)
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
        radius: HydraMetrics.radiusXl
        color: HydraMaterials.panelGlass
        border.color: HydraMaterials.borderFaint
        border.width: 1
        focus: true
        Keys.onEscapePressed: root.close()
        transformOrigin: Item.Right
        scale: 1
        opacity: 1
        Behavior on scale { NumberAnimation { duration: HydraMotion.panel; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: HydraMotion.panel; easing.type: Easing.OutCubic } }
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
            radius: HydraMetrics.radiusXl
            color: "transparent"
            clip: true
            readonly property int heroBannerH: 96

            // wallpaper banner — full bleed, clipped by the card's top radius
            Rectangle {
                id: heroBanner
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: heroCard.heroBannerH
                radius: HydraMetrics.radiusXl
                color: HydraTheme.field
                Image {
                    id: heroImg
                    anchors.fill: parent
                    source: (function() {
                        const p = HydraState.activeMediaPath
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
                        radius: HydraMetrics.radiusXl
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

            // brand — hydra cobra logo, vertically centered with the name/subtitle block
            Rectangle {
                id: heroAvatar
                x: HydraMetrics.m
                anchors.verticalCenter: footerRail.verticalCenter
                width: 34; height: 34
                color: "transparent"
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorizationColor: HydraTheme.accent
                    colorization: 1.0
                }
                Image {
                    anchors.fill: parent
                    anchors.margins: 3
                    source: "file://StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/hypr/assets/hydra-logo.png""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false
                }
            }

            // identity — bold name + username·context·uptime, right of avatar in the footer
            Column {
                x: HydraMetrics.m + 34 + HydraMetrics.s
                anchors.verticalCenter: footerRail.verticalCenter
                width: parent.width - (HydraMetrics.m + 34 + HydraMetrics.s) - 70
                spacing: 2
                Text { text: "HYDRA SAMO"; color: HydraTheme.text; font.family: HydraTheme.fontUI; font.pixelSize: Math.round(14 * HydraState.fontScale); font.bold: true; elide: Text.ElideRight; width: parent.width }
                Text { text: HydraState.uptimeLine; color: HydraTheme.muted; font.family: HydraTheme.fontMono; font.pixelSize: Math.round(9 * HydraState.fontScale); elide: Text.ElideRight; width: parent.width }
            }

            // header actions — power + settings, right-aligned in the footer band
            Row {
                anchors.right: parent.right; anchors.rightMargin: HydraMetrics.s
                anchors.verticalCenter: footerRail.verticalCenter
                spacing: HydraMetrics.s
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: powHead.containsMouse ? HydraMaterials.surface2 : "transparent"
                    Behavior on color { ColorAnimation { duration: HydraMotion.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "\uDB81\uDC25"
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(12 * HydraState.fontScale)
                        color: HydraTheme.muted
                    }
                    MouseArea {
                        id: powHead
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.close(); HydraState.powerOpen = true }
                    }
                }
                Rectangle {
                    id: gearBtn
                    width: 26; height: 26; radius: 13
                    color: gearHover.containsMouse ? HydraMaterials.surface2 : "transparent"
                    Behavior on color { ColorAnimation { duration: HydraMotion.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "\uDB81\uDC93"
                        font.family: HydraTheme.fontMono
                        font.pixelSize: Math.round(12 * HydraState.fontScale)
                        color: HydraTheme.muted
                    }
                    MouseArea {
                        id: gearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.close(); HydraState.settingsOpen = true }
                    }
                }
            }

            // live wallpaper refresh — nudge the Image when the poster regenerates
            Connections {
                target: WallpaperStore
                function onPosterGenerated(path) {
                    if (path === WallpaperStore.cachedPosterPath(HydraState.activeMediaPath)) {
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
            anchors.leftMargin: HydraMetrics.xl   // iNiR signature: 24px internal padding
            anchors.rightMargin: HydraMetrics.xl
            anchors.bottomMargin: HydraMetrics.xl
            anchors.topMargin: HydraMetrics.l
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: bodyCol.implicitHeight

            Column {
                id: bodyCol
                width: parent.width
                spacing: HydraMetrics.l

                // ── quick pills: Wi-Fi / Bluetooth / Caffeine + one shared drawer ──
                Column {
                    width: parent.width
                    spacing: HydraMetrics.s

                    Row {
                        width: parent.width
                        spacing: HydraMetrics.s
                        PillCapsule {
                            width: (parent.width - 3 * HydraMetrics.s) / 4
                            icon: HydraState.isOn("wifi") ? HydraState.wifiIcon(HydraState.wifiSig) : "\uDB81\uDDAA"; label: "Wi-Fi"
                            active: HydraState.isOn("wifi")
                            isOpen: netOpen
                            onToggled: HydraState.toggleKey("wifi")
                            onClicked: { netOpen = !netOpen; btOpen = false; cafOpen = false; if (netOpen) HydraState.refreshWifi() }
                        }
                        PillCapsule {
                            width: (parent.width - 3 * HydraMetrics.s) / 4
                            icon: "\uDB80\uDCAF"; label: "Bluetooth"
                            active: HydraState.isOn("bt")
                            isOpen: btOpen
                            onToggled: HydraState.toggleKey("bt")
                            onClicked: { btOpen = !btOpen; netOpen = false; cafOpen = false; if (btOpen) HydraState.refreshBt() }
                        }
                        PillCapsule {
                            width: (parent.width - 3 * HydraMetrics.s) / 4
                            icon: "󰅶"; label: "Caffeine"
                            active: HydraState.caffeineMin !== 0
                            isOpen: cafOpen
                            onToggled: HydraState.setCaffeine(HydraState.caffeineMin !== 0 ? 0 : -1)
                            onClicked: { cafOpen = !cafOpen; netOpen = false; btOpen = false }
                        }
                        PillCapsule {
                            width: (parent.width - 3 * HydraMetrics.s) / 4
                            icon: "\uDB80\uDE96"; label: "Game"
                            active: HydraState.gameModeOn
                            drawerGlyph: ""
                            onToggled: HydraState.toggleGameMode()
                            onClicked: HydraState.toggleGameMode()
                        }
                    }

                    // shared drawer — one small card dropping below the pills
                    Item {
                        width: parent.width
                        height: (netOpen ? netDrawer.height : btOpen ? btDrawer.height : cafOpen ? cafDrawer.height : 0)
                        clip: true
                        Rectangle {
                            id: netDrawer
                            width: parent.width; height: Math.max(40, Math.min(116, 6 + HydraState.wifiList.length * 27) + 8)
                            visible: netOpen
                            radius: HydraMetrics.radiusMd
                            color: HydraMaterials.surface2
                            ListView {
                                anchors.fill: parent; anchors.margins: 4
                                model: HydraState.wifiList
                                clip: true
                                delegate: Rectangle {
                                    id: wifiRow
                                    required property var modelData
                                    width: ListView.view.width; height: 27; radius: 7
                                    color: rowH.containsMouse ? HydraMaterials.surface0 : (modelData.use ? HydraTheme.accentDim : "transparent")
                                    MouseArea { id: rowH; anchors.fill: parent; hoverEnabled: true; onClicked: HydraState.exec("hydra-wifi-connect \"" + modelData.ssid + "\" \"" + modelData.sec + "\""); cursorShape: Qt.PointingHandCursor }
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                        Text {
                                            text: modelData.use ? "\uDB80\uDD2C" : (modelData.sec ? "\uDB80\uDF3E" : "\uDB81\uDDA9")
                                            color: modelData.use ? HydraTheme.accent : HydraTheme.muted
                                            font.family: HydraTheme.fontMono; font.pixelSize: Math.round(10 * HydraState.fontScale)
                                        }
                                        Text {
                                            text: modelData.ssid; elide: Text.ElideMiddle
                                            color: HydraTheme.text
                                            font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
                                        }
                                        Text {
                                            text: HydraState.wifiIcon(modelData.sig)
                                            color: HydraTheme.muted; font.family: HydraTheme.fontMono; font.pixelSize: Math.round(9 * HydraState.fontScale)
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: HydraState.wifiList.length === 0
                                anchors.centerIn: parent; text: "Scanning…"
                                color: HydraTheme.muted; font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
                            }
                        }
                        Rectangle {
                            id: btDrawer
                            width: parent.width; height: Math.max(40, Math.min(116, 6 + HydraState.btDevices.length * 27) + 8)
                            visible: btOpen
                            radius: HydraMetrics.radiusMd
                            color: HydraMaterials.surface2
                            ListView {
                                anchors.fill: parent; anchors.margins: 4
                                model: HydraState.btDevices
                                clip: true
                                delegate: Rectangle {
                                    id: btRow
                                    required property var modelData
                                    width: ListView.view.width; height: 27; radius: 7
                                    color: rowBh.containsMouse ? HydraMaterials.surface0 : (modelData.connected ? HydraTheme.accentDim : "transparent")
                                    MouseArea { id: rowBh; anchors.fill: parent; hoverEnabled: true; onClicked: HydraState.toggleBtDevice(modelData.mac, modelData.connected); cursorShape: Qt.PointingHandCursor }
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                        Text {
                                            text: modelData.connected ? "\uDB80\uDD2C" : "\uDB80\uDCAF"
                                            color: modelData.connected ? HydraTheme.accent : HydraTheme.muted
                                            font.family: HydraTheme.fontMono; font.pixelSize: Math.round(10 * HydraState.fontScale)
                                        }
                                        Text {
                                            text: modelData.name; elide: Text.ElideMiddle; color: HydraTheme.text
                                            font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: HydraState.btDevices.length === 0
                                anchors.centerIn: parent; text: "No paired devices"
                                color: HydraTheme.muted; font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
                            }
                        }
                        Rectangle {
                            id: cafDrawer
                            width: parent.width; height: 36
                            visible: cafOpen
                            radius: HydraMetrics.radiusMd
                            color: HydraMaterials.surface2
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
                                        color: hC.containsMouse ? HydraMaterials.surface0 : (HydraState.caffeineMin === modelData.min ? HydraTheme.accentDim : "transparent")
                                        border.color: HydraState.caffeineMin === modelData.min ? HydraMaterials.borderActive : "transparent"; border.width: 1
                                        Text { anchors.centerIn: parent; text: modelData.label; color: HydraState.caffeineMin === modelData.min ? HydraTheme.text : HydraTheme.muted; font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale) }
                                        MouseArea { id: hC; anchors.fill: parent; hoverEnabled: true; onClicked: HydraState.setCaffeine(modelData.min); cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── audio & display (soft pill sliders + audio I/O drawer) ──
                Column {
                    width: parent.width
                    spacing: HydraMetrics.s

                    Rectangle {
                        width: parent.width
                        height: sliderCol.implicitHeight + 2 * HydraMetrics.m
                        radius: HydraMetrics.radiusMd
                        color: HydraMaterials.surface2
                        property bool audioOpen: false
                        Behavior on height { NumberAnimation { duration: HydraMotion.transition; easing.type: Easing.OutCubic } }

                        Column {
                            id: sliderCol
                            anchors.fill: parent
                            anchors.margins: HydraMetrics.m
                            spacing: HydraMetrics.m

                            PillSlider {
                                width: parent.width
                                glyph: "\uDB81\uDDA8"
                                value: HydraState.briPct
                                onMoved: (pct) => HydraState.setBrightness(pct)
                            }
                            PillSlider {
                                width: parent.width
                                glyph: HydraState.volPct === 0 ? "\uDB81\uDD81" : HydraState.volPct < 33 ? "\uDB81\uDD7F" : HydraState.volPct < 66 ? "\uDB81\uDD80" : "\uDB81\uDD7E"
                                value: HydraState.volPct
                                glyphClickable: true
                                glyphOpen: parent.parent.audioOpen
                                onGlyphClicked: parent.parent.audioOpen = !parent.parent.audioOpen
                                onMoved: (pct) => HydraState.setVolume(pct)
                            }

                            // audio I/O drawer — drops from the volume glyph (no standalone card)
                            Column {
                                visible: parent.parent.audioOpen
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: HydraState.audioSinks
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width; height: 26; radius: 7
                                        color: rowS.containsMouse ? HydraMaterials.surface0 : (modelData.default ? HydraTheme.accentDim : "transparent")
                                        MouseArea {
                                            id: rowS; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { parent.parent.parent.parent.audioOpen = false; HydraState.setAudioOutput(modelData.id) }
                                        }
                                        Row {
                                            width: parent.width
                                            anchors.verticalCenter: parent.verticalCenter; spacing: 6; leftPadding: 6
                                            Text {
                                                text: modelData.default ? "\uDB80\uDD2C" : "\uDB81\uDD7E"
                                                color: modelData.default ? HydraTheme.accent : HydraTheme.muted
                                                font.family: HydraTheme.fontMono; font.pixelSize: Math.round(10 * HydraState.fontScale)
                                            }
                                            Text {
                                                width: parent.width - 66
                                                text: modelData.label; elide: Text.ElideMiddle
                                                color: HydraTheme.text; font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
                                            }
                                        }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "transparent" }
                                Text {
                                    text: "Input"; color: HydraTheme.muted
                                    font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale); font.bold: true
                                }
                                Repeater {
                                    model: HydraState.audioSources
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width; height: 26; radius: 7
                                        color: rowI.containsMouse ? HydraMaterials.surface0 : (modelData.default ? HydraTheme.accentDim : "transparent")
                                        MouseArea {
                                            id: rowI; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { parent.parent.parent.parent.audioOpen = false; HydraState.setAudioInput(modelData.id) }
                                        }
                                        Row {
                                            width: parent.width
                                            anchors.verticalCenter: parent.verticalCenter; spacing: 6; leftPadding: 6
                                            Text {
                                                text: modelData.default ? "\uDB80\uDD2C" : "\uDB80\uDF6C"
                                                color: modelData.default ? HydraTheme.accent : HydraTheme.muted
                                                font.family: HydraTheme.fontMono; font.pixelSize: Math.round(10 * HydraState.fontScale)
                                            }
                                            Text {
                                                width: parent.width - 66
                                                text: modelData.label; elide: Text.ElideMiddle
                                                color: HydraTheme.text; font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
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
                    spacing: HydraMetrics.s

                    // header — left: bell + title | right: count badge + clear
                    Item {
                        width: parent.width; height: 24

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 7
                            Text {
                                text: "\uDB80\uDC9A"; color: HydraTheme.accent
                                font.family: HydraTheme.fontMono; font.pixelSize: Math.round(12 * HydraState.fontScale)
                            }
                            Text {
                                text: "Notifications"; color: HydraTheme.text
                                font.family: HydraTheme.fontUI; font.pixelSize: Math.round(10 * HydraState.fontScale); font.bold: true
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Rectangle {
                                visible: HydraState.notifList.length > 0
                                width: 20; height: 20; radius: 10
                                color: HydraTheme.accent
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: HydraState.notifList.length
                                    color: HydraTheme.textOnAccent
                                    font.family: HydraTheme.fontMono; font.bold: true
                                    font.pixelSize: Math.round(9 * HydraState.fontScale)
                                }
                            }
                            Item {
                                width: 20; height: 20
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uDB80\uDD56"; color: clearH.containsMouse ? HydraTheme.accent : HydraTheme.muted
                                    font.family: HydraTheme.fontMono; font.pixelSize: Math.round(11 * HydraState.fontScale)
                                    Behavior on color { ColorAnimation { duration: HydraMotion.fast } }
                                }
                                MouseArea { id: clearH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: HydraState.clearNotifs() }
                            }
                        }
                    }

                    Repeater {
                        model: HydraState.notifList.slice(0, 4)
                        Item {
                            required property var modelData
                            required property int index
                            width: parent.width; height: 36

                            Rectangle {
                                id: nBg
                                anchors.fill: parent; radius: 8
                                color: rowN.containsMouse ? HydraMaterials.surface2 : HydraMaterials.surface0
                                Behavior on color { ColorAnimation { duration: HydraMotion.fast } }
                            }
                            MouseArea {
                                id: rowN
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: HydraState.openNotification(index)
                            }
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 6; anchors.rightMargin: 6
                                spacing: 8
                                Rectangle {
                                    width: 24; height: 24; radius: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: HydraMaterials.surface0
                                    Text {
                                        anchors.centerIn: parent
                                        text: (modelData.app || "?").charAt(0).toUpperCase()
                                        color: HydraTheme.accent
                                        font.family: HydraTheme.fontUI; font.bold: true
                                        font.pixelSize: Math.round(10 * HydraState.fontScale)
                                    }
                                }
                                Column {
                                    width: parent.width - 32
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        text: modelData.app || "System"; elide: Text.ElideRight
                                        color: HydraTheme.accent; font.family: HydraTheme.fontUI; font.bold: true
                                        font.pixelSize: Math.round(8 * HydraState.fontScale)
                                    }
                                    Text {
                                        text: modelData.summary; elide: Text.ElideRight
                                        color: HydraTheme.text; font.family: HydraTheme.fontUI
                                        font.pixelSize: Math.round(9 * HydraState.fontScale); maximumLineCount: 1
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: HydraState.notifList.length === 0
                        text: "All clear"; color: HydraTheme.muted
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: HydraTheme.fontUI; font.pixelSize: Math.round(9 * HydraState.fontScale)
                        padding: 6
                    }
                    Text {
                        visible: HydraState.notifList.length > 4
                        text: "+ " + (HydraState.notifList.length - 4) + " more"; color: HydraTheme.muted
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
                        padding: 4
                    }
                }

                // ── tailscale (click the header to draw down the peer list; toggle mesh) ──
                Rectangle {
                    width: parent.width
                    height: tsCol.implicitHeight + 2 * HydraMetrics.m
                    radius: HydraMetrics.radiusMd
                    color: HydraMaterials.surface2
                    Column {
                        id: tsCol
                        anchors.fill: parent
                        anchors.margins: HydraMetrics.m
                        spacing: HydraMetrics.xs

                        Item {
                            width: parent.width
                            height: tsHead.implicitHeight
                            RowLayout {
                                id: tsHead
                                width: parent.width
                                spacing: HydraMetrics.s
                                Item {
                                    Layout.preferredWidth: 22; Layout.preferredHeight: 18
                                    Text {
                                        anchors.centerIn: parent; text: "\uDB81\uDC8B"
                                        color: !HydraState.tsUp ? HydraTheme.danger :
                                               HydraState.tsPeers.some(p => p.online) ? HydraTheme.accent : HydraTheme.muted
                                        font.family: HydraTheme.fontMono; font.pixelSize: Math.round(15 * HydraState.fontScale)
                                    }
                                }
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Tailscale"; color: HydraTheme.text
                                        font.family: HydraTheme.fontUI; font.pixelSize: Math.round(10 * HydraState.fontScale)
                                    }
                                    Text {
                                        text: tsSubtitle(); color: HydraTheme.muted; elide: Text.ElideRight
                                        width: parent.width
                                        font.pixelSize: Math.round(8 * HydraState.fontScale); font.family: HydraTheme.fontUI
                                    }
                                }
                                Text {
                                    text: "\uDB80\uDD40"; color: HydraTheme.muted
                                    font.family: HydraTheme.fontMono; font.pixelSize: Math.round(11 * HydraState.fontScale)
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
                            model: HydraState.tsPeers
                            visible: tsOpen
                            Row {
                                required property var modelData
                                width: parent.width
                                height: 22
                                spacing: 6
                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.online ? HydraTheme.accent : HydraTheme.tint(HydraTheme.muted, "66")
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 150
                                    text: modelData.name
                                    color: modelData.online ? HydraTheme.text : HydraTheme.muted
                                    font.family: HydraTheme.fontUI; font.pixelSize: Math.round(9 * HydraState.fontScale)
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 46
                                    text: modelData.online ? "" : "off"
                                    horizontalAlignment: Text.AlignRight
                                    color: HydraTheme.muted
                                    font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 66
                                    horizontalAlignment: Text.AlignRight
                                    text: modelData.ip
                                    color: HydraTheme.tint(HydraTheme.muted, "99")
                                    font.family: HydraTheme.fontMono; font.pixelSize: Math.round(8 * HydraState.fontScale)
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        Text {
                            visible: tsOpen && HydraState.tsPeers.length === 0
                            text: "No peers"; color: HydraTheme.muted
                            font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale)
                        }
                        RowLayout {
                            width: parent.width
                            visible: tsOpen
                            spacing: HydraMetrics.s
                            Text {
                                text: "Mesh"; color: HydraState.tsUp ? HydraTheme.accent : HydraTheme.muted
                                font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale); font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            TogglePill {
                                on: HydraState.tsUp
                                onToggled: HydraState.setTailscale(!HydraState.tsUp)
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
                subtitle: (HydraState.acSource === "battery" && HydraState.powerProfileLive !== HydraState.powerProfile
                        ? HydraState.powerProfileLive + " (on battery)"
                        : HydraState.powerProfileLive)
                Row {
                    spacing: HydraMetrics.s
                    Repeater {
                        model: [
                            { key: "power-saver", label: "Silent" },
                            { key: "balanced", label: "Balanced" },
                            { key: "performance", label: "Perf" }
                        ]
                        Rectangle {
                            required property var modelData
                            readonly property bool active: HydraState.powerProfile === modelData.key
                            width: 52; height: 24; radius: 8
                            color: hP.containsMouse ? HydraMaterials.surface0 : (active ? HydraMaterials.surface0 : "transparent")
                            border.color: active ? HydraMaterials.borderActive : "transparent"; border.width: 1
                            Text { anchors.centerIn: parent; text: modelData.label; color: active ? HydraTheme.text : HydraTheme.muted; font.family: HydraTheme.fontUI; font.pixelSize: Math.round(8 * HydraState.fontScale) }
                            MouseArea { id: hP; anchors.fill: parent; hoverEnabled: true; onClicked: HydraState.setPowerProfile(modelData.key); cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

        }
    }
    }
}