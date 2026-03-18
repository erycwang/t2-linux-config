import Quickshell
import QtQuick
import "../../../config"

Text {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    text: Qt.formatDate(clock.date, "ddd MMM d")
    color: Colors.fg
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
