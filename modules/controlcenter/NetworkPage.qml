import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// wifi networks, secured ones ask for a password inline
DevicePage {
    id: root

    property string asking: ""

    title: "Wifi"
    icon: "wifi"
    on: Network.wifiEnabled
    empty: Network.wifiEnabled ? "Searching for networks." : "Wifi is off."
    model: Network.networks
    onSwitched: on => Network.setWifi(on)
    Component.onCompleted: Network.scan(true)
    Component.onDestruction: Network.scan(false)

    delegate: Column {
        id: row

        required property var modelData
        readonly property bool known: Network.known.includes(modelData.name)
        readonly property bool busy: Network.connecting === modelData.name

        width: ListView.view.width
        spacing: Theme.spacing.xs

        ListRow {
            width: parent.width
            icon: row.modelData.strength > 0.66 ? "network_wifi" : row.modelData.strength > 0.33 ? "network_wifi_2_bar" : "network_wifi_1_bar"
            title: row.modelData.name
            subtitle: row.busy ? "Connecting" : Network.failed === row.modelData.name ? "Could not connect" : row.modelData.connected ? "Connected" : row.known ? "Saved" : row.modelData.secured ? "Secured" : "Open"
            selected: row.modelData.connected
            onClicked: {
                if (row.modelData.connected)
                    Network.disconnect();
                else if (row.modelData.secured && !row.known) {
                    root.asking = root.asking === row.modelData.name ? "" : row.modelData.name;
                    psk.text = "";
                    psk.focusInput();
                } else
                    Network.connect(row.modelData.name, "");
            }
            onRightClicked: {
                if (row.known)
                    Network.forget(row.modelData.name);
            }

            Icon {
                visible: row.modelData.secured
                name: "lock"
                size: Theme.font.large
                color: Theme.color.inkFaint
            }
        }

        Field {
            id: psk

            width: parent.width
            visible: root.asking === row.modelData.name
            password: true
            icon: "key"
            placeholder: "Password"
            onAccepted: {
                Network.connect(row.modelData.name, text);
                root.asking = "";
            }
        }
    }
}
