import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Io
import "../../services"
import "../../config"

PanelWindow {
    id: root

    screen: BluetoothPopupState.popupScreen ?? Quickshell.screens[0]
    visible: BluetoothPopupState.open && BluetoothPopupState.popupScreen !== null

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    property var pairedDevices: {
        let paired = []
        for (const d of Bluetooth.devices.values) {
            if (d.paired) paired.push(d)
        }
        return paired
    }

    // Fullscreen transparent area — click outside popup to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: BluetoothPopupState.close()
    }

    // Popup panel anchored top-right, below the bar
    Rectangle {
        id: popup
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Config.barHeight + 2
        anchors.rightMargin: Config.padding

        width: 260
        height: col.implicitHeight + Config.padding * 2

        color: Colors.bg
        radius: 6
        border.color: Colors.muted
        border.width: 1

        // Absorb clicks so they don't reach the dismiss MouseArea
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: col
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Config.padding
            }
            spacing: 4

            // Header
            Text {
                text: "Bluetooth"
                color: Colors.muted
                font.pixelSize: Config.fontSize - 1
                font.family: Config.fontFamily
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.muted
                opacity: 0.4
            }

            // Paired device list
            Repeater {
                model: root.pairedDevices

                delegate: Rectangle {
                    id: deviceRow
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: rowLayout.implicitHeight + 8
                    radius: 4
                    color: rowMouse.containsMouse
                        ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.07)
                        : "transparent"

                    RowLayout {
                        id: rowLayout
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            margins: 4
                        }
                        spacing: Config.spacing

                        Text {
                            text: deviceRow.modelData.connected ? "󰂱" : "󰂯"
                            color: deviceRow.modelData.connected ? Colors.accent : Colors.muted
                            font.pixelSize: Config.fontSize
                            font.family: Config.fontFamily
                        }

                        Text {
                            text: deviceRow.modelData.name || deviceRow.modelData.address
                            color: deviceRow.modelData.connected ? Colors.fg : Colors.muted
                            font.pixelSize: Config.fontSize
                            font.family: Config.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "connected"
                            color: Colors.accent
                            font.pixelSize: Config.fontSize - 2
                            font.family: Config.fontFamily
                            visible: deviceRow.modelData.connected
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            btCmd.command = [
                                "bluetoothctl",
                                deviceRow.modelData.connected ? "disconnect" : "connect",
                                deviceRow.modelData.address
                            ]
                            btCmd.running = true
                        }
                    }
                }
            }

            // Empty state when no paired devices
            Text {
                visible: root.pairedDevices.length === 0
                text: "No paired devices"
                color: Colors.muted
                font.pixelSize: Config.fontSize
                font.family: Config.fontFamily
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Process {
            id: btCmd
            running: false
        }
    }
}
