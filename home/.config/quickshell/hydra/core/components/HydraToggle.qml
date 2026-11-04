// VALKYX Toggle — glassmorphic on/off switch.
// Usage: ValkyxToggle { checked: true; onToggled: doSomething() }
import QtQuick
import ".."

Rectangle {
    id: toggle
    width: 44; height: 24; radius: 12
    property bool checked: false
    signal toggled(bool checked)

    color: checked ? ValkyxTheme.tint(ValkyxTheme.muted, "66") : ValkyxTheme.tint(ValkyxTheme.muted, "33")

    Rectangle {
        x: toggle.checked ? 22 : 2; y: 2; width: 20; height: 20; radius: 10
        color: ValkyxTheme.text
    }

    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: { toggle.checked = !toggle.checked; toggle.toggled(toggle.checked) }
    }
}
