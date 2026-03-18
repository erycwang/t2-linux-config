import Quickshell
import "../../config"

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        property var modelData  // ShellScreen injected by Variants for this instance

        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: Config.barHeight
        color: Colors.bgAlpha

        Bar { screen: modelData }
    }
}
