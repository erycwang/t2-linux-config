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

    // Shared lookup maps — computed once, used by all 10 delegates
    property var otherMonitorWsIds: {
        var result = {}
        var monitors = Hyprland.monitors.values
        for (var i = 0; i < monitors.length; i++) {
            var m = monitors[i]
            if (m !== monitor) {
                var wsId = m.activeWorkspace?.id
                if (wsId) result[wsId] = true
            }
        }
        return result
    }
    property var occupiedOffscreenWsIds: {
        var onScreen = {}
        var monitors = Hyprland.monitors.values
        for (var i = 0; i < monitors.length; i++)
            onScreen[monitors[i].activeWorkspace?.id] = true
        var result = {}
        var workspaces = Hyprland.workspaces.values
        for (var i = 0; i < workspaces.length; i++) {
            var wsId = workspaces[i].id
            if (wsId > 0 && !onScreen[wsId]) result[wsId] = true
        }
        return result
    }
    property bool hasSpecialWorkspace: {
        var workspaces = Hyprland.workspaces.values
        for (var i = 0; i < workspaces.length; i++) {
            if (workspaces[i].id < 0) return true
        }
        return false
    }

    Repeater {
        model: 10
        delegate: Rectangle {
            required property int index
            property int wsId: index + 1
            property bool isActive: activeWsId === wsId
            property bool isOnOtherMonitor: wsId in otherMonitorWsIds
            property bool hasOffscreenWindows: wsId in occupiedOffscreenWsIds

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

    // Special workspace indicator
    Rectangle {
        id: specialWsIndicator
        property bool specialActive: (monitor?.lastIpcObject?.specialWorkspace?.id ?? 0) !== 0
        property bool isActive: specialActive
        property bool hasWindows: hasSpecialWorkspace

        Connections {
            target: Hyprland
            function onRawEvent(event) {
                if (event.name === "activespecial") {
                    var args = event.parse(2)  // args[0]=workspace name, args[1]=monitor name
                    if (args[1] === monitor?.name) {
                        specialWsIndicator.specialActive = args[0] !== ""
                    }
                }
            }
        }

        visible: isActive || hasWindows
        width: 24
        height: 24
        radius: 4
        color: isActive ? Colors.fg : "transparent"

        Text {
            anchors.centerIn: parent
            text: "·"
            color: parent.isActive ? Colors.bg : Colors.muted
            font.pixelSize: 18
            font.family: "monospace"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Hyprland.dispatch("togglespecialworkspace")
        }
    }
}
