// SETTINGS: Appearance — wallpaper, accent, blur, font scale.
import QtQuick
import QtQuick.Effects
import "../../core" as Core
import "../../core/components" as Comp

Flickable {
    contentHeight: col.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        width: parent.width
        spacing: Core.ValkyxMetrics.l

        // ── Section: Wallpaper ──
        // Full-width blurred hero of the applied wallpaper — ports iNiR's coverflow
        // backdrop (blurMax 64, blur 1.0, saturation 0.15 + dark scrim + vignette).
        // Clicking opens the full skew/grid selector (Super+W).
        Comp.ValkyxSection { label: "WALLPAPER" }

        Item {
            id: wpHero
            width: parent.width
            height: 220
            clip: true

            // MultiEffect fades at its bounds, so oversize the source by blurOverflow.
            readonly property int blurOverflow: 64
            // posterFor() mutates the poster queue, so it must NOT run inside a
            // binding (QML flagged a binding loop on _src). Resolve imperatively.
            property string _src: ""
            function refreshSrc() {
                _src = Core.ValkyxState.activeMediaPath.length > 0
                    ? Core.WallpaperStore.posterFor(Core.ValkyxState.activeMediaPath) : ""
            }
            Component.onCompleted: refreshSrc()
            Connections {
                target: Core.ValkyxState
                function onActiveMediaPathChanged() { wpHero.refreshSrc() }
            }

            Item {
                id: wpHeroSrc
                anchors.fill: parent
                anchors.margins: -wpHero.blurOverflow
                // `layer.effect` (not a standalone MultiEffect{source:...}) — the
                // standalone form leaves the sharp source drawn underneath.
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 48
                    blur: 0.5
                    saturation: 0.15
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Item {
                            width: wpHero.width + 2 * wpHero.blurOverflow
                            height: wpHero.height + 2 * wpHero.blurOverflow
                            Rectangle {
                                x: wpHero.blurOverflow; y: wpHero.blurOverflow
                                width: wpHero.width; height: wpHero.height
                                radius: Core.ValkyxMetrics.radiusMd
                                color: "white"
                            }
                        }
                    }
                }
                Image {
                    anchors.fill: parent
                    anchors.margins: wpHero.blurOverflow
                    source: wpHero._src
                    fillMode: Image.PreserveAspectCrop
                    cache: true; asynchronous: true
                    sourceSize.width: 1400; sourceSize.height: 720
                }
            }

            // dark scrim over the blur for label legibility
            Rectangle {
                anchors.fill: parent
                color: Core.ValkyxMaterials.surface0
                opacity: 0.45
            }

            // vignette: darken edges for depth
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.65; color: "transparent" }
                    GradientStop { position: 1.0; color: Core.ValkyxTheme.tint(Core.ValkyxTheme.bg, "66") }
                }
            }

            // 1px outline on the rounded mask edge
            Rectangle {
                anchors.fill: parent
                radius: Core.ValkyxMetrics.radiusMd
                color: "transparent"
                border.color: Core.ValkyxMaterials.border; border.width: 1
            }

            // icon-style affordance, nudged below center rather than dead-center
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 44
                spacing: 3
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\uDB80\uDEE9"
                    color: Core.ValkyxTheme.text
                    font.family: Core.ValkyxTheme.fontMono
                    font.pixelSize: Math.round(18 * Core.ValkyxState.fontScale)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Browse wallpapers"
                    color: Core.ValkyxTheme.tint(Core.ValkyxTheme.text, "99")
                    font.family: Core.ValkyxTheme.fontUI
                    font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale)
                }
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: Core.ValkyxState.wallpaperOpen = true
            }
        }

        // ── Section: Online (Wallhaven, SFW) ──
        Comp.ValkyxSection { label: "ONLINE"; topPadding: 8 }

        Row {
            width: parent.width; spacing: 8
            Rectangle {
                width: parent.width - 70; height: 30; radius: 6
                color: Core.ValkyxMaterials.panelGlass; border.color: Core.ValkyxMaterials.border; border.width: 1
                TextInput {
                    id: searchInput
                    anchors.fill: parent; anchors.margins: 6
                    color: Core.ValkyxTheme.text; selectionColor: Core.ValkyxTheme.accent
                    font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(11 * Core.ValkyxState.fontScale)
                    clip: true
                    property string placeholder: "Search wallpapers..."
                    Text {
                        visible: !searchInput.text && !searchInput.activeFocus
                        text: searchInput.placeholder; color: Core.ValkyxTheme.muted
                        font: searchInput.font; anchors.verticalCenter: parent.verticalCenter
                    }
                    Keys.onReturnPressed: doSearch()
                    Keys.onEnterPressed: doSearch()
                    function doSearch() { if (text.length > 0) Core.WallpaperApi.search(text) }
                }
            }
            Rectangle {
                width: 62; height: 30; radius: 6
                color: Core.ValkyxTheme.accent
                Text {
                    anchors.centerIn: parent; text: "Search"
                    color: "#fff"; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale)
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (searchInput.text.length > 0) Core.WallpaperApi.search(searchInput.text) }
                }
            }
        }

        Flow {
            width: parent.width; spacing: 8
            Repeater {
                model: Core.WallpaperApi.results
                Rectangle {
                    required property int index
                    required property var modelData
                    width: 100; height: 64; radius: 8
                    color: "transparent"
                    border.color: Core.ValkyxMaterials.border; border.width: 1
                    Image {
                        anchors.fill: parent; anchors.margins: 2
                        source: modelData.thumb; fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Core.ValkyxState.downloadAndSetWallpaper(modelData.full)
                    }
                }
            }
        }

        Row {
            width: parent.width; spacing: 8
            visible: Core.WallpaperApi.hasMore || Core.WallpaperApi.loading
            Item { width: 1; height: 1 }
            Rectangle {
                visible: Core.WallpaperApi.hasMore && !Core.WallpaperApi.loading
                width: loadMoreLabel.implicitWidth + 24; height: 26; radius: 6
                color: "transparent"; border.color: Core.ValkyxMaterials.border; border.width: 1
                Text {
                    id: loadMoreLabel; anchors.centerIn: parent; text: "Load more"
                    color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI
                    font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale)
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: Core.WallpaperApi.nextPage()
                }
            }
            Text {
                visible: Core.WallpaperApi.loading
                text: "Loading..."; color: Core.ValkyxTheme.muted
                font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale)
            }
        }

        // ── Section: Theme (accent + bg family, applied live) ──
        // Only the 6 valkyx accents here (the full omarchy catalogue is applied via
        // `qs -c valkyx ipc call theme apply <name>` — 28 swatches made this unreadable).
        Comp.ValkyxSection { label: "THEME"; topPadding: 8 }

        Row {
            spacing: 12
            Repeater {
                model: Core.ValkyxTheme.themeNames
                Column {
                    required property string modelData
                    property var theme: Core.ValkyxTheme.themeByName(modelData)
                    spacing: 4
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 32; height: 32; radius: 16
                        color: theme.accent
                        border.color: Core.ValkyxState.themeName === modelData ? Core.ValkyxTheme.text : "transparent"
                        border.width: 2
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Core.ValkyxState.applyTheme(modelData)
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData
                        color: Core.ValkyxState.themeName === modelData ? Core.ValkyxTheme.accent : Core.ValkyxTheme.muted
                        font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(8 * Core.ValkyxState.fontScale)
                    }
                }
            }
        }

        // ── Section: Effects ──
        Comp.ValkyxSection { label: "EFFECTS"; topPadding: 8 }

        Row {
            spacing: Core.ValkyxMetrics.m; height: 36
            Text { text: "Blur"; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Comp.ValkyxToggle {
                checked: Core.ValkyxState.blurEnabled
                anchors.verticalCenter: parent.verticalCenter
                onToggled: Core.ValkyxState.toggleBlur()
            }
        }

        // ── Section: Motion ──
        Comp.ValkyxSection { label: "MOTION"; topPadding: 8 }

        Row {
            spacing: Core.ValkyxMetrics.m; height: 36
            Text { text: "Reduced motion"; color: Core.ValkyxTheme.text; font.family: Core.ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Comp.ValkyxToggle {
                // resolved value, not the pref: "auto" that resolves to reduced
                // must show as ON, or the toggle lies about the shell's state.
                checked: Core.ValkyxState.reducedMotion
                anchors.verticalCenter: parent.verticalCenter
                onToggled: Core.ValkyxState.setMotion(checked)
            }
        }

        // ── Section: Font Scale ──
        Comp.ValkyxSection { label: "FONT SCALE"; topPadding: 8 }

        Row {
            spacing: Core.ValkyxMetrics.m; height: 28
            Text { text: "0.8×"; color: Core.ValkyxTheme.muted; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
            Item {
                id: fsTrack
                width: parent.parent.width - 128; height: 20
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { // rail
                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    height: 6; radius: 3; color: Core.ValkyxTheme.tint(Core.ValkyxTheme.muted, "26")
                }
                Rectangle { // fill
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * ((Core.ValkyxState.fontScale - 0.8) / 0.7)
                    height: 6; radius: 3; color: Core.ValkyxTheme.tint(Core.ValkyxTheme.muted, "55")
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (m) => setFromX(m.x)
                    onPositionChanged: (m) => { if (pressed) setFromX(m.x) }
                    onReleased: Core.ValkyxState.savePersisted()
                    function setFromX(x) {
                        const v = Math.max(0, Math.min(1, x / fsTrack.width))
                        Core.ValkyxState.fontScale = Math.round((0.8 + v * 0.7) * 100) / 100
                    }
                }
            }
            Text { text: "1.5×"; color: Core.ValkyxTheme.muted; font.pixelSize: Math.round(10 * Core.ValkyxState.fontScale); anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
