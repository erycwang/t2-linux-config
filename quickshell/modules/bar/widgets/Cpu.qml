import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: "CPU " + Cpu.usage + "%"
    color: Cpu.usage >= 80 ? "#ff757f"
         : Cpu.usage >= 50 ? "#ffc777"
         : "#c3e88d"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
