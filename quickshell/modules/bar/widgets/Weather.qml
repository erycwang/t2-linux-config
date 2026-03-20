import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../config"

RowLayout {
    spacing: 4

    Text {
        text:           Weather.valid ? Weather.icon : "\ue312"
        color:          Weather.valid ? Colors.fg : Colors.muted
        font.pixelSize: Config.fontSize + 2
        font.family:    Config.fontFamily
    }

    Text {
        text:           Weather.valid ? Weather.temperature + "°" : "--°"
        color:          Weather.valid ? Colors.fg : Colors.muted
        font.pixelSize: Config.fontSize
        font.family:    Config.fontFamily
    }

    Text {
        text:           Weather.valid ? Weather.city : ""
        color:          Colors.muted
        font.pixelSize: Config.fontSize
        font.family:    Config.fontFamily
        visible:        Weather.valid && Weather.city !== ""
    }
}
