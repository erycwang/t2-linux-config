import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../../config"

Text {
    id: root
    property string appClass: ""

    visible: appClass !== ""
    text: appClass
    color: Colors.fg
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
    verticalAlignment: Text.AlignVCenter

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow") {
                var cls = event.parse(2)[0] ?? ""
                root.appClass = cls ? cls.charAt(0).toUpperCase() + cls.slice(1) : ""
            }
        }
    }
}
