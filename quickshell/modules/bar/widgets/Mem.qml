import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: "MEM " + Mem.usage + "%"
    color: Mem.usage >= 80 ? "#f38ba8"
         : Mem.usage >= 50 ? "#f9e2af"
         : "#a6e3a1"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
