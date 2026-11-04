// VALKYX Sidebar — control center, iNiR-style.
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

    visible: ValkyxState.panelOpen
    anchors { right: true; top: true; bottom: true }
    // iNiR floating island — generous margin off the edge
    margins { top: 16; bottom: 16; right: 16 }

    implicitWidth: ValkyxMetrics.sidebarW
    exclusiveZone: ValkyxMetrics.sidebarW + 16
    color: "transparent"
    focusable: true

    property bool exiting: false
    property bool netOpen: false
    property bool btOpen: false
    property bool cafOpen: false
    property bool tsOpen: false
    function close() { exiting = true; ValkyxState.panelOpen = false }
    onVisibleChanged: if (visible) { exiting = false; ValkyxState.refreshNotifs() }

    function tsSubtitle() {
        if (!ValkyxState.tsUp) return "Off"
        const on = ValkyxState.tsPeers.filter(p => p.online).length
        const tot = ValkyxState.tsPeers.length
        return !tot ? ValkyxState.tsSelfIp : "self " + ValkyxState.tsSelfName + "  " + ValkyxState.tsSelfIp + "  ·  " + on + "/" + tot + " online"
    }

    function caffeineLabel() {
        const m = ValkyxState.caffeineMin
        if (m === -1) return "On (never idle)"
        if (m === 0) return "Off"
        return "On for " + m + " min"
    }

    // ── iOS-style switch (accent on-state track, follows theme/wallpaper accent) ──
    component TogglePill: Rectangle {
        property bool on: false
        signal toggled()
        width: 44; height: 24; radius: 12
        color: on ? ValkyxTheme.accent : ValkyxTheme.tint(ValkyxTheme.muted, "2e")
        border.color: on ? ValkyxMaterials.borderActive : "transparent"; border.width: 1
        Rectangle {
            x: on ? width - 21 : 2; width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: ValkyxTheme.text
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
        color: ValkyxMaterials.surface0
        Rectangle {
            width: Math.max(parent.height, parent.width * (slider.value / 100))
            height: parent.height; radius: parent.radius
            color: ValkyxTheme.accent
            // The value is optimistic (setVolume/setBrightness write volPct before
            // the command lands), so without this the fill SNAPS to the new width
            // and then jitters back when the 1s poller corrects it.
            Behavior on width {
                NumberAnimation { duration: ValkyxMotion.fast; easing.type: Easing.OutCubic }
            }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ValkyxMetrics.m + 2; anchors.rightMargin: ValkyxMetrics.m
            Text {
                text: slider.glyphOpen ? "\uDB80\uDD40" : slider.glyph
                font.family: ValkyxTheme.fontMono
                font.pixelSize: Math.round(15 * ValkyxState.fontScale)
                color: ValkyxTheme.textOnAccent
                rotation: slider.glyphOpen ? 180 : 0
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(slider.value) + "%"
                font.family: ValkyxTheme.fontUI
                font.pixelSize: Math.round(11 * ValkyxState.fontScale)
                color: ValkyxTheme.muted
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
        property color iconColor: ValkyxTheme.muted
        property string title: ""
        property string subtitle: ""
        property bool subVisible: subtitle.length > 0
        property bool loud: false
        default property alias content: controlArea.data
        implicitHeight: 56
        width: parent ? parent.width : 340
        Rectangle {
            anchors.fill: parent
            radius: ValkyxMetrics.radiusMd
            color: ValkyxMaterials.surface2
            Rectangle {
                visible: cap.loud
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: 3
                color: ValkyxTheme.accent
                radius: 2
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: ValkyxMetrics.m; anchors.rightMargin: ValkyxMetrics.m
                spacing: ValkyxMetrics.s
                Item {
                    Layout.preferredWidth: 30; Layout.preferredHeight: 24
                    Text {
                        anchors.centerIn: parent; text: cap.icon
                        color: cap.loud ? ValkyxTheme.accent : cap.iconColor
                        font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(15 * ValkyxState.fontScale)
                    }
                }
                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: cap.title; color: ValkyxTheme.text
                        font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                    }
                    Text {
                        visible: cap.subVisible
                        text: cap.subtitle; color: ValkyxTheme.muted; elide: Text.ElideRight
                        width: parent.width
                        font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                    }
                }
                Row {
                    id: controlArea
                    Layout.preferredWidth: 172
                    spacing: ValkyxMetrics.xs
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
        color: active ? ValkyxTheme.accent : ValkyxMaterials.surface2
        border.color: isOpen ? ValkyxMaterials.borderActive : "transparent"; border.width: 1
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
                text: pill.icon; color: pill.active ? ValkyxTheme.textOnAccent : ValkyxTheme.text
                font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(12 * ValkyxState.fontScale)
            }
            Text {
                Layout.fillWidth: true
                text: pill.label; elide: Text.ElideRight
                color: pill.active ? ValkyxTheme.textOnAccent : ValkyxTheme.muted
                font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
            }
            Text {
                Layout.rightMargin: 8
                text: pill.drawerGlyph
                color: pill.isOpen ? ValkyxTheme.textOnAccent : (pill.active ? ValkyxTheme.textOnAccent : ValkyxTheme.muted)
                font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(11 * ValkyxState.fontScale)
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
        radius: ValkyxMetrics.radiusXl
        color: ValkyxMaterials.panelGlass
        border.color: ValkyxMaterials.borderFaint
        border.width: 1
        focus: true
        Keys.onEscapePressed: root.close()
        transformOrigin: Item.Right
        scale: 1
        opacity: 1
        Behavior on scale { NumberAnimation { duration: ValkyxMotion.panel; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: ValkyxMotion.panel; easing.type: Easing.OutCubic } }
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
            radius: ValkyxMetrics.radiusXl
            color: "transparent"
            clip: true
            readonly property int heroBannerH: 96

            // wallpaper banner — full bleed, clipped by the card's top radius
            Rectangle {
                id: heroBanner
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: heroCard.heroBannerH
                radius: ValkyxMetrics.radiusXl
                color: ValkyxTheme.field
                Image {
                    id: heroImg
                    anchors.fill: parent
                    source: (function() {
                        const p = ValkyxState.activeMediaPath
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
                        radius: ValkyxMetrics.radiusXl
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

            // brand — valkyx cobra logo, vertically centered with the name/subtitle block
            Rectangle {
                id: heroAvatar
                x: ValkyxMetrics.m
                anchors.verticalCenter: footerRail.verticalCenter
                width: 34; height: 34
                color: "transparent"
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorizationColor: ValkyxTheme.accent
                    colorization: 1.0
                }
                Image {
                    anchors.fill: parent
                    anchors.margins: 3
                    source: "file://StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/hypr/assets/valkyx-logo.png""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false
                }
            }

            // identity — bold name + username·context·uptime, right of avatar in the footer
            Column {
                x: ValkyxMetrics.m + 34 + ValkyxMetrics.s
                anchors.verticalCenter: footerRail.verticalCenter
                width: parent.width - (ValkyxMetrics.m + 34 + ValkyxMetrics.s) - 70
                spacing: 2
                Text { text: "VALKYX"; color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(14 * ValkyxState.fontScale); font.bold: true; elide: Text.ElideRight; width: parent.width }
                Text { text: ValkyxState.uptimeLine; color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(9 * ValkyxState.fontScale); elide: Text.ElideRight; width: parent.width }
            }

            // header actions — power + settings, right-aligned in the footer band
            Row {
                anchors.right: parent.right; anchors.rightMargin: ValkyxMetrics.s
                anchors.verticalCenter: footerRail.verticalCenter
                spacing: ValkyxMetrics.s
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: powHead.containsMouse ? ValkyxMaterials.surface2 : "transparent"
                    Behavior on color { ColorAnimation { duration: ValkyxMotion.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "\uDB81\uDC25"
                        font.family: ValkyxTheme.fontMono
                        font.pixelSize: Math.round(12 * ValkyxState.fontScale)
                        color: ValkyxTheme.muted
                    }
                    MouseArea {
                        id: powHead
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.close(); ValkyxState.powerOpen = true }
                    }
                }
                Rectangle {
                    id: gearBtn
                    width: 26; height: 26; radius: 13
                    color: gearHover.containsMouse ? ValkyxMaterials.surface2 : "transparent"
                    Behavior on color { ColorAnimation { duration: ValkyxMotion.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "\uDB81\uDC93"
                        font.family: ValkyxTheme.fontMono
                        font.pixelSize: Math.round(12 * ValkyxState.fontScale)
                        color: ValkyxTheme.muted
                    }
                    MouseArea {
                        id: gearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.close(); ValkyxState.settingsOpen = true }
                    }
                }
            }

            // live wallpaper refresh — nudge the Image when the poster regenerates
            Connections {
                target: WallpaperStore
                function onPosterGenerated(path) {
                    if (path === WallpaperStore.cachedPosterPath(ValkyxState.activeMediaPath)) {
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
            anchors.leftMargin: ValkyxMetrics.xl   // iNiR signature: 24px internal padding
            anchors.rightMargin: ValkyxMetrics.xl
            anchors.bottomMargin: ValkyxMetrics.xl
            anchors.topMargin: ValkyxMetrics.l
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: bodyCol.implicitHeight

            Column {
                id: bodyCol
                width: parent.width
                spacing: ValkyxMetrics.l

                // ── quick pills: Wi-Fi / Bluetooth / Caffeine + one shared drawer ──
                Column {
                    width: parent.width
                    spacing: ValkyxMetrics.s

                    Row {
                        width: parent.width
                        spacing: ValkyxMetrics.s
                        PillCapsule {
                            width: (parent.width - 3 * ValkyxMetrics.s) / 4
                            icon: ValkyxState.isOn("wifi") ? ValkyxState.wifiIcon(ValkyxState.wifiSig) : "\uDB81\uDDAA"; label: "Wi-Fi"
                            active: ValkyxState.isOn("wifi")
                            isOpen: netOpen
                            onToggled: ValkyxState.toggleKey("wifi")
                            onClicked: { netOpen = !netOpen; btOpen = false; cafOpen = false; if (netOpen) ValkyxState.refreshWifi() }
                        }
                        PillCapsule {
                            width: (parent.width - 3 * ValkyxMetrics.s) / 4
                            icon: "\uDB80\uDCAF"; label: "Bluetooth"
                            active: ValkyxState.isOn("bt")
                            isOpen: btOpen
                            onToggled: ValkyxState.toggleKey("bt")
                            onClicked: { btOpen = !btOpen; netOpen = false; cafOpen = false; if (btOpen) ValkyxState.refreshBt() }
                        }
                        PillCapsule {
                            width: (parent.width - 3 * ValkyxMetrics.s) / 4
                            icon: "󰅶"; label: "Caffeine"
                            active: ValkyxState.caffeineMin !== 0
                            isOpen: cafOpen
                            onToggled: ValkyxState.setCaffeine(ValkyxState.caffeineMin !== 0 ? 0 : -1)
                            onClicked: { cafOpen = !cafOpen; netOpen = false; btOpen = false }
                        }
                        PillCapsule {
                            width: (parent.width - 3 * ValkyxMetrics.s) / 4
                            icon: "\uDB80\uDE96"; label: "Game"
                            active: ValkyxState.gameModeOn
                            drawerGlyph: ""
                            onToggled: ValkyxState.toggleGameMode()
                            onClicked: ValkyxState.toggleGameMode()
                        }
                    }

                    // shared drawer — one small card dropping below the pills
                    Item {
                        width: parent.width
                        height: (netOpen ? netDrawer.height : btOpen ? btDrawer.height : cafOpen ? cafDrawer.height : 0)
                        clip: true
                        Rectangle {
                            id: netDrawer
                            width: parent.width; height: Math.max(40, Math.min(116, 6 + ValkyxState.wifiList.length * 27) + 8)
                            visible: netOpen
                            radius: ValkyxMetrics.radiusMd
                            color: ValkyxMaterials.surface2
                            ListView {
                                anchors.fill: parent; anchors.margins: 4
                                model: ValkyxState.wifiList
                                clip: true
                                delegate: Rectangle {
                                    id: wifiRow
                                    required property var modelData
                                    width: ListView.view.width; height: 27; radius: 7
                                    color: rowH.containsMouse ? ValkyxMaterials.surface0 : (modelData.use ? ValkyxTheme.accentDim : "transparent")
                                    MouseArea { id: rowH; anchors.fill: parent; hoverEnabled: true; onClicked: ValkyxState.exec("valkyx-wifi-connect \"" + modelData.ssid + "\" \"" + modelData.sec + "\""); cursorShape: Qt.PointingHandCursor }
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                        Text {
                                            text: modelData.use ? "\uDB80\uDD2C" : (modelData.sec ? "\uDB80\uDF3E" : "\uDB81\uDDA9")
                                            color: modelData.use ? ValkyxTheme.accent : ValkyxTheme.muted
                                            font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                                        }
                                        Text {
                                            text: modelData.ssid; elide: Text.ElideMiddle
                                            color: ValkyxTheme.text
                                            font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                                        }
                                        Text {
                                            text: ValkyxState.wifiIcon(modelData.sig)
                                            color: ValkyxTheme.muted; font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: ValkyxState.wifiList.length === 0
                                anchors.centerIn: parent; text: "Scanning…"
                                color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                            }
                        }
                        Rectangle {
                            id: btDrawer
                            width: parent.width; height: Math.max(40, Math.min(116, 6 + ValkyxState.btDevices.length * 27) + 8)
                            visible: btOpen
                            radius: ValkyxMetrics.radiusMd
                            color: ValkyxMaterials.surface2
                            ListView {
                                anchors.fill: parent; anchors.margins: 4
                                model: ValkyxState.btDevices
                                clip: true
                                delegate: Rectangle {
                                    id: btRow
                                    required property var modelData
                                    width: ListView.view.width; height: 27; radius: 7
                                    color: rowBh.containsMouse ? ValkyxMaterials.surface0 : (modelData.connected ? ValkyxTheme.accentDim : "transparent")
                                    MouseArea { id: rowBh; anchors.fill: parent; hoverEnabled: true; onClicked: ValkyxState.toggleBtDevice(modelData.mac, modelData.connected); cursorShape: Qt.PointingHandCursor }
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                        Text {
                                            text: modelData.connected ? "\uDB80\uDD2C" : "\uDB80\uDCAF"
                                            color: modelData.connected ? ValkyxTheme.accent : ValkyxTheme.muted
                                            font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                                        }
                                        Text {
                                            text: modelData.name; elide: Text.ElideMiddle; color: ValkyxTheme.text
                                            font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: ValkyxState.btDevices.length === 0
                                anchors.centerIn: parent; text: "No paired devices"
                                color: ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                            }
                        }
                        Rectangle {
                            id: cafDrawer
                            width: parent.width; height: 36
                            visible: cafOpen
                            radius: ValkyxMetrics.radiusMd
                            color: ValkyxMaterials.surface2
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
                                        color: hC.containsMouse ? ValkyxMaterials.surface0 : (ValkyxState.caffeineMin === modelData.min ? ValkyxTheme.accentDim : "transparent")
                                        border.color: ValkyxState.caffeineMin === modelData.min ? ValkyxMaterials.borderActive : "transparent"; border.width: 1
                                        Text { anchors.centerIn: parent; text: modelData.label; color: ValkyxState.caffeineMin === modelData.min ? ValkyxTheme.text : ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale) }
                                        MouseArea { id: hC; anchors.fill: parent; hoverEnabled: true; onClicked: ValkyxState.setCaffeine(modelData.min); cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── audio & display (soft pill sliders + audio I/O drawer) ──
                Column {
                    width: parent.width
                    spacing: ValkyxMetrics.s

                    Rectangle {
                        width: parent.width
                        height: sliderCol.implicitHeight + 2 * ValkyxMetrics.m
                        radius: ValkyxMetrics.radiusMd
                        color: ValkyxMaterials.surface2
                        property bool audioOpen: false
                        Behavior on height { NumberAnimation { duration: ValkyxMotion.transition; easing.type: Easing.OutCubic } }

                        Column {
                            id: sliderCol
                            anchors.fill: parent
                            anchors.margins: ValkyxMetrics.m
                            spacing: ValkyxMetrics.m

                            PillSlider {
                                width: parent.width
                                glyph: "\uDB81\uDDA8"
                                value: ValkyxState.briPct
                                onMoved: (pct) => ValkyxState.setBrightness(pct)
                            }
                            PillSlider {
                                width: parent.width
                                glyph: ValkyxState.volPct === 0 ? "\uDB81\uDD81" : ValkyxState.volPct < 33 ? "\uDB81\uDD7F" : ValkyxState.volPct < 66 ? "\uDB81\uDD80" : "\uDB81\uDD7E"
                                value: ValkyxState.volPct
                                glyphClickable: true
                                glyphOpen: parent.parent.audioOpen
                                onGlyphClicked: parent.parent.audioOpen = !parent.parent.audioOpen
                                onMoved: (pct) => ValkyxState.setVolume(pct)
                            }

                            // audio I/O drawer — drops from the volume glyph (no standalone card)
                            Column {
                                visible: parent.parent.audioOpen
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: ValkyxState.audioSinks
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width; height: 26; radius: 7
                                        color: rowS.containsMouse ? ValkyxMaterials.surface0 : (modelData.default ? ValkyxTheme.accentDim : "transparent")
                                        MouseArea {
                                            id: rowS; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { parent.parent.parent.parent.audioOpen = false; ValkyxState.setAudioOutput(modelData.id) }
                                        }
                                        Row {
                                            width: parent.width
                                            anchors.verticalCenter: parent.verticalCenter; spacing: 6; leftPadding: 6
                                            Text {
                                                text: modelData.default ? "\uDB80\uDD2C" : "\uDB81\uDD7E"
                                                color: modelData.default ? ValkyxTheme.accent : ValkyxTheme.muted
                                                font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                                            }
                                            Text {
                                                width: parent.width - 66
                                                text: modelData.label; elide: Text.ElideMiddle
                                                color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                                            }
                                        }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "transparent" }
                                Text {
                                    text: "Input"; color: ValkyxTheme.muted
                                    font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale); font.bold: true
                                }
                                Repeater {
                                    model: ValkyxState.audioSources
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width; height: 26; radius: 7
                                        color: rowI.containsMouse ? ValkyxMaterials.surface0 : (modelData.default ? ValkyxTheme.accentDim : "transparent")
                                        MouseArea {
                                            id: rowI; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { parent.parent.parent.parent.audioOpen = false; ValkyxState.setAudioInput(modelData.id) }
                                        }
                                        Row {
                                            width: parent.width
                                            anchors.verticalCenter: parent.verticalCenter; spacing: 6; leftPadding: 6
                                            Text {
                                                text: modelData.default ? "\uDB80\uDD2C" : "\uDB80\uDF6C"
                                                color: modelData.default ? ValkyxTheme.accent : ValkyxTheme.muted
                                                font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                                            }
                                            Text {
                                                width: parent.width - 66
                                                text: modelData.label; elide: Text.ElideMiddle
                                                color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
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
                    spacing: ValkyxMetrics.s

                    // header — left: bell + title | right: count badge + clear
                    Item {
                        width: parent.width; height: 24

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 7
                            Text {
                                text: "\uDB80\uDC9A"; color: ValkyxTheme.accent
                                font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(12 * ValkyxState.fontScale)
                            }
                            Text {
                                text: "Notifications"; color: ValkyxTheme.text
                                font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale); font.bold: true
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Rectangle {
                                visible: ValkyxState.notifList.length > 0
                                width: 20; height: 20; radius: 10
                                color: ValkyxTheme.accent
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: ValkyxState.notifList.length
                                    color: ValkyxTheme.textOnAccent
                                    font.family: ValkyxTheme.fontMono; font.bold: true
                                    font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                                }
                            }
                            Item {
                                width: 20; height: 20
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uDB80\uDD56"; color: clearH.containsMouse ? ValkyxTheme.accent : ValkyxTheme.muted
                                    font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(11 * ValkyxState.fontScale)
                                    Behavior on color { ColorAnimation { duration: ValkyxMotion.fast } }
                                }
                                MouseArea { id: clearH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ValkyxState.clearNotifs() }
                            }
                        }
                    }

                    Repeater {
                        model: ValkyxState.notifList.slice(0, 4)
                        Item {
                            required property var modelData
                            required property int index
                            width: parent.width; height: 36

                            Rectangle {
                                id: nBg
                                anchors.fill: parent; radius: 8
                                color: rowN.containsMouse ? ValkyxMaterials.surface2 : ValkyxMaterials.surface0
                                Behavior on color { ColorAnimation { duration: ValkyxMotion.fast } }
                            }
                            MouseArea {
                                id: rowN
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ValkyxState.openNotification(index)
                            }
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 6; anchors.rightMargin: 6
                                spacing: 8
                                Rectangle {
                                    width: 24; height: 24; radius: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: ValkyxMaterials.surface0
                                    Text {
                                        anchors.centerIn: parent
                                        text: (modelData.app || "?").charAt(0).toUpperCase()
                                        color: ValkyxTheme.accent
                                        font.family: ValkyxTheme.fontUI; font.bold: true
                                        font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                                    }
                                }
                                Column {
                                    width: parent.width - 32
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        text: modelData.app || "System"; elide: Text.ElideRight
                                        color: ValkyxTheme.accent; font.family: ValkyxTheme.fontUI; font.bold: true
                                        font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                                    }
                                    Text {
                                        text: modelData.summary; elide: Text.ElideRight
                                        color: ValkyxTheme.text; font.family: ValkyxTheme.fontUI
                                        font.pixelSize: Math.round(9 * ValkyxState.fontScale); maximumLineCount: 1
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: ValkyxState.notifList.length === 0
                        text: "All clear"; color: ValkyxTheme.muted
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                        padding: 6
                    }
                    Text {
                        visible: ValkyxState.notifList.length > 4
                        text: "+ " + (ValkyxState.notifList.length - 4) + " more"; color: ValkyxTheme.muted
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                        padding: 4
                    }
                }

                // ── tailscale (click the header to draw down the peer list; toggle mesh) ──
                Rectangle {
                    width: parent.width
                    height: tsCol.implicitHeight + 2 * ValkyxMetrics.m
                    radius: ValkyxMetrics.radiusMd
                    color: ValkyxMaterials.surface2
                    Column {
                        id: tsCol
                        anchors.fill: parent
                        anchors.margins: ValkyxMetrics.m
                        spacing: ValkyxMetrics.xs

                        Item {
                            width: parent.width
                            height: tsHead.implicitHeight
                            RowLayout {
                                id: tsHead
                                width: parent.width
                                spacing: ValkyxMetrics.s
                                Item {
                                    Layout.preferredWidth: 22; Layout.preferredHeight: 18
                                    Text {
                                        anchors.centerIn: parent; text: "\uDB81\uDC8B"
                                        color: !ValkyxState.tsUp ? ValkyxTheme.danger :
                                               ValkyxState.tsPeers.some(p => p.online) ? ValkyxTheme.accent : ValkyxTheme.muted
                                        font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(15 * ValkyxState.fontScale)
                                    }
                                }
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Tailscale"; color: ValkyxTheme.text
                                        font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                                    }
                                    Text {
                                        text: tsSubtitle(); color: ValkyxTheme.muted; elide: Text.ElideRight
                                        width: parent.width
                                        font.pixelSize: Math.round(8 * ValkyxState.fontScale); font.family: ValkyxTheme.fontUI
                                    }
                                }
                                Text {
                                    text: "\uDB80\uDD40"; color: ValkyxTheme.muted
                                    font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(11 * ValkyxState.fontScale)
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
                            model: ValkyxState.tsPeers
                            visible: tsOpen
                            Row {
                                required property var modelData
                                width: parent.width
                                height: 22
                                spacing: 6
                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.online ? ValkyxTheme.accent : ValkyxTheme.tint(ValkyxTheme.muted, "66")
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 150
                                    text: modelData.name
                                    color: modelData.online ? ValkyxTheme.text : ValkyxTheme.muted
                                    font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 46
                                    text: modelData.online ? "" : "off"
                                    horizontalAlignment: Text.AlignRight
                                    color: ValkyxTheme.muted
                                    font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 66
                                    horizontalAlignment: Text.AlignRight
                                    text: modelData.ip
                                    color: ValkyxTheme.tint(ValkyxTheme.muted, "99")
                                    font.family: ValkyxTheme.fontMono; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        Text {
                            visible: tsOpen && ValkyxState.tsPeers.length === 0
                            text: "No peers"; color: ValkyxTheme.muted
                            font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale)
                        }
                        RowLayout {
                            width: parent.width
                            visible: tsOpen
                            spacing: ValkyxMetrics.s
                            Text {
                                text: "Mesh"; color: ValkyxState.tsUp ? ValkyxTheme.accent : ValkyxTheme.muted
                                font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale); font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            TogglePill {
                                on: ValkyxState.tsUp
                                onToggled: ValkyxState.setTailscale(!ValkyxState.tsUp)
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
                subtitle: (ValkyxState.acSource === "battery" && ValkyxState.powerProfileLive !== ValkyxState.powerProfile
                        ? ValkyxState.powerProfileLive + " (on battery)"
                        : ValkyxState.powerProfileLive)
                Row {
                    spacing: ValkyxMetrics.s
                    Repeater {
                        model: [
                            { key: "power-saver", label: "Silent" },
                            { key: "balanced", label: "Balanced" },
                            { key: "performance", label: "Perf" }
                        ]
                        Rectangle {
                            required property var modelData
                            readonly property bool active: ValkyxState.powerProfile === modelData.key
                            width: 52; height: 24; radius: 8
                            color: hP.containsMouse ? ValkyxMaterials.surface0 : (active ? ValkyxMaterials.surface0 : "transparent")
                            border.color: active ? ValkyxMaterials.borderActive : "transparent"; border.width: 1
                            Text { anchors.centerIn: parent; text: modelData.label; color: active ? ValkyxTheme.text : ValkyxTheme.muted; font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * ValkyxState.fontScale) }
                            MouseArea { id: hP; anchors.fill: parent; hoverEnabled: true; onClicked: ValkyxState.setPowerProfile(modelData.key); cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

        }
    }
    }
}