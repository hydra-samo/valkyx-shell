// HYDRA NotifToast — branded transient for new notifications.
// Uses brand icon instead of word labels.
import Quickshell
import QtQuick
import QtQuick.Layouts
import "../core"

PanelWindow {
    id: toast
    visible: HydraState.toastVisible
    anchors { top: true; right: true }
    margins { top: HydraMetrics.topGap + 6; right: HydraMetrics.edgeGap }
    implicitWidth: 300
    implicitHeight: toastCol.implicitHeight + 24
    color: "transparent"
    exclusiveZone: -1

    Rectangle {
        anchors.fill: parent
        radius: HydraMetrics.rTile
        color: HydraMaterials.panelGlass
        border.color: HydraTheme.accent
        border.width: 1

        Column {
            id: toastCol
            anchors.fill: parent
            anchors.margins: HydraMetrics.m
            spacing: 3
            Row {
                spacing: HydraMetrics.s
                Text {
                    text: HydraState.toastGlyph
                    color: HydraTheme.accent
                    font.family: HydraTheme.fontMono
                    font.pixelSize: Math.round(10 * HydraState.fontScale)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    width: 230
                    elide: Text.ElideRight
                    text: HydraState.toastApp !== "" ? HydraState.toastApp : ""
                    color: HydraTheme.accent
                    font.family: HydraTheme.fontUI; font.pixelSize: Math.round(10 * HydraState.fontScale); font.letterSpacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                width: parent.width; elide: Text.ElideRight; wrapMode: Text.Wrap
                maximumLineCount: 2
                text: HydraState.toastSummary
                color: HydraTheme.text
                font.family: HydraTheme.fontUI; font.pixelSize: Math.round(12 * HydraState.fontScale)
            }
        }
    }
}
