import QtQuick
import Quickshell.Bluetooth
import "../../../config"

Text {
    property int connectedCount: {
        let count = 0
        for (const d of Bluetooth.devices.values) {
            if (d.connected) count++
        }
        return count
    }

    visible: connectedCount > 0
    width: visible ? implicitWidth : 0

    text: "BT: " + connectedCount
    color: "#cdd6f4"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
