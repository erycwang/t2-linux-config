import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: "CPU " + Cpu.usage.toString().padStart(3, ' ') + "%"
    color: Cpu.usage >= 80 ? Colors.red
         : Cpu.usage >= 50 ? Colors.yellow
         : Colors.green
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
