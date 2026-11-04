// VALKYX Wallpaper Selector — iNiR-style fan deck + grid toggle (Super+W).
// Catalogue = local ~/Pictures/Wallpapers (stills/gifs/videos) + Wallhaven stills.
// Apply routes through ValkyxState.setWallpaper (awww for images, mpvpaper for video/gif).
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../core"

PanelWindow {
    id: wsel
    visible: ValkyxState.wallpaperOpen
    focusable: true
    aboveWindows: true
    exclusiveZone: -1
    color: "transparent"
    // Re-assert keyboard focus on a retry timer: layershell re-maps can land AFTER
    // Qt.callLater fires, so a one-shot focus grab is dropped and the deck goes
    // keyboard-dead until a click. Poll while visible, stop once focus actually sticks.
    property Timer focusPoll: Timer {
        interval: 120; repeat: true
        onTriggered: {
            deckFocus.forceActiveFocus()
            if (deckFocus.activeFocus) stop()
        }
    }
    // `visible` is pinned true forever, so onVisibleChanged never fires — the open
    // sequence has to hang off the real state flag instead.
    Connections {
        target: ValkyxState
        function onWallpaperOpenChanged() { if (ValkyxState.wallpaperOpen) { open(); focusPoll.start() } else focusPoll.stop() }
    }

    // ── geometry: fullscreen overlay (iNiR style) ──
    width: wsel.screen ? wsel.screen.width : 1920
    height: wsel.screen ? wsel.screen.height : 1080
    margins { left: 0; top: 0; right: 0; bottom: 0 }

    // ── catalogue ──
    property int typeFilter: 0   // 0 all | 1 img | 2 vid | 3 gif
    property string query: ""
    property int viewMode: 0     // 0 skew | 1 grid
    property bool favOnly: false // ★ filter to favorites
    property var hueFilter: []   // selected hue chips (hex strings)
    property var hueChips: []    // unique colour families in current view
    property int favCount: 0     // favourites in current type-filtered view

    function kindIdx(kind) {
        return kind === "image" ? 1 : kind === "video" ? 2 : 3
    }

    // hue angle (0-360) of a #rrggbb hex; NaN-safe
    function hueOf(hex) {
        const h = String(hex).replace("#", "")
        if (h.length < 6) return -1
        const r = parseInt(h.slice(0, 2), 16) / 255.0
        const g = parseInt(h.slice(2, 4), 16) / 255.0
        const b = parseInt(h.slice(4, 6), 16) / 255.0
        const mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn
        if (!d) return -1
        let hh
        if (mx === r) hh = 60 * (((g - b) / d) % 6)
        else if (mx === g) hh = 60 * ((b - r) / d + 2)
        else hh = 60 * ((r - g) / d + 4)
        return hh < 0 ? hh + 360 : hh
    }
    function hueNear(a, b) {
        if (a < 0 || b < 0) return false
        const d = Math.abs(a - b)
        return Math.min(d, 360 - d) <= 32
    }
    function entryMatches(e) {
        if (favOnly && !WallpaperStore.isFav(e.path)) return false
        if (hueFilter.length) {
            const cs = e.colors || []
            if (!cs.some(c => hueFilter.some(h => hueNear(hueOf(c), hueOf(h))))) return false
        }
        return true
    }
    function refresh() {
        const out = []
        const want = typeFilter
        for (const m of WallpaperStore.mediaList) {
            const k = WallpaperStore.kindOf(m.path)
            if (want !== 0 && kindIdx(k) !== want) continue
            const e = {
                path: m.path, name: m.name, kind: k, online: false,
                poster: WallpaperStore.posterFor(m.path),
                colors: WallpaperStore.colorsFor(m.path)
            }
            if (entryMatches(e)) out.push(e)
        }
        for (const w of WallpaperApi.results) {
            if (want !== 0 && want !== 1) continue   // online results are stills
            const e = { path: w.full, name: w.id, kind: "image", online: true, poster: w.thumb, colors: [] }
            if (entryMatches(e)) out.push(e)
        }
        deck.rebuild(out)
        gridItem.rebuild(out)
        recalcChips()
        let fc = 0
        for (const m of WallpaperStore.mediaList) {
            if (typeFilter !== 0 && kindIdx(WallpaperStore.kindOf(m.path)) !== typeFilter) continue
            if (WallpaperStore.isFav(m.path)) fc++
        }
        favCount = fc
    }
    // unique colour families across the current (type-filtered) entries
    function recalcChips() {
        const chips = []
        for (const e of deck.entries) {
            for (const c of (e.colors || [])) {
                const h = hueOf(c)
                if (h < 0 || chips.some(x => hueNear(hueOf(x), h))) continue
                chips.push(c)
            }
        }
        hueChips = chips
    }
    function open() {
        query = ""
        queryInput.text = ""
        favOnly = false
        hueFilter = []
        refresh()
        if (deck.entries.length > 0) {
            // center the currently applied wallpaper (iNiR preview behaviour)
            centerOnActive()
        } else {
            // store scan is async (first open right after boot); re-center when it lands
            pendingCenter = true
        }
        deckFocus.forceActiveFocus()
    }
    property bool pendingCenter: false
    function centerOnActive() {
        const i = deck.entries.findIndex(e => e.path === ValkyxState.activeMediaPath)
        deck.currentIndex = i >= 0 ? i : Math.floor(deck.entries.length / 2)
    }
    function toggleHue(hex) {
        const f = hueFilter.slice()
        const i = f.indexOf(hex)
        if (i >= 0) f.splice(i, 1)
        else f.push(hex)
        hueFilter = f
        refresh()
    }
    function toggleFavOnly() { favOnly = !favOnly; refresh() }
    function jump(d) {
        if (deck.entries.length === 0) return
        const n = (deck.currentIndex + d + deck.entries.length) % deck.entries.length
        // single source of truth: gridItem.currentIndex is BOUND to deck.currentIndex
        // (ValkyxWallpaper.qml:483) — writing it here would destroy that binding.
        deck.currentIndex = n
    }
    function activate() {
        if (deck.entries.length === 0) return
        const e = deck.entries[deck.currentIndex]
        if (e.online) ValkyxState.downloadAndSetWallpaper(e.path)
        else ValkyxState.setWallpaper(e.path)
    }
    function close() {
        ValkyxState.wallpaperOpen = false
    }

    Timer { id: searchT; interval: 450; repeat: false; onTriggered: if (wsel.visible) WallpaperApi.search(query) }
    onQueryChanged: if (wsel.visible) searchT.restart()

    Connections {
        target: WallpaperStore
        function onPosterGenerated(_p) { if (wsel.visible) refresh() }
        function onMediaChanged() { if (wsel.visible) { refresh(); if (wsel.pendingCenter && deck.entries.length > 0) { wsel.pendingCenter = false; wsel.centerOnActive() } } }
        function onFavListChanged() { if (wsel.visible) refresh() }
        // hue for one entry landed: patch just that card, keep position
        function onColorsReady(_p) {
            if (!wsel.visible) return
            for (let i = 0; i < deck.entries.length; ++i) {
                if (deck.entries[i].path !== _p) continue
                const es = deck.entries.slice()
                es[i] = Object.assign({}, es[i], { colors: WallpaperStore.colorsFor(_p) })
                deck.entries = es
                gridItem.entries = es
                break
            }
            wsel.recalcChips()
        }
    }
    Connections {
        target: WallpaperApi
        function onResultsChanged() { if (wsel.visible) refresh() }
    }

    // ── layout (iNiR preview: no scrim — cards float directly on the wallpaper) ──
    Item {
        id: layoutRoot
        anchors.fill: parent
        // Same gate every other panel uses: this PanelWindow is always mapped (see
        // the `visible: true` note above), so WITHOUT this the fullscreen deck
        // paints over the whole desktop and swallows every click, while
        // focusable:false + the ESC shortcut's `enabled` leave no way to close it.
        // `enabled` is required too — opacity 0 alone still eats pointer events.
        opacity: ValkyxState.wallpaperOpen ? 1 : 0
        enabled: ValkyxState.wallpaperOpen

        // floating toolbar pill
        Rectangle {
            id: bar
            width: barRow.implicitWidth + 2 * ValkyxMetrics.m
            height: barRow.implicitHeight + 2 * ValkyxMetrics.m
            radius: ValkyxMetrics.radiusLg
            color: ValkyxMaterials.surface1
            border.color: ValkyxMaterials.borderFaint
            border.width: 1
            layer.enabled: true
            layer.samples: 4
            anchors.top: parent.top
            // centre the whole selector block (pill + fan) vertically on screen
            anchors.topMargin: Math.max(ValkyxMetrics.m, (parent.height - (barRow.implicitHeight + 4 * ValkyxMetrics.m + deck.cardH)) / 2)
            anchors.horizontalCenter: parent.horizontalCenter
            z: 20

            RowLayout {
                id: barRow
                anchors.fill: parent
                anchors.margins: ValkyxMetrics.m
                spacing: ValkyxMetrics.l

                Text {
                    id: title
                    text: "WALLPAPER"
                    color: ValkyxTheme.accent
                    font.family: ValkyxTheme.fontUI
                    font.pixelSize: Math.round(13 * ValkyxState.fontScale)
                    font.bold: true
                }

                Item { Layout.preferredWidth: ValkyxMetrics.s }

                Repeater {
                    model: ["ALL", "IMG", "VID", "GIF"]
                    Item {
                        required property int index
                        required property string modelData
                        Layout.preferredWidth: lbl.implicitWidth + 16
                        Layout.preferredHeight: 26
                        Rectangle {
                            anchors.fill: parent
                            radius: ValkyxMetrics.radiusSm
                            color: wsel.typeFilter === index ? ValkyxMaterials.surface2 : "transparent"
                            border.color: wsel.typeFilter === index ? ValkyxTheme.accent : ValkyxMaterials.borderFaint
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: ValkyxMotion.fast } }
                            Behavior on border.color { ColorAnimation { duration: ValkyxMotion.fast } }
                            Text {
                                id: lbl
                                anchors.centerIn: parent
                                text: modelData
                                color: wsel.typeFilter === index ? ValkyxTheme.accent : ValkyxTheme.muted
                                font.family: ValkyxTheme.fontUI
                                font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                                font.bold: wsel.typeFilter === index
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { wsel.typeFilter = index; wsel.refresh() }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 28
                    radius: ValkyxMetrics.radiusMd
                    color: ValkyxMaterials.surface2
                    border.color: queryInput.activeFocus ? ValkyxTheme.accent : ValkyxMaterials.borderFaint
                    border.width: 1
                    TextField {
                        id: queryInput
                        anchors.fill: parent
                        anchors.leftMargin: 8; anchors.rightMargin: 8
                        color: ValkyxTheme.text
                        font.family: ValkyxTheme.fontUI
                        font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                        placeholderText: "search wallhaven"
                        placeholderTextColor: ValkyxTheme.muted
                        verticalAlignment: Text.AlignVCenter
                        background: Item {}
                        focus: false
                        activeFocusOnTab: false
                        onTextChanged: wsel.query = text
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                event.accepted = true; wsel.activate()
                            } else if (event.key === Qt.Key_Escape) {
                                event.accepted = true; wsel.close()
                            }
                        }
                    }
                }
                Rectangle {
                    visible: WallpaperApi.loading
                    width: 10; height: 10; radius: 5
                    color: ValkyxTheme.accent; opacity: 0.7
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.preferredWidth: ValkyxMetrics.s }

                // view toggle: skew ⇄ grid (solid accent = selection, no wash)
                Rectangle {
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 88
                    radius: ValkyxMetrics.radiusMd
                    color: ValkyxMaterials.surface2
                    border.color: ValkyxMaterials.borderFaint
                    border.width: 1
                    Row {
                        anchors.centerIn: parent
                        width: 84; height: 24
                        spacing: 2
                        Repeater {
                            model: ["SKEW", "GRID"]
                            Rectangle {
                                required property int index
                                required property string modelData
                                width: 42; height: 24
                                radius: 6
                                color: wsel.viewMode === index ? ValkyxTheme.accent : "transparent"
                                Behavior on color { ColorAnimation { duration: ValkyxMotion.fast } }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: wsel.viewMode === index ? ValkyxTheme.textOnAccent : ValkyxTheme.muted
                                    font.family: ValkyxTheme.fontUI
                                    font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                                    font.bold: wsel.viewMode === index
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: wsel.viewMode = index
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredWidth: ValkyxMetrics.l }

                Text {
                    text: hueFilter.length ? "FILTER" : "COLORS"
                    color: ValkyxTheme.muted
                    font.family: ValkyxTheme.fontUI
                    font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
                Repeater {
                    model: wsel.hueChips
                    Rectangle {
                        required property int index
                        required property string modelData
                        width: 16; height: 16; radius: 8
                        Layout.alignment: Qt.AlignVCenter
                        color: modelData
                        border.width: wsel.hueFilter.indexOf(modelData) >= 0 ? 2 : 1
                        border.color: wsel.hueFilter.indexOf(modelData) >= 0 ? ValkyxTheme.accent : ValkyxMaterials.border
                        scale: wsel.hueFilter.indexOf(modelData) >= 0 ? 1.15 : 1
                        Behavior on scale { NumberAnimation { duration: ValkyxMotion.fast } }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wsel.toggleHue(modelData)
                        }
                    }
                }
                Text {
                    visible: wsel.hueChips.length === 0
                    text: "…"
                    color: ValkyxMaterials.border
                    font.family: ValkyxTheme.fontUI
                    font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                }
                Rectangle {
                    visible: wsel.hueFilter.length > 0
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: clrTxt.implicitWidth + 12
                    Layout.alignment: Qt.AlignVCenter
                    radius: 10
                    color: ValkyxMaterials.surface2
                    border.color: ValkyxMaterials.borderFaint; border.width: 1
                    Text {
                        id: clrTxt
                        anchors.centerIn: parent
                        text: "✕"
                        color: ValkyxTheme.muted
                        font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { wsel.hueFilter = []; wsel.refresh() }
                    }
                }

                Item { Layout.preferredWidth: ValkyxMetrics.s }

                // ACCENT THEME swatches (moved here from the old left sidebar)
                Text {
                    text: "ACCENT"
                    color: ValkyxTheme.muted
                    font.family: ValkyxTheme.fontUI
                    font.pixelSize: Math.round(9 * ValkyxState.fontScale)
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
                Repeater {
                    model: ValkyxTheme.themeNames
                    Rectangle {
                        required property string modelData
                        width: 16; height: 16; radius: 8
                        Layout.alignment: Qt.AlignVCenter
                        color: ValkyxTheme.themeByName(modelData).accent
                        border.width: ValkyxState.themeName === modelData ? 2 : 1
                        border.color: ValkyxState.themeName === modelData ? ValkyxTheme.accent : ValkyxMaterials.border
                        scale: ValkyxState.themeName === modelData ? 1.15 : 1
                        Behavior on scale { NumberAnimation { duration: ValkyxMotion.fast } }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ValkyxState.applyTheme(modelData)
                        }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: favTxt.implicitWidth + 22
                    Layout.alignment: Qt.AlignVCenter
                    radius: 11
                    color: wsel.favOnly ? ValkyxTheme.accent : ValkyxMaterials.surface2
                    border.color: wsel.favOnly ? ValkyxTheme.accent : ValkyxMaterials.borderFaint
                    border.width: 1
                    Text {
                        id: favTxt
                        anchors.centerIn: parent
                        text: "★ " + wsel.favCount
                        color: wsel.favOnly ? ValkyxTheme.textOnAccent : ValkyxTheme.text
                        font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wsel.toggleFavOnly()
                    }
                }
            }
        }

        // content floats directly on the wallpaper under the pill
        Item {
            id: contentArea
            anchors.top: bar.bottom
            anchors.topMargin: ValkyxMetrics.m
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true

            FocusScope {
                id: deckFocus
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: wsel.close()
                Keys.onRightPressed: { wsel.jump(1); event.accepted = true }
                Keys.onLeftPressed: { wsel.jump(-1); event.accepted = true }
                Keys.onReturnPressed: { wsel.activate(); event.accepted = true }
                Keys.onSpacePressed: { wsel.togglePreviewSK(); event.accepted = true }

                ValkyxWallpaperSkew {
                    id: deck
                    anchors.fill: parent
                    visible: wsel.viewMode === 0
                    activePath: ValkyxState.activeMediaPath
                    currentIndex: 0
                    onPick: wsel.activate()
                }
                ValkyxWallpaperGrid {
                    id: gridItem
                    anchors.fill: parent
                    visible: wsel.viewMode === 1
                    activePath: ValkyxState.activeMediaPath
                    currentIndex: deck.currentIndex
                    onPick: wsel.activate()
                    onSelected: (i) => deck.currentIndex = i
                }

                Text {
                    visible: deck.entries.length === 0 && !WallpaperApi.loading
                    anchors.centerIn: parent
                    text: "No media yet — drop wallpapers into ~/Pictures/Wallpapers"
                    color: ValkyxTheme.muted
                    font.family: ValkyxTheme.fontUI
                    font.pixelSize: Math.round(11 * ValkyxState.fontScale)
                }
            }
        }
    }

// ── keyboard handled by Keys on deckFocus (item-level, like launcher) ──
    function togglePreviewSK() { deck.animatePreview = !deck.animatePreview }
}