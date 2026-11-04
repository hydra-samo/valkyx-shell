// AXORA Dock — bottom center, glassmorphism, context-priority ordering.
// Icons only, hover-expand, running indicators.
import Quickshell
import QtQuick
import QtQuick.Layouts
import "../core"

PanelWindow {
    id: dock
    visible: AxoraContext.rule(AxoraState.context, "dock")
    // NOT full-width: the panel surface is sized to the centered pill so it
    // doesn't cover/intercept the whole bottom edge of the screen. Height
    // collapses to a thin reveal strip when hidden. (Anchors only support the
    // 4 edges — no horizontalCenter — so center via margins.left.)
    anchors { bottom: true; left: true; right: false }
    margins { bottom: 0; left: Math.max(0, Math.round(((dock.screen ? dock.screen.width : 1366) - dock.pillWidth) / 2)) }
    implicitHeight: dock.shown ? 84 : 16  // 56 pill + 28 tooltip strip above; thin hot zone when hidden
    implicitWidth: dock.pillWidth
    color: "transparent"
    exclusiveZone: -1

    property int hoveredIdx: -1
    property bool shown: false

    // pill width: contents + padding, capped so a pile of running apps doesn't
    // stretch the dock across the screen. pillWidth = min(content, 70% screen).
    readonly property real pillWidth: {
        const w = dockRow.implicitWidth + AxoraMetrics.xl * 2
        const max = (dock.screen ? dock.screen.width : 1366) * 0.7
        return Math.min(w, max)
    }

    // full-window hover zone — single source of truth for show/hide + tile interaction.
    // one MouseArea = no enter/leave races between overlapping areas.
    // Constrained to the centered pill width so it never blocks clicks on window
    // buttons at the screen edges (the dock is NOT a full-width taskbar).
    MouseArea {
        id: hoverZone
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: dock.pillWidth
        height: parent.height
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: armTimer.start()
        onExited: { armTimer.stop(); hoveredIdx = -1; if (!dockMenu.visible) hideTimer.start() }
        onPositionChanged: (mouse) => {
            var t = tileAt(mouse.x, mouse.y)
            hoveredIdx = t ? t.index : -1
        }
        onClicked: (mouse) => {
            const t = tileAt(mouse.x, mouse.y)
            if (!t) return
            if (mouse.button === Qt.RightButton) dockMenu.openAt(t)
            else if (t.item.isAction) t.item.action()
            else AxoraState.focusOrLaunch(t.item.cls, t.item.cmd)
        }
        cursorShape: hoveredIdx >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    Timer { id: armTimer; interval: AxoraMotion.peekDelay; onTriggered: { shown = true; hideTimer.stop() } }
    Timer { id: hideTimer; interval: 400; onTriggered: shown = false }

    onVisibleChanged: if (visible) shown = false

    // tile under a window-local point, or null
    function tileAt(x, y) {
        var pos = dockRow.mapFromItem(hoverZone, x, y)
        var child = dockRow.childAt(pos.x, pos.y)
        while (child && child.parent !== dockRow) child = child.parent
        return (child && child.index !== undefined) ? child : null
    }

    // pinned dock apps — cls + cmd + label; icon comes from themedIcon() (accent-reactive)
    readonly property var apps: [
        { key: "terminal", cls: "kitty", cmd: "kitty", label: "Terminal" },
        { key: "web",      cls: "helium", cmd: "helium-browser", label: "Browser" },
        { key: "files",    cls: "thunar", cmd: "thunar", label: "Files" },
        { key: "sandbox",  cls: "kitty", cmd: "kitty --title AxoraSandbox --directory=" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/axora-sandbox", label: "Sandbox" },
        { key: "blender",  cls: "blender", cmd: "blender", label: "Blender" },
        { key: "resolve",  cls: "resolve", cmd: "/opt/resolve/resolve", label: "DaVinci Resolve" }
    ]

    readonly property var labelMap: {
        "kitty": "Terminal",
        "helium": "Browser",
        "helium-browser": "Browser",
        "thunar": "Files",
        "blender": "Blender",
        "resolve": "DaVinci Resolve",
        "org.telegram.desktop": "Telegram",
        "code-oss": "Code",
        "firefox": "Browser",
        "chromium": "Browser",
        "code": "Code",
        "kitty": "Terminal",
        "nautilus": "Files",
        "org.gnome.Nautilus": "Files",
        "org.gnome.Console": "Terminal",
        "io.wezterm.wez": "Terminal",
        "gimp": "GIMP",
        "inkscape": "Inkscape",
        "obs": "OBS Studio",
        "vlc": "VLC",
        "spotify": "Spotify",
        "dolphin": "Dolphin",
        "darktable": "Darktable",
        "gedit": "Editor",
        "org.gnome.Calendar": "Calendar"
    }

    function getLabel(cls) {
        if (labelMap[cls]) return labelMap[cls]
        return AxoraState.appLabel(cls)
    }

    // context priority reordering (for pinned apps only)
    function contextOrder() {
        const ctx = AxoraState.context
        if (ctx === "creative") return [3, 5, 0, 1, 2, 4]  // sandbox, blender, resolve then the rest
        return [0, 1, 2, 3, 4, 5]  // normal order
    }

    // combined model: pinned apps first, then running apps not in pinned.
    // Rebuilt explicitly on runningWindows/context/theme change (a plain var
    // binding is evaluated once at construction — this is what made the dock
    // show only pinned apps).
    property var dockItems: []

    function refreshModel() {
        const order = contextOrder()
        const pinned = []
        const running = AxoraState.runningWindows || []
        for (let i = 0; i < order.length; i++) {
            const app = apps[order[i]]
            const isAction = app.cls === ""
            // keep visible themed glyph for pinned entries (accent-branded and
            // readable on the dark glass); real icons used for extra running apps
            pinned.push({ key: app.key, cls: app.cls, cmd: app.cmd, label: app.label, pinned: true, realIdx: order[i], icon: themedIcon(app.key), isAction: isAction, action: function() { AxoraState.launch(app.cmd) } })
        }
        // add running apps not in pinned list (chrome-* = Helium, already pinned as web)
        const pinnedClasses = new Set(apps.map(a => a.cls))
        for (const cls of running) {
            if (!pinnedClasses.has(cls) && cls.indexOf("chrome-") !== 0) {
                // real app icon when resolved, else themed glyph
                const real = AxoraState.classIcons[cls]
                // resolve a launch command for unknown running apps so New Window / click-launch works
                const resolvedCmd = AxoraState.commandForClass(cls)
                const label = resolvedCmd !== "" ? getLabel(cls) : getLabel(cls)
                pinned.push({ key: cls, cls: cls, cmd: resolvedCmd, icon: real || themedIcon(cls), label: label, pinned: false })
            }
        }
        dockItems = pinned
    }

    // accent-themed glyph for pinned apps + unknown running classes (fits the shell).
    function themedIcon(cls) {
        const theme = AxoraState.themedName || "Axora"
        const map = {
            terminal: "terminal", web: "browser", files: "files", editor: "editor",
            blender: "blender", resolve: "resolve", kitty: "terminal", thunar: "files",
            sandbox: "terminal", toggle: "swap",
            "org.telegram.desktop": "browser", code: "editor",
            "code-oss": "editor"
        }
        const g = map[cls] || "window"
        return "file://StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/axora-icons/"" + theme + "/" + g + ".png"
    }

    Component.onCompleted: refreshModel()
    Connections {
        target: AxoraState
        function onRunningWindowsChanged() { refreshModel() }
        function onContextChanged() { refreshModel() }
        function onThemeNameChanged() { refreshModel() }
        function onClassIconsChanged() { refreshModel() }
    }

    Rectangle {
        // centered pill: panel is full-width transparent, pill is centered
        // masked by default — slides up on hover-arm, slides down on leave
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: shown ? 12 : -64
        width: dock.pillWidth
        height: 56
        radius: AxoraMetrics.rPanel
        color: AxoraMaterials.dockGlass
        border.color: AxoraTheme.tint(AxoraTheme.accent, "66")
        border.width: 1

        Row {
            id: dockRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: AxoraMetrics.xs
            spacing: AxoraMetrics.s

            Repeater {
                model: dock.dockItems

                Item {
                    required property int index
                    required property var modelData
                    property var item: modelData
                    property bool running: item.pinned ? (AxoraState.states["dock_" + item.key] === "on") : true

                    width: 54
                    height: 54

                    // transparent hit-test area for childAt/tileAt
                    Rectangle { anchors.fill: parent; color: "transparent" }

                    // running indicator dot (all running apps, not just pinned)
                    Rectangle {
                        visible: running && !item.isAction
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 3
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 6; height: 6; radius: 3
                        color: AxoraTheme.accent
                    }

                    // icon — macOS-style "pop": hovered icon scales up and lifts
                    // toward its nearest screen edge with a springy decay. No
                    // background wash/rect. The pill container clips overflow.
                    Image {
                        id: dockIcon
                        anchors.centerIn: parent
                        source: item.icon
                        transformOrigin: Item.Center
                        scale: (dock.hoveredIdx === index) ? 1.35 : 1.0
                        // lift upward (dock is bottom-anchored); neighbors not displaced
                        anchors.verticalCenterOffset: (dock.hoveredIdx === index) ? -6 : 0
                        Behavior on scale { SpringAnimation { spring: 3.2; damping: 0.9; mass: 1.0 } }
                        Behavior on anchors.verticalCenterOffset { SpringAnimation { spring: 3.2; damping: 0.9; mass: 1.0 } }
                        width: 34; height: 34
                        smooth: true; mipmap: true
                        sourceSize: Qt.size(96, 96)
                    }

                    // label on hover
                    Rectangle {
                        visible: dock.hoveredIdx === index
                        anchors.bottom: dockIcon.top; anchors.bottomMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 18; radius: 4
                        color: AxoraMaterials.panelGlass
                        border.color: AxoraMaterials.border; border.width: 1
                        width: 80
                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: item.label
                            color: AxoraTheme.text
                            font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale)
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // ── dock app context menu (right-click) ──
    // MenuRow is the row widget used by DockMenu.
    component MenuRow: Rectangle {
        id: mr
        required property var modelData
        property bool itemEnabled: modelData.enabled !== false
        signal triggered()
        width: parent.width; height: 26; radius: 6
        color: mrH.containsMouse && itemEnabled ? AxoraMaterials.tileGlass : "transparent"
        Text {
            anchors.left: parent.left; anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.label; color: itemEnabled ? (mrH.containsMouse ? AxoraTheme.accent : AxoraTheme.text) : AxoraTheme.tint(AxoraTheme.muted, "88")
            font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale)
        }
        MouseArea {
            id: mrH; anchors.fill: parent; hoverEnabled: true; enabled: mr.itemEnabled
            cursorShape: mr.itemEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mr.triggered()
        }
    }

    component DockMenu: PanelWindow {
        id: dm
        visible: false
        anchors.bottom: true
        exclusiveZone: 0
        focusable: true
        aboveWindows: true
        color: "transparent"
        implicitWidth: 190
        property var app: null

        function openAt(tile) {
            app = tile.item
            const g = tile.mapToGlobal(tile.width / 2, tile.height)
            const sw = dm.screen ? dm.screen.width : 1366
            dm.anchors.left = true; dm.anchors.right = false
            dm.margins.bottom = dock.implicitHeight + 8
            dm.margins.left = Math.max(4, Math.min(sw - dm.implicitWidth - 4, g.x - dm.implicitWidth / 2))
            visible = true
        }

        Shortcut { sequence: "Escape"; onActivated: dm.visible = false }
        onVisibleChanged: if (!visible) hideTimer.start()

        Rectangle {
            anchors.fill: parent
            radius: AxoraMetrics.rPanel
            color: AxoraMaterials.panelGlass
            border.color: AxoraMaterials.border
            border.width: 1
        }

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            Row {
                width: parent.width; height: 26; spacing: 8
                Image { anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; sourceSize: Qt.size(16, 16); source: dm.app ? dm.app.icon : "" }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: dm.app ? dm.app.label : ""
                    color: AxoraTheme.text; font.family: AxoraTheme.fontUI
                    font.pixelSize: Math.round(10 * AxoraState.fontScale); font.bold: true
                }
            }
            Rectangle { width: parent.width; height: 1; color: AxoraMaterials.border }
            Repeater {
                model: dm.app && dm.app.isAction ? [
                    { label: "Toggle Shell",
                      action: function() { AxoraState.launch(dm.app.cmd) },
                      enabled: true }
                ] : dm.app ? [
                    { label: dm.app.running ? "New Window" : "Open",
                      action: function() { AxoraState.launch(dm.app.cmd) },
                      enabled: dm.app.cmd !== "" },
                    { label: "Close Window(s)", action: function() { AxoraState.closeClass(dm.app.cls) }, enabled: dm.app.running },
                    { label: "Quit", action: function() { AxoraState.quitClass(dm.app.cls) }, enabled: dm.app.running }
                ] : []
                MenuRow {
                    onTriggered: { modelData.action(); dm.visible = false }
                }
            }
        }
    }

    DockMenu { id: dockMenu }
}
