pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property int usage: 0
    property var _prev: null

    property var proc: Process {
        command: ["cat", "/proc/stat"]
        stdout: SplitParser {
            onRead: line => {
                if (!line.startsWith("cpu ")) return
                let p = line.trim().split(/\s+/)
                let user = parseInt(p[1]), nice = parseInt(p[2]),
                    system = parseInt(p[3]), idle = parseInt(p[4]),
                    iowait = parseInt(p[5]), irq = parseInt(p[6]),
                    softirq = parseInt(p[7])
                let total = user + nice + system + idle + iowait + irq + softirq
                let idleTotal = idle + iowait
                if (root._prev) {
                    let dt = total - root._prev.total
                    let di = idleTotal - root._prev.idle
                    root.usage = dt > 0 ? Math.round((dt - di) / dt * 100) : 0
                }
                root._prev = { total, idle: idleTotal }
            }
        }
    }

    property var timer: Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
