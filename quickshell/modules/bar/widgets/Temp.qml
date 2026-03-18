import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: Temp.temp + "°"
    color: Temp.temp >= 80 ? Colors.red
         : Temp.temp >= 60 ? Colors.yellow
         : Colors.green
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
