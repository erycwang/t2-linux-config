import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: "MEM " + Mem.usage + "%"
    color: Mem.usage >= 80 ? "#ff757f"
         : Mem.usage >= 50 ? "#ffc777"
         : "#c3e88d"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
