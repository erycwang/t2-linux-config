import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: "MEM " + Mem.usage + "%"
    color: Mem.usage >= 80 ? Colors.red
         : Mem.usage >= 50 ? Colors.yellow
         : Colors.green
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
