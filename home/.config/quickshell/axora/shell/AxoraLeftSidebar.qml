// AXORA Left Sidebar — SYSTEM DASHBOARD.
// Monitor | Media | Weather | Calendar | Clipboard | Notifications.
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Hyprland
import "../core"

PanelWindow {
    id: left
    visible: AxoraState.panelLeftOpen
    anchors { left: true; top: true; bottom: true }
    margins { top: 0; bottom: 0; left: 10 }
    implicitWidth: 280
    color: "transparent"
    exclusiveZone: 280
    focusable: true

    property bool exiting: false
    function close() { exiting = true; AxoraState.panelLeftOpen = false }

    // weather glyph from wttr.in code (weather-icons, 4-digit escapes)
    function weatherGlyph(code) {
        if (code >= 200 && code !== 113 && code !== 116 && code !== 119 && code !== 122) {
            if (code === 200 || (code >= 386 && code <= 395)) return "\uDB81\uDD93"
        }
        if (code === 113) return "\uDB81\uDD99"
        if (code === 116) return "\uDB81\uDD95"
        if (code === 119 || code === 122) return "\uDB81\uDD90"
        if (code === 143 || code === 248 || code === 260) return "\uDB81\uDD91"
        if (code === 179 || code === 182 || code === 185) return "\uDB81\uDD98"
        if (code >= 227 && code <= 230) return "\uDB81\uDD98"
        if (code >= 320 && code <= 350) return "\uDB81\uDD98"
        if (code >= 362 && code <= 377) return "\uDB81\uDD98"
        if (code >= 392 && code <= 395) return "\uDB81\uDD93"
        return "\uDB81\uDD97"
    }

    Rectangle {
        anchors.fill: parent
        radius: AxoraMetrics.rPanel
        color: AxoraMaterials.panelGlass
        border.color: AxoraMaterials.border
        border.width: 1
        focus: true
        Keys.onEscapePressed: left.close()

        Flickable {
            anchors.fill: parent
            anchors.margins: AxoraMetrics.m + 4
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: dashCol.implicitHeight

            Column {
                id: dashCol
                width: parent.width
                spacing: AxoraMetrics.s

                // ════════════ HEADER (text-only identity: no logo plates) ════════════
                Row {
                    width: parent.width
                    spacing: AxoraMetrics.m
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30; height: 30; radius: 15
                        color: gearLeftHover.containsMouse ? AxoraMaterials.surface2 : "transparent"
                        Behavior on color { ColorAnimation { duration: AxoraMotion.fast } }
                        Text {
                            anchors.centerIn: parent
                            text: "\uDB81\uDC93"
                            font.family: AxoraTheme.fontMono
                            font.pixelSize: Math.round(13 * AxoraState.fontScale)
                            color: AxoraTheme.muted
                        }
                        MouseArea {
                            id: gearLeftHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { left.close(); AxoraState.settingsOpen = true }
                        }
                    }
                    Text {
                        id: sysLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SYSTEM"
                        color: AxoraTheme.accent
                        font.family: AxoraTheme.fontMono
                        font.pixelSize: Math.round(9 * AxoraState.fontScale)
                        font.letterSpacing: 2
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // live state, not the saved choice — on battery these differ
                        text: AxoraState.uptimeLine + "  ·  " + AxoraState.powerProfileLive.charAt(0).toUpperCase() + AxoraState.powerProfileLive.slice(1)
                        color: AxoraTheme.muted
                        font.family: AxoraTheme.fontMono
                        font.pixelSize: Math.round(7 * AxoraState.fontScale)
                        elide: Text.ElideRight
                        // was a hard 90px cap → "up 2h 14m · Perform…"; fill what the row leaves
                        width: parent.width - 30 - AxoraMetrics.m * 2 - sysLabel.width
                    }
                }

                // ════════════ SYSTEM MONITOR ════════════
                Column {
                    width: parent.width
                    spacing: AxoraMetrics.xs

                    // usage counters: CPU·RAM·GPU·DISK
                    Row {
                        width: parent.width
                        height: 24
                        spacing: 6
                        DashRow { label: "CPU"; glyph: "\uDB81\uDE1A"; value: AxoraState.cpuPct + "%"; danger: AxoraState.cpuPct > 80 }
                        DashRow { label: "RAM"; glyph: "\uDB80\uDF5B"; value: AxoraState.memPct + "%"; danger: AxoraState.memPct > 80 }
                        DashRow { label: "GPU"; glyph: "\uDB80\uDF79"; value: AxoraState.gpuUtil >= 0 ? AxoraState.gpuUtil + "%" : "—"; danger: AxoraState.gpuUtil > 80 }
                        DashRow { label: "DISK"; glyph: "\uDB80\uDECA"; value: AxoraState.diskPct + "%"; danger: AxoraState.diskPct > 85 }
                    }

                    // stat rows
                    Row {
                        width: parent.width; spacing: 6
                        DashRow { label: "CPU"; glyph: "\uDB81\uDE1A"; value: AxoraState.cpuPct + "%"; danger: AxoraState.cpuPct > 80 }
                        DashRow { label: "RAM"; glyph: "\uDB80\uDF5B"; value: AxoraState.memPct + "%"; danger: AxoraState.memPct > 80 }
                        DashRow { label: "SWAP"; glyph: "\uDB81\uDCE1"; value: AxoraState.swapPct + "%"; danger: AxoraState.swapPct > 60 }
                        DashRow { label: "DISK"; glyph: "\uDB80\uDECA"; value: AxoraState.diskPct + "%"; danger: AxoraState.diskPct > 85 }
                    }
                    Row {
                        width: parent.width; spacing: 6
                        DashRow { label: "GPU"; glyph: "\uDB80\uDF79"; value: AxoraState.gpuUtil >= 0 ? AxoraState.gpuUtil + "%" : "—"; danger: AxoraState.gpuUtil > 80 }
                        DashRow { label: "TEMP"; glyph: "\uDB81\uDD0F"; value: (AxoraState.pkgTemp > 0 ? AxoraState.pkgTemp : AxoraState.cpuTemp) + "°"; danger: (AxoraState.pkgTemp || AxoraState.cpuTemp) > 80 }
                        DashRow { label: "↓"; glyph: "\uDB83\uDCDB"; value: AxoraState.netDownKbs + "K"; danger: false }
                        DashRow { label: "↑"; glyph: "\uDB83\uDCE1"; value: AxoraState.netUpKbs + "K"; danger: false }
                    }
                    Row {
                        width: parent.width; spacing: 6
                        DashRow {
                            label: "BAT"; glyph: "\uDB80\uDC79"; glyphRotation: 90
                            danger: AxoraState.batteryPct >= 0 && AxoraState.batteryPct < 15
                            value: AxoraState.batteryPct >= 0 ? Math.round(AxoraState.batteryPct) + "%" : "—"
                        }
                        DashRow { label: "WATT"; glyph: "\uDB80\uDE41"; value: AxoraState.batWatts >= 0 ? AxoraState.batWatts.toFixed(1) + "W" : "—"; danger: false }
                        DashRow { label: "C°"; glyph: "\uDB81\uDD0F"; value: (AxoraState.cpuTemp > 0 ? AxoraState.cpuTemp : "—") + ""; danger: false }
                        DashRow { label: "P°"; glyph: "\uDB81\uDD0F"; value: (AxoraState.pkgTemp > 0 ? AxoraState.pkgTemp : "—") + ""; danger: false }
                    }
                    Text {
                        visible: AxoraState.gpuStr.indexOf("|") >= 0
                        width: parent.width
                        text: "VRAM " + AxoraState.gpuStr.split("|")[2] + "/" + AxoraState.gpuStr.split("|")[3] + " MiB · GPU " +
                              (AxoraState.gpuStr.split("|")[1] || "—") + "°C"
                        color: AxoraTheme.muted; font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                    }
                }

                SectionDivider {}

                // ════════════ MEDIA ════════════
                Column {
                    width: parent.width
                    spacing: AxoraMetrics.xs

                    Row {
                        width: parent.width
                        spacing: 8
                        Rectangle {
                            width: 44; height: 44; radius: 8
                            color: AxoraState.mediaArt ? "transparent" : AxoraTheme.field
                            border.color: AxoraMaterials.borderFaint; border.width: 1
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: AxoraState.mediaArt
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: AxoraState.mediaArt.length > 0
                            }
                            Text {
                                anchors.centerIn: parent
                                text: AxoraState.mediaPlaying ? "\uDB80\uDFE4" : "\uDB81\uDC0A"
                                visible: AxoraState.mediaArt.length === 0
                                color: AxoraTheme.tint(AxoraTheme.accent, "55")
                                font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(16 * AxoraState.fontScale)
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 52
                            spacing: 1
                            Text {
                                text: AxoraState.mediaTitle.length ? AxoraState.mediaTitle : "Nothing playing"
                                elide: Text.ElideRight; width: parent.width
                                color: AxoraState.mediaTitle.length ? AxoraTheme.text : AxoraTheme.tint(AxoraTheme.muted, "88")
                                font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(10 * AxoraState.fontScale); font.bold: AxoraState.mediaTitle.length > 0
                            }
                            Text {
                                text: AxoraState.mediaArtist
                                elide: Text.ElideRight; width: parent.width
                                color: AxoraTheme.muted; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale)
                            }
                            // seek slider — was a 2px non-interactive progress hairline
                            Rectangle {
                                id: seek
                                property real pct: AxoraState.mediaLen > 0
                                                     ? Math.min(1, AxoraState.mediaPos / AxoraState.mediaLen) * 100 : 0
                                width: parent.width; height: 10; radius: 5
                                color: AxoraTheme.tint(AxoraTheme.muted, "26")
                                Rectangle {
                                    width: Math.max(parent.height, parent.width * (seek.pct / 100))
                                    height: parent.height; radius: parent.radius
                                    color: AxoraTheme.accent
                                    Behavior on width {
                                        NumberAnimation { duration: AxoraMotion.fast; easing.type: Easing.OutCubic }
                                    }
                                }
                                // 26px hit band, same as the other sliders: the visible
                                // bar is 10px but you must not have to aim at it.
                                MouseArea {
                                    anchors.centerIn: parent
                                    width: parent.width; height: 26
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: (m) => { if (m.buttons & Qt.LeftButton) seekTo(m) }
                                    onClicked: (m) => seekTo(m)
                                    function seekTo(m) {
                                        if (AxoraState.mediaLen > 0)
                                            AxoraState.mediaSeek(Math.max(0, Math.min(100, m.x / seek.width * 100)))
                                    }
                                }
                            }
                        }
                    }

                    // controls
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: AxoraMetrics.xl
                        MediaBtn { glyph: "\uDB81\uDCAB"; onClicked: AxoraState.mediaPrev() }
                        MediaBtn {
                            glyph: AxoraState.mediaPlaying ? "\uDB80\uDFE4" : "\uDB81\uDC0A"
                            primary: true
                            onClicked: AxoraState.mediaTogglePlay()
                        }
                        MediaBtn { glyph: "\uDB81\uDCAC"; onClicked: AxoraState.mediaNext() }
                    }
                }

                SectionDivider {}

                // ════════════ WEATHER ════════════
                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: left.weatherGlyph(AxoraState.weatherCode)
                        color: AxoraTheme.accent; font.family: AxoraTheme.fontMono
                        font.pixelSize: Math.round(26 * AxoraState.fontScale)
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 44
                        spacing: 1
                        Row {
                            width: parent.width; spacing: 6
                            Text { text: AxoraState.weatherTemp + "°C"; color: AxoraTheme.text; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(17 * AxoraState.fontScale); font.bold: true }
                            Text { text: "feels " + AxoraState.weatherFeels + "°"; color: AxoraTheme.muted; anchors.verticalCenter: parent.verticalCenter; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale) }
                        }
                        Text {
                            text: (AxoraState.weatherDesc.length ? AxoraState.weatherDesc : "offline") +
                                  (AxoraState.weatherCode !== 0 ? "  ·  \uDB81\uDD8E " + AxoraState.weatherHum + "%  ·  \uDB81\uDD9D " + AxoraState.weatherWind + " km/h" : "")
                            elide: Text.ElideRight; width: parent.width
                            color: AxoraTheme.muted; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale)
                        }
                    }
                }

                SectionDivider {}

                // ════════════ CALENDAR ════════════
                DashCalendar {}

                SectionDivider {}

                // ════════════ CLIPBOARD ════════════
                Column {
                    width: parent.width
                    spacing: AxoraMetrics.xs
                    Row {
                        width: parent.width
                        Text { text: "CLIPBOARD"; color: AxoraTheme.muted; font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale); font.letterSpacing: 1 }
                        Item { width: 12; height: 1 }
                        Text { text: "· " + AxoraState.clipList.length; color: AxoraTheme.tint(AxoraTheme.muted, "88"); font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(8 * AxoraState.fontScale); anchors.verticalCenter: parent.verticalCenter }
                    }
                    ListView {
                        id: clipView
                        width: parent.width
                        height: clipView.count * 24
                        interactive: false
                        model: AxoraState.clipList.slice(0, 6)
                        delegate: Item {
                            required property var modelData
                            width: clipView.width; height: 24
                            Rectangle {
                                anchors.fill: parent; radius: 5
                                color: h.containsMouse ? AxoraMaterials.tileGlass : "transparent"
                            }
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 6; anchors.right: parent.right; anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                elide: Text.ElideRight
                                color: h.containsMouse ? AxoraTheme.accent : AxoraTheme.text
                                font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                            }
                            MouseArea {
                                id: h; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { AxoraState.copyClip(modelData.run); AxoraState.exec("notify-send 'Clipboard' 'Copied to clipboard'" + "") }
                            }
                        }
                    }
                    Text {
                        visible: AxoraState.clipList.length === 0
                        width: parent.width
                        text: "Nothing copied yet"; color: AxoraTheme.tint(AxoraTheme.muted, "66")
                        font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(9 * AxoraState.fontScale)
                    }
                }
            }
        }
    }

    // ── reusable dashboard pieces ──
    component DashRow: Rectangle {
        property string label: "?"
        property string glyph: ""
        property string value: "—"
        property bool danger: false
        property int glyphRotation: 0
        width: (parent.width - 18) / 4
        height: 24
        radius: 6
        color: danger ? AxoraTheme.danger : AxoraTheme.field
        border.width: 1
        border.color: danger ? "transparent" : AxoraMaterials.borderFaint
        Row {
            anchors.centerIn: parent
            anchors.leftMargin: 5; anchors.rightMargin: 5
            spacing: 3
            // rotation-aware slot: a rotated glyph is as wide as it is tall, so
            // size the wrapper off implicitHeight or the label collides with it
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: dgTxt.implicitHeight; height: dgTxt.implicitHeight
                Text {
                    id: dgTxt
                    anchors.centerIn: parent
                    rotation: danger ? 0 : glyphRotation
                    text: danger ? "\uDB80\uDC28" : glyph
                    color: danger ? "#04140d" : AxoraTheme.accent
                    font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                }
            }
            Text {
                text: danger ? label : value
                anchors.verticalCenter: parent.verticalCenter
                color: danger ? "#04140d" : AxoraTheme.text
                font.family: AxoraTheme.fontMono; font.pixelSize: Math.round(8 * AxoraState.fontScale); font.bold: true
                elide: Text.ElideRight
            }
        }
    }

    component MediaBtn: Rectangle {
        signal clicked()
        property string glyph: "\uDB81\uDC0A"
        property bool primary: false
        width: primary ? 38 : 30; height: width; radius: primary ? 19 : 15
        color: primary ? AxoraTheme.accent : AxoraMaterials.surface2
        border.color: primary ? "transparent" : AxoraMaterials.borderFaint
        border.width: primary ? 0 : 1
        Text {
            anchors.centerIn: parent
            text: parent.glyph
            color: parent.primary ? AxoraTheme.textOnAccent : (h.containsMouse ? AxoraTheme.accent : AxoraTheme.text)
            font.family: AxoraTheme.fontMono; font.pixelSize: Math.round((parent.primary ? 16 : 13) * AxoraState.fontScale)
        }
        MouseArea {
            id: h; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component SectionDivider: Rectangle {
        width: left.width - 32
        height: 1
        color: AxoraTheme.tint(AxoraTheme.muted, "18")
        opacity: 0.6
    }

    // compact month calendar with live clock
    component DashCalendar: Column {
        width: parent.width
        spacing: 6
        readonly property date calDate: new Date()
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
        Row {
            width: parent.width
            Text {
                text: Qt.formatDate(calDate, "MMMM yyyy").toUpperCase()
                color: AxoraTheme.text; font.family: AxoraTheme.fontUI
                font.pixelSize: Math.round(10 * AxoraState.fontScale); font.bold: true; font.letterSpacing: 1
            }
            Item { width: 12; height: 1 }
            SystemClock { id: calClock; precision: SystemClock.Minutes }
            Text {
                text: Qt.formatTime(calClock.date, "HH:mm")
                color: AxoraTheme.accent; font.family: AxoraTheme.fontMono
                font.pixelSize: Math.round(12 * AxoraState.fontScale)
            }
        }
        Grid {
            columns: 7; columnSpacing: 3; rowSpacing: 3
            width: parent.width
            Repeater {
                model: ["MO","TU","WE","TH","FR","SA","SU"]
                Text {
                    width: 24; height: 14
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: AxoraTheme.tint(AxoraTheme.muted, "88"); font.family: AxoraTheme.fontUI
                    font.pixelSize: Math.round(7 * AxoraState.fontScale)
                }
            }
        }
        Grid {
            columns: 7; columnSpacing: 3; rowSpacing: 3
            width: parent.width
            Repeater {
                model: calCells()
                Rectangle {
                    required property int modelData
                    readonly property bool isToday: modelData !== 0 && modelData === (new Date()).getDate() && calDate.getMonth() === (new Date()).getMonth()
                    readonly property bool hasDay: modelData !== 0
                    width: 24; height: 22
                    radius: 6
                    color: isToday ? AxoraMaterials.surface2 : "transparent"
                    border.width: isToday ? 1 : 0
                    border.color: isToday ? AxoraTheme.accent : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: modelData === 0 ? "" : String(modelData)
                        color: isToday ? AxoraTheme.accent : AxoraTheme.text
                        font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(8 * AxoraState.fontScale)
                        font.bold: isToday
                    }
                }
            }
        }
    }
}