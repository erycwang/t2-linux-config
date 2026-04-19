pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool   valid:       false
    property int    temperature: 0
    property int    weatherCode: 0
    property string icon:        "\ue312"
    property string city:        ""
    property string _raw:        ""
    property real   _lastTime:   0

    function codeToIcon(code) {
        // Clear / partly cloudy
        if (code === 113) return "\ue30d"  // day_sunny
        if (code === 116) return "\ue302"  // day_cloudy (sun + cloud)
        if (code === 119 || code === 122) return "\ue312"  // cloudy / overcast

        // Fog / mist
        if (code === 143 || code === 248 || code === 260) return "\ue313"  // fog

        // Blowing snow / blizzard
        if (code === 227 || code === 230) return "\ue35e"  // snow_wind

        // Thundery outbreaks (no heavy precip)
        if (code === 200) return "\ue31d"  // thunderstorm

        // Drizzle / patchy light rain / sprinkle
        if (code === 176 || code === 185 || code === 263 || code === 266 ||
            code === 293 || code === 353) return "\ue31b"  // sprinkle

        // Freezing drizzle / rain mix (rain + ice)
        if (code === 281 || code === 284 || code === 311 || code === 314) return "\ue316"  // rain_mix

        // Light–moderate rain
        if (code === 296 || code === 299 || code === 302) return "\ue318"  // rain

        // Heavy rain / showers / torrential
        if (code === 305 || code === 308 || code === 356 || code === 359) return "\ue319"  // showers

        // Sleet
        if (code === 182 || code === 317 || code === 320 ||
            code === 362 || code === 365) return "\ue3ad"  // sleet

        // Snow
        if (code === 179 || code === 323 || code === 326 || code === 329 ||
            code === 332 || code === 335 || code === 338 ||
            code === 368 || code === 371) return "\ue31a"  // snow

        // Ice pellets / hail
        if (code === 350 || code === 374 || code === 377) return "\ue314"  // hail

        // Thunder with light precip
        if (code === 386 || code === 392) return "\ue31c"  // storm_showers

        // Thunder with heavy precip
        if (code === 389 || code === 395) return "\ue31d"  // thunderstorm

        return "\ue312"  // cloudy (fallback)
    }

    property var proc: Process {
        // Requires: curl, jq
        command: ["sh", "-c",
            "city=$(curl -s --max-time 5 'https://wttr.in/?format=%l') && " +
            "curl -s --max-time 10 'https://wttr.in/?format=j1' | " +
            "jq -r --arg city \"$city\" '[.current_condition[0].temp_C, .current_condition[0].weatherCode, $city] | join(\"|\")'"]
        stdout: StdioCollector {
            onStreamFinished: root._raw = this.text.trim()
        }
        onExited: (exitCode, _) => {
            if (exitCode !== 0 || root._raw === "") {
                root._raw = ""
                root.valid = false
                return
            }
            let parts = root._raw.split("|")
            root._raw = ""
            if (parts.length < 3) { root.valid = false; return }
            let t = parseInt(parts[0])
            let c = parseInt(parts[1])
            if (isNaN(t) || isNaN(c)) { root.valid = false; return }
            root.temperature = t
            root.weatherCode = c
            root.icon        = root.codeToIcon(c)
            root.city        = parts[2].trim()
            root.valid       = true
        }
    }

    property var timer: Timer {
        interval:         900000  // 15 min
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered: {
            root._lastTime = Date.now()
            proc.running = true
        }
    }

    // Lightweight suspend-wake detector — only checks for time jumps
    property var suspendDetector: Timer {
        interval:         120000  // 2 min
        running:          true
        repeat:           true
        onTriggered: {
            let now = Date.now()
            if (root._lastTime > 0 && (now - root._lastTime) > 180000) {
                proc.running = true
                root._lastTime = now
            }
        }
    }
}
