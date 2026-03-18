import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: "CPU " + Cpu.usage + "%"
    color: Cpu.usage >= 80 ? "#f38ba8"
         : Cpu.usage >= 50 ? "#f9e2af"
         : "#a6e3a1"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
