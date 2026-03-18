pragma Singleton
import QtQuick
import Quickshell.Services.UPower

QtObject {
    property var device: UPower.displayDevice
    property int percentage: Math.round((device?.percentage ?? 0) * 100)
    property bool charging: device?.state === UPowerDeviceState.Charging
                         || device?.state === UPowerDeviceState.FullyCharged
}
