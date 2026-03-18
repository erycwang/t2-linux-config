import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: (Battery.charging ? "↑" : "") + Battery.percentage + "%"
    color: Battery.percentage < 15 ? "#f38ba8"
         : Battery.percentage < 30 ? "#fab387"
         : "#cdd6f4"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
