// VALKYX Section — accent-colored section header.
// Usage: ValkyxSection { text: "DISPLAY" }
import QtQuick
import ".."

Text {
    property string label: ""
    text: label.toUpperCase()
    color: ValkyxTheme.accent
    font.family: ValkyxTheme.fontMono
    font.pixelSize: Math.round(10 * ValkyxState.fontScale)
    font.letterSpacing: 1
}
