pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property int temp: 0

    property var proc: Process {
        command: ["sensors", "-u", "coretemp-isa-0000"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n")
                let inPackage = false
                for (const line of lines) {
                    if (line.startsWith("Package id 0:")) {
                        inPackage = true
                    } else if (inPackage && line.includes("temp1_input:")) {
                        root.temp = Math.round(parseFloat(line.trim().split(":")[1]))
                        break
                    }
                }
            }
        }
    }

    property var timer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
