import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../../config"

RowLayout {
    property var screen  // ShellScreen passed from Bar
    spacing: 4

    // Cache monitor lookup once for all delegates
    property var monitor: Hyprland.monitorFor(screen)
    property int activeWsId: monitor?.activeWorkspace?.id ?? -1

    Repeater {
        model: 9
        delegate: Rectangle {
            required property int index
            property int wsId: index + 1
            property bool isActive: activeWsId === wsId
            property bool isOnOtherMonitor: {
                var monitors = Hyprland.monitors.values
                for (var i = 0; i < monitors.length; i++) {
                    var m = monitors[i]
                    if (m !== monitor && m.activeWorkspace?.id === wsId)
                        return true
                }
                return false
            }
            // Has windows but not visible on any monitor — check monitors
            // directly to avoid cascading from isActive/isOnOtherMonitor
            property bool hasOffscreenWindows: {
                var workspaces = Hyprland.workspaces.values
                var exists = false
                for (var i = 0; i < workspaces.length; i++) {
                    if (workspaces[i].id === wsId) { exists = true; break }
                }
                if (!exists) return false
                var monitors = Hyprland.monitors.values
                for (var i = 0; i < monitors.length; i++) {
                    if (monitors[i].activeWorkspace?.id === wsId)
                        return false
                }
                return true
            }

            width: 24
            height: 24
            radius: 4
            color: isActive ? Colors.fg : "transparent"
            border.width: isOnOtherMonitor ? 1 : 0
            border.color: isOnOtherMonitor ? Colors.muted : "transparent"

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.hasOffscreenWindows ? -2 : 0
                text: parent.wsId
                color: parent.isActive ? Colors.bg : Colors.muted
                font.pixelSize: 12
                font.family: "monospace"
            }

            // Dot pip: workspace has windows but isn't visible on any monitor
            Rectangle {
                visible: parent.hasOffscreenWindows
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                width: 4
                height: 4
                radius: 2
                color: Colors.muted
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + parent.wsId)
            }
        }
    }
}
