import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: Temp.temp + "°"
    color: Temp.temp >= 80 ? "#ff757f"
         : Temp.temp >= 60 ? "#ffc777"
         : "#c3e88d"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
