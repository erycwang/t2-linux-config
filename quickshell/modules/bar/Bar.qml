import QtQuick
import QtQuick.Layouts
import "widgets"
import "../../config"

Item {
    id: root
    property var screen  // ShellScreen from BarWrapper
    anchors.fill: parent

    // Left: workspaces + focused app
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: Config.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.spacing
        Workspaces { screen: root.screen }
        Separator { visible: focusedWindow.visible; width: visible ? implicitWidth : 0 }
        FocusedWindow { id: focusedWindow }
    }

    // Center: clock + date (truly centered, unaffected by left/right widths)
    RowLayout {
        anchors.centerIn: parent
        spacing: Config.spacing
        Clock {}
        Separator {}
        Date {}
    }

    // Right: system info
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: Config.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.spacing
        Weather {}
        Separator {}
        Cpu {}
        Separator {}
        Mem {}
        Separator {}
        Temp {}
        Separator {}
        Bluetooth { id: btWidget }
        Separator { visible: btWidget.visible; width: visible ? implicitWidth : 0 }
        Wifi {}
        Separator {}
        Battery {}
    }
}
