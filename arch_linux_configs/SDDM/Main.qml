import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    focus: true

    readonly property string userName: "alex"
    readonly property url wallpaper: Qt.resolvedUrl("cherry_bloom_wallpaper_blur.jpg")

    readonly property string fontFamily: "Monospace"

    // Palette close to hyprlock
    readonly property color fg: "#fff2f2f2"
    readonly property color muted: "#ffb8b6bb"
    readonly property color accent: "#ffd24b5b"
    // You had accent2 in hyprlock; pick something sane unless you provide it.
    readonly property color accent2: "#ff9b3440"

    readonly property color clockColor: "#25f2f2f2"
    readonly property int inputFieldWidth: 347
    readonly property int inputFieldHeight: 43
    readonly property int inputFieldRadius: 15
    readonly property int inputFieldBottomMargin: 53
    
    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    function login() {
        var si = sessionModel.lastIndex
        if (si < 0) si = 0
        sddm.login(root.userName, passwordField.text, si)
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.login()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            passwordField.text = ""
            event.accepted = true
        }
    }

    Image {
        id: bg
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    Text {
        id: clockText
        text: Qt.formatTime(root.now, "hh:mm")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
	anchors.topMargin: 146

        font.pixelSize: 230
        
	font.family: "JetBrainsMono Nerd Font Mono"
	font.weight: Font.ExtraBold
	font.bold: true	

        color: clockColor

        layer.enabled: true
        layer.effect: DropShadow {
            radius: 10
            samples: 20
            horizontalOffset: 0
            verticalOffset: 0
            color: "#dd000000"
        }
    }


    Rectangle {
        id: passwordBox
        width: root.inputFieldWidth
        height: root.inputFieldHeight
        radius: root.inputFieldRadius

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.inputFieldBottomMargin

        color: "#990b0f14"

        TextField {
    id: passwordField
    anchors.fill: parent

    // padding instead of shrinking the control
    leftPadding: 20
    rightPadding: 20
    topPadding: 10
    bottomPadding: 10

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    cursorDelegate: Item { }

    echoMode: TextInput.Password
    // if you want a specific character:
    // passwordCharacter: "•"
    // passwordMaskDelay: 0

    background: null

    font.family: root.fontFamily
    font.pixelSize: 16
    color: root.fg
    placeholderText: ""

    focus: true
    Component.onCompleted: forceActiveFocus()
}
    }

    // Keyboard layout label above input
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: passwordBox.top
        anchors.bottomMargin: 30

        font.pixelSize: 12
        font.family: root.fontFamily
        color: root.muted
        text: keyboard.layouts.length > 0 ? keyboard.layouts[keyboard.currentLayout].longName : ""
        horizontalAlignment: Text.AlignHCenter

        layer.enabled: true
        layer.effect: DropShadow {
            radius: 4
            samples: 12
            horizontalOffset: 0
            verticalOffset: 0
            color: "#aa000000"
        }
    }

    Connections {
        target: sddm
        onLoginFailed: {
            passwordField.text = ""
            // hyprlock fail_color ~= accent; you used a brighter red before
            passwordBox.border.color = "#ff4b5b"
            glowBox.border.color = "#ff4b5b"
            passwordField.forceActiveFocus()
        }
    }
}
