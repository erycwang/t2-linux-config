import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../config"

RowLayout {
    spacing: 4

    Text {
        text: {
            if (!Wifi.connected) return "xxx"
            let s = Wifi.signal
            let b1 = "▃"
            let b2 = s >= 40 ? "▅" : "░"
            let b3 = s >= 70 ? "█" : "░"
            return b1 + b2 + b3
        }
        color: Wifi.connected ? Colors.fg : Colors.red
        font.pixelSize: Config.fontSize
        font.family: Config.fontFamily
    }

    Text {
        text: {
            if (!Wifi.connected) return "NO NETWORK"
            let name = Wifi.ssid
            return name.length > 12 ? name.substring(0, 12) + "…" : name
        }
        color: Wifi.connected ? Colors.fg : Colors.red
        font.pixelSize: Config.fontSize
        font.family: Config.fontFamily
    }
}
