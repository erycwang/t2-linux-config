import Quickshell
import QtQuick
import "../../../config"

Text {
	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}
	text: Qt.formatTime(clock.date, "HH:mm")
	color: Colors.fg
	font.pixelSize: Config.fontSize
	font.family: Config.fontFamily
}
