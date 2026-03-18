import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: Temp.temp + "°"
    color: Temp.temp >= 80 ? "#f38ba8"
         : Temp.temp >= 60 ? "#f9e2af"
         : "#a6e3a1"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
