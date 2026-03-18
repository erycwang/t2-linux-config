# Phase 3: System Info — Volume, Battery, Network, Bluetooth

## Context

Phase 2 delivered workspaces with multi-monitor awareness and a true left/center/right layout. Phase 3 fills the right side of the bar with live system info. The existing PLAN.md specifies a services layer (data singletons) sitting below widgets — this phase introduces that layer for the first time.

---

## Architecture

Services are `pragma Singleton` QML objects registered in `services/qmldir`. Widgets import the services directly (same pattern as `Config`) — no prop drilling. This also sets up for Phase 4/5 where OSD and notifications reuse the same service singletons.

```
quickshell/
  services/
    qmldir            ← registers Audio, Battery, Network, Bluetooth as singletons
    Audio.qml         ← wraps Quickshell.Services.Pipewire
    Battery.qml       ← wraps Quickshell.Services.UPower
    Network.qml       ← polls nmcli via Process (reactive every 5s)
    Bluetooth.qml     ← wraps Quickshell.Bluetooth
  modules/bar/widgets/
    Volume.qml        ← reads Audio singleton, scroll to change
    Battery.qml       ← reads Battery singleton
    Network.qml       ← reads Network singleton
    Bluetooth.qml     ← reads Bluetooth singleton
```

**Widget display** (right section, left→right): `Volume · Network · Bluetooth · Battery`

---

## Files to Create

### `quickshell/services/qmldir` (partially done — Battery registered)
```
singleton Audio 1.0 Audio.qml
singleton Battery 1.0 Battery.qml
singleton Network 1.0 Network.qml
singleton Bluetooth 1.0 Bluetooth.qml
```

### `quickshell/services/Audio.qml`
```qml
pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    property var sink: Pipewire.defaultSink
    property real volume: sink?.audio?.volume ?? 0
    property bool muted: sink?.audio?.muted ?? false

    function adjustVolume(delta) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta))
    }
    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }
}
```

Note: If `Pipewire.defaultSink` doesn't compile, try `Pipewire.defaultAudioSink` — check Quickshell version.

### `quickshell/services/Battery.qml` ✅ DONE
```qml
pragma Singleton
import QtQuick
import Quickshell.Services.UPower

QtObject {
    property var device: UPower.displayDevice
    property int percentage: Math.round((device?.percentage ?? 0) * 100)
    property bool charging: device?.state === UPowerDeviceState.Charging
                         || device?.state === UPowerDeviceState.FullyCharged
}
```

> **Note:** UPower percentage via Quickshell is 0.0–1.0, not 0–100. Multiply by 100.

### `quickshell/services/Network.qml`
Uses `Process` + `nmcli` polling every 5s. More reliable than the Quickshell.Networking module for getting the active SSID.

```qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property string ssid: ""
    property bool connected: ssid !== ""

    property var _proc: Process {
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("yes:"))
                    root.ssid = data.slice(4).trim()
            }
        }
        onExited: root._timer.restart()
    }

    property var _timer: Timer {
        interval: 5000
        running: true
        triggeredOnStart: true
        onTriggered: {
            root.ssid = ""
            root._proc.running = true
        }
    }
}
```

### `quickshell/services/Bluetooth.qml`
```qml
pragma Singleton
import QtQuick
import Quickshell.Bluetooth

QtObject {
    property bool powered: Bluetooth.adapter?.powered ?? false
    property int connectedCount: Bluetooth.devices.values.filter(d => d.connected).length
}
```

---

### `quickshell/modules/bar/widgets/Volume.qml`
Shows percentage or `—` when muted. Scroll wheel adjusts ±5%.

```qml
import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: Audio.muted ? "—" : Math.round(Audio.volume * 100) + "%"
    color: Audio.muted ? "#6c7086" : "white"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily

    MouseArea {
        anchors.fill: parent
        onWheel: event => Audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
        onClicked: Audio.toggleMute()
    }
}
```

### `quickshell/modules/bar/widgets/Battery.qml` ✅ DONE
`↑87%` when charging, `87%` otherwise. Red below 15%, amber below 30%.

```qml
import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: (Battery.charging ? "↑" : "") + Battery.percentage + "%"
    color: Battery.percentage < 15 ? "#f38ba8"
         : Battery.percentage < 30 ? "#fab387"
         : "#cdd6f4"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
```

### `quickshell/modules/bar/widgets/Network.qml`
Shows SSID when connected, `—` when not.

```qml
import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: Network.connected ? Network.ssid : "—"
    color: Network.connected ? "white" : "#6c7086"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
```

### `quickshell/modules/bar/widgets/Bluetooth.qml`
`bt:2` when on with connected devices, `bt` when on but none connected, dimmed `bt` when adapter off.

```qml
import QtQuick
import "../../../services"
import "../../../config"

Text {
    text: Bluetooth.connectedCount > 0 ? "bt:" + Bluetooth.connectedCount : "bt"
    color: Bluetooth.powered ? "white" : "#6c7086"
    font.pixelSize: Config.fontSize
    font.family: Config.fontFamily
}
```

---

## Files to Modify

### `quickshell/modules/bar/Bar.qml`
Add the four widgets to the right `RowLayout`:

```qml
// Right: system info
RowLayout {
    anchors.right: parent.right
    anchors.rightMargin: Config.padding
    anchors.verticalCenter: parent.verticalCenter
    spacing: Config.spacing

    Volume {}
    Network {}
    Bluetooth {}
    Battery {}
}
```

Widgets import services directly — no changes needed to Bar.qml imports.

---

## Import path notes

- Widgets are at `modules/bar/widgets/` → `"../../../services"` = `quickshell/services/` ✓
- Widgets → `"../../../config"` = `quickshell/config/` ✓

---

## Validation

**Run:** `quickshell` in terminal

**Check:**
1. Right side shows Volume, Network, Bluetooth, Battery
2. Volume: change with scroll wheel, value updates live; click mutes/unmutes (dims to `—`)
3. Battery: percentage reflects current charge; `↑` appears when plugged in
4. Network: shows current WiFi SSID; disconnect from WiFi → shows `—`
5. Bluetooth: `bt` when on, `bt:N` when devices connected, dimmed when adapter off

**If a service fails to load:**
- `Audio`: check `Pipewire.defaultSink` vs `Pipewire.defaultAudioSink` in Quickshell docs for installed version
- `Battery`: verify `upower` is running: `systemctl status upower`
- `Network`: verify `nmcli dev wifi` works in terminal
- `Bluetooth`: verify `bluetoothctl show` returns an adapter; check BlueZ is running
