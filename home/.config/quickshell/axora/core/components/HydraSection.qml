// AXORA Section — accent-colored section header.
// Usage: AxoraSection { text: "DISPLAY" }
import QtQuick
import ".."

Text {
    property string label: ""
    text: label.toUpperCase()
    color: AxoraTheme.accent
    font.family: AxoraTheme.fontMono
    font.pixelSize: Math.round(10 * AxoraState.fontScale)
    font.letterSpacing: 1
}
