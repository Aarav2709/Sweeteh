import QtQuick
import qs.theme
import qs.services
import qs.components

// paired and nearby bluetooth devices
DevicePage {
    id: root

    title: "Bluetooth"
    icon: "bluetooth"
    on: BluetoothState.enabled
    empty: !BluetoothState.available ? "Bluetooth is not running, switch it on to start it." : BluetoothState.enabled ? "Searching for devices." : "Bluetooth is off."
    model: BluetoothState.devices.filter(d => root.matches(d.name || d.deviceName))
    onSwitched: on => BluetoothState.setEnabled(on)
    Component.onCompleted: BluetoothState.discover(true)
    Component.onDestruction: BluetoothState.discover(false)

    delegate: ListRow {
        id: row

        required property var modelData

        width: ListView.view.width
        icon: modelData.icon.includes("audio") || modelData.icon.includes("headset") ? "headphones" : modelData.icon.includes("input") ? "mouse" : modelData.icon.includes("phone") ? "smartphone" : "bluetooth"
        title: modelData.name || modelData.address
        subtitle: BluetoothState.busy === modelData.address ? (modelData.connected ? "Disconnecting" : "Connecting") : modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available"
        selected: modelData.connected
        onClicked: {
            if (BluetoothState.busy !== "")
                return;
            if (row.modelData.connected)
                BluetoothState.disconnect(row.modelData);
            else
                BluetoothState.connect(row.modelData);
        }
        onRightClicked: {
            if (row.modelData.paired)
                BluetoothState.forget(row.modelData);
        }

        Label {
            visible: row.modelData.batteryAvailable
            text: Math.round(row.modelData.battery * 100) + "%"
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
            color: row.foreground
        }
    }
}
