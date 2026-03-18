import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: (Battery.charging ? "↑" : "") + Battery.percentage + "%"
    color: Battery.charging ? Colors.green
         : Battery.percentage < 15 ? Colors.red
         : Battery.percentage < 30 ? Colors.orange
         : Colors.fg
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
