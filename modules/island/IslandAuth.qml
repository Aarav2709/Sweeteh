import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// password prompt for an app that asks for admin rights
ColumnLayout {
    id: root

    function reset(): void {
        field.text = "";
        field.focusInput();
    }

    width: 420
    spacing: Theme.spacing.medium

    RowLayout {
        spacing: Theme.spacing.medium

        Rectangle {
            implicitWidth: 44
            implicitHeight: 44
            radius: Theme.radius.medium
            color: Theme.color.primaryContainer

            Icon {
                anchors.centerIn: parent
                name: "admin_panel_settings"
                fill: 1
                color: Theme.color.fgPrimaryContainer
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                text: "Authentication needed"
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                text: Auth.flow?.message ?? ""
                wrapMode: Text.Wrap
                maximumLineCount: 3
                font.pixelSize: Theme.font.small
                color: Theme.color.inkMeta
            }
        }
    }

    Field {
        id: field

        Layout.fillWidth: true
        color: Theme.color.layer1
        password: !(Auth.flow?.responseVisible ?? false)
        icon: "key"
        placeholder: Auth.flow?.inputPrompt.replace(/:\s*$/, "") || "Password"
        onAccepted: {
            Auth.submit(text);
            text = "";
        }
        input.Keys.onEscapePressed: Auth.cancel()
    }

    Label {
        Layout.fillWidth: true
        visible: text !== ""
        text: Auth.flow?.supplementaryMessage ?? ""
        wrapMode: Text.Wrap
        font.pixelSize: Theme.font.small
        color: Auth.flow?.supplementaryIsError ? Theme.color.error : Theme.color.inkMeta
    }

    RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: Theme.spacing.small

        Button {
            variant: "neutral"
            text: "Cancel"
            onClicked: Auth.cancel()
        }

        Button {
            variant: "filled"
            icon: "lock_open"
            text: "Allow"
            onClicked: {
                Auth.submit(field.text);
                field.text = "";
            }
        }
    }
}
