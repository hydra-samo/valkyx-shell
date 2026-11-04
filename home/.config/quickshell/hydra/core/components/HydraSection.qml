// HYDRA Section — accent-colored section header.
// Usage: HydraSection { text: "DISPLAY" }
import QtQuick
import ".."

Text {
    property string label: ""
    text: label.toUpperCase()
    color: HydraTheme.accent
    font.family: HydraTheme.fontMono
    font.pixelSize: Math.round(10 * HydraState.fontScale)
    font.letterSpacing: 1
}
