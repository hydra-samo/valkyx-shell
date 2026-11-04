import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    color: "#0d1310"
    property bool loginFailedFlag: false
    readonly property string loginUser: sddm.user || "valkyxsamo"

    function hexToRgba(hex, alpha) {
        var h = (hex && String(hex).replace("#", "")) || "00A86B"
        if (h.length < 6) h = "00A86B"
        return Qt.rgba(
            parseInt(h.substring(0, 2), 16) / 255,
            parseInt(h.substring(2, 4), 16) / 255,
            parseInt(h.substring(4, 6), 16) / 255,
            alpha)
    }
    readonly property color accent: hexToRgba(config.accent, 1)
    readonly property color textC: Qt.rgba(0.91, 0.95, 0.93, 1)
    readonly property color mutedC: Qt.rgba(0.91, 0.95, 0.93, 0.45)

    Text {
        id: clockText
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 18
        anchors.rightMargin: 22
        color: root.mutedC
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm")
        }
        Component.onCompleted: text = Qt.formatDateTime(new Date(), "HH:mm")
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "VALKYX"
            color: root.accent
            font.family: "GohuFont uni14 Nerd Font Propo"
            font.pixelSize: 70
            font.weight: Font.Normal
            font.letterSpacing: 0
        }
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            width: 46
            height: 2
            color: root.mutedC
            opacity: 0.4
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -6
            text: "LABS"
            color: root.mutedC
            font.family: "Rubik"
            font.pixelSize: 15
            font.weight: Font.Medium
            font.letterSpacing: 10
        }
        Item {
            id: passwordRow
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 28
            width: 300
            height: 44

            Rectangle {
                id: fieldBorder
                anchors.fill: parent
                radius: 22
                color: Qt.rgba(0.91, 0.95, 0.93, 0.06)
                border.color: password.activeFocus
                    ? root.accent
                    : (root.loginFailedFlag ? Qt.rgba(0.85, 0.31, 0.35, 0.8) : Qt.rgba(0.91, 0.95, 0.93, 0.28))
                border.width: 1
            }
            Text {
                id: lockGlyph
                anchors.left: parent.left
                anchors.leftMargin: 15
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf023"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: password.activeFocus ? root.accent : root.mutedC
            }
            TextField {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 40
                anchors.rightMargin: 12
                focus: true
                echoMode: TextInput.Password
                font.family: "Rubik"
                font.pixelSize: 14
                color: root.textC
                placeholderText: "password"
                placeholderTextColor: root.mutedC
                background: Item {}
                onAccepted: doLogin()
                onTextChanged: root.loginFailedFlag = false
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            visible: root.loginFailedFlag
            text: "Try again"
            color: Qt.rgba(0.85, 0.31, 0.35, 0.9)
            font.family: "Rubik"
            font.pixelSize: 12
        }
    }

    Column {
        id: bottomLeft
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 22
        anchors.bottomMargin: 20
        spacing: 2

        Text {
            color: root.mutedC
            font.family: "Rubik"
            font.pixelSize: 13
            font.weight: Font.Medium
            text: root.loginUser
        }
        Text {
            color: root.mutedC
            opacity: 0.7
            font.family: "Rubik"
            font.pixelSize: 10
            text: sessionBox.currentText ? sessionBox.currentText : "default session"
        }
    }

    ComboBox {
        id: sessionBox
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 8
        model: sessionModel
        textRole: "name"
        currentIndex: sessionModel ? sessionModel.lastIndex : 0
        implicitWidth: 130
        implicitHeight: 22
        opacity: 0.75
        background: Rectangle {
            color: "transparent"
            border.color: Qt.rgba(0.91, 0.95, 0.93, 0.2)
            border.width: 1
        }
        contentItem: Text {
            text: parent.displayText
            color: root.mutedC
            font.family: "Rubik"
            font.pixelSize: 9
            font.letterSpacing: 1
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        popup: Popup {
            y: -sessionBox.height - 2
            width: sessionBox.width
            implicitHeight: contentItem.implicitHeight
            padding: 1
            background: Rectangle {
                color: "#111b17"
                border.color: Qt.rgba(0.91, 0.95, 0.93, 0.25)
                border.width: 1
            }
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: sessionBox.popup.visible ? sessionModel : null
                currentIndex: sessionBox.highlightedIndex
                delegate: ItemDelegate {
                    width: sessionBox.width
                    height: 26
                    contentItem: Text {
                        text: name
                        color: sessionBox.highlightedIndex === index ? root.accent : root.textC
                        font.family: "Rubik"
                        font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle { color: "transparent" }
                }
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 22
        anchors.bottomMargin: 16
        spacing: 16

        Item {
            id: pwBtn
            width: 22
            height: 18
            property bool hovering: false
            Text {
                anchors.fill: parent
                text: "\uf011"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                color: pwBtn.hovering ? Qt.rgba(0.85, 0.31, 0.35, 1) : root.mutedC
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: pwBtn.hovering = true
                onExited: pwBtn.hovering = false
                onClicked: sddm.powerOff()
            }
        }
        Item {
            id: slBtn
            width: 22
            height: 18
            property bool hovering: false
            Text {
                anchors.fill: parent
                text: "\uf186"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                color: slBtn.hovering ? root.accent : root.mutedC
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: slBtn.hovering = true
                onExited: slBtn.hovering = false
                onClicked: sddm.suspend()
            }
        }
        Item {
            id: rbBtn
            width: 22
            height: 18
            property bool hovering: false
            Text {
                anchors.fill: parent
                text: "\uf021"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                color: rbBtn.hovering ? root.accent : root.mutedC
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: rbBtn.hovering = true
                onExited: rbBtn.hovering = false
                onClicked: sddm.reboot()
            }
        }
    }

    function doLogin() {
        var sess = (sessionBox.currentIndex >= 0) ? sessionBox.currentIndex : 0
        sddm.login(root.loginUser, password.text, sess)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginFailedFlag = true
            password.selectAll()
            password.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        console.log("THEME-LOADED-MARKER")
        password.forceActiveFocus()
    }
}