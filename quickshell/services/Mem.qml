pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property int usage: 0
    property int _total: 0

    property var proc: Process {
        command: ["cat", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("MemTotal:"))
                    root._total = parseInt(line.trim().split(/\s+/)[1])
                else if (line.startsWith("MemAvailable:") && root._total > 0) {
                    let available = parseInt(line.trim().split(/\s+/)[1])
                    root.usage = Math.round((root._total - available) / root._total * 100)
                }
            }
        }
    }

    property var timer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
