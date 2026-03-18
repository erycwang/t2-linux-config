import QtQuick
import QtQuick.Layouts
import "widgets"
import "../../config"

Item {
    id: root
    property var screen  // ShellScreen from BarWrapper
    anchors.fill: parent

    // Left: workspaces
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: Config.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.spacing
        Workspaces { screen: root.screen }
    }

    // Center: clock (truly centered, unaffected by left/right widths)
    RowLayout {
        anchors.centerIn: parent
        Clock {}
    }

    // Right: system info
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: Config.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.spacing
        Battery {}
    }
}
