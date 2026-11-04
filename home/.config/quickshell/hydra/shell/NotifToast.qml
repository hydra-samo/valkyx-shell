// VALKYX NotifToast — branded transient for new notifications.
// Uses brand icon instead of word labels.
import Quickshell
import QtQuick
import QtQuick.Layouts
import "../core"

PanelWindow {
    id: toast
    visible: ValkyxState.toastVisible
    anchors { top: true; right: true }
    margins { top: ValkyxMetrics.topGap + 6; right: ValkyxMetrics.edgeGap }
    implicitWidth: 300
    implicitHeight: toastCol.implicitHeight + 24
    color: "transparent"
    exclusiveZone: -1

    Rectangle {
        anchors.fill: parent
        radius: ValkyxMetrics.rTile
        color: ValkyxMaterials.panelGlass
        border.color: ValkyxTheme.accent
        border.width: 1

        Column {
            id: toastCol
            anchors.fill: parent
            anchors.margins: ValkyxMetrics.m
            spacing: 3
            Row {
                spacing: ValkyxMetrics.s
                Text {
                    text: ValkyxState.toastGlyph
                    color: ValkyxTheme.accent
                    font.family: ValkyxTheme.fontMono
                    font.pixelSize: Math.round(10 * ValkyxState.fontScale)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    width: 230
                    elide: Text.ElideRight
                    text: ValkyxState.toastApp !== "" ? ValkyxState.toastApp : ""
                    color: ValkyxTheme.accent
                    font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(10 * ValkyxState.fontScale); font.letterSpacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                width: parent.width; elide: Text.ElideRight; wrapMode: Text.Wrap
                maximumLineCount: 2
                text: ValkyxState.toastSummary
                color: ValkyxTheme.text
                font.family: ValkyxTheme.fontUI; font.pixelSize: Math.round(12 * ValkyxState.fontScale)
            }
        }
    }
}
