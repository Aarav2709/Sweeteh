import QtQuick
import qs.theme

// single line text input on a rounded surface
Rectangle {
    id: root

    property alias text: textInput.text
    property alias input: textInput
    property string placeholder
    property string icon
    property bool password: false
    // search style fields skip the focus ring
    property bool outlineOnFocus: true

    signal accepted
    signal edited

    function focusInput(): void {
        textInput.forceActiveFocus();
    }

    implicitHeight: Theme.size.buttonLarge
    implicitWidth: 240
    radius: height / 2
    color: Theme.color.layer2
    border.width: textInput.activeFocus && outlineOnFocus ? 2 : 0
    border.color: Theme.color.primary

    Icon {
        id: lead

        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.large
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        color: textInput.activeFocus ? Theme.color.primary : Theme.color.inkMeta
    }

    TextInput {
        id: textInput

        anchors.left: lead.visible ? lead.right : parent.left
        anchors.right: parent.right
        anchors.leftMargin: lead.visible ? Theme.spacing.medium : Theme.spacing.large
        anchors.rightMargin: Theme.spacing.large
        anchors.verticalCenter: parent.verticalCenter
        // a password is typed under the shapes, the field keeps the text and the keys
        color: root.password ? "transparent" : Theme.color.ink
        cursorDelegate: root.password ? hiddenCursor : null
        selectionColor: Theme.color.primary
        selectedTextColor: Theme.color.fgPrimary
        font.family: Theme.font.family
        font.variableAxes: ({
                "ROND": Theme.font.round
            })
        font.pixelSize: Theme.font.body
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"
        clip: true
        autoScroll: activeFocus
        selectByMouse: true
        onAccepted: root.accepted()
        onTextEdited: root.edited()

        Component {
            id: hiddenCursor

            Item {}
        }

        PasswordShapes {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.password
            count: root.password ? textInput.length : 0
            size: Theme.font.body + 2
        }

        Label {
            anchors.fill: parent
            visible: textInput.text === ""
            text: root.placeholder
            color: Theme.color.inkFaint
            font.pixelSize: Theme.font.body
        }
    }
}
