import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: (Battery.charging ? "↑" : "") + Battery.percentage + "%"
    color: Battery.charging ? "#c3e88d"
         : Battery.percentage < 15 ? "#ff757f"
         : Battery.percentage < 30 ? "#ff966c"
         : "#c8d3f5"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
