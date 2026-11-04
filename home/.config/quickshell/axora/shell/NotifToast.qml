// AXORA NotifToast — branded transient for new notifications.
// Uses brand icon instead of word labels.
import Quickshell
import QtQuick
import QtQuick.Layouts
import "../core"

PanelWindow {
    id: toast
    visible: AxoraState.toastVisible
    anchors { top: true; right: true }
    margins { top: AxoraMetrics.topGap + 6; right: AxoraMetrics.edgeGap }
    implicitWidth: 300
    implicitHeight: toastCol.implicitHeight + 24
    color: "transparent"
    exclusiveZone: -1

    Rectangle {
        anchors.fill: parent
        radius: AxoraMetrics.rTile
        color: AxoraMaterials.panelGlass
        border.color: AxoraTheme.accent
        border.width: 1

        Column {
            id: toastCol
            anchors.fill: parent
            anchors.margins: AxoraMetrics.m
            spacing: 3
            Row {
                spacing: AxoraMetrics.s
                Text {
                    text: AxoraState.toastGlyph
                    color: AxoraTheme.accent
                    font.family: AxoraTheme.fontMono
                    font.pixelSize: Math.round(10 * AxoraState.fontScale)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    width: 230
                    elide: Text.ElideRight
                    text: AxoraState.toastApp !== "" ? AxoraState.toastApp : ""
                    color: AxoraTheme.accent
                    font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(10 * AxoraState.fontScale); font.letterSpacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                width: parent.width; elide: Text.ElideRight; wrapMode: Text.Wrap
                maximumLineCount: 2
                text: AxoraState.toastSummary
                color: AxoraTheme.text
                font.family: AxoraTheme.fontUI; font.pixelSize: Math.round(12 * AxoraState.fontScale)
            }
        }
    }
}
