import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation

    readonly property var conf: Plasmoid.configuration
    readonly property bool blurOn: conf.blur !== undefined ? conf.blur : true
    readonly property real tint: conf.tint !== undefined ? (conf.tint / 100.0) : 0.45

    readonly property int plasmoidLocation: Plasmoid.location
    readonly property string iconBase: Qt.resolvedUrl("../icons/").toString()
    readonly property string scriptDir: decodeURIComponent(Qt.resolvedUrl("../scripts/").toString().replace("file://", ""))
    function script(name, args) { return "bash '" + scriptDir + name + "'" + (args ? " " + args : "") }

    toolTipMainText: "OmniFlyout"

    // ---------------- State ----------------
    property date now: new Date()
    property bool devicesOpen: false

    // Real Physical IP
    property string activeIp: ""
    property string activeIpType: ""
    property string activeIpDev: ""

    // Brightness
    property bool brightnessPresent: false
    property string brightnessDispName: "display3"
    property int brightnessMax: 10000
    property real brightness: 1.0

    // Volume & Audio devices
    property real volume: 0.5
    property bool muted: false
    property bool micMuted: false
    property string defsink: ""
    property string defsource: ""
    property var sinks: []
    property var sources: []
    property string defaultSinkLabel: "Speakers"

    // Networks & Bluetooth
    property bool ethPresent: true
    property string ethDevice: "enp44s0"
    property bool ethConn: false
    property string ethSub: "Disconnected"

    property bool wifiOn: false
    property bool wifiConn: false
    property string wifiSsid: ""
    property string wifiSub: "Off"
    property var wifiNetworks: []
    property bool wifiScanning: false
    property string wifiConnectingSsid: ""
    property string wifiError: ""

    property bool btOn: false
    property int btCount: 0
    property string btSub: "Off"
    property var btDevices: []
    property bool btScanning: false
    property string btConnectingMac: ""
    property string btAlias: "cachy-vitg"

    // Power profile
    property string profile: "balanced"
    readonly property var profiles: ["power-saver", "balanced", "performance"]
    function profileName(p) { return p === "power-saver" ? "Power Saver" : (p === "performance" ? "Performance" : "Balanced") }
    property string profileSub: "Balanced"

    // Quick toggles
    property bool airplane: false
    property bool dnd: false
    property bool caffeine: false
    property bool night: false
    property bool dark: true

    // Media
    property bool hasPlayerctl: false
    property string player: ""
    property string mediaStatus: ""
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string artUrl: ""
    property real mediaPos: 0
    property real mediaLen: 0
    readonly property bool mediaActive: (mediaStatus === "Playing" || mediaStatus === "Paused") && mediaTitle !== ""

    // Slider throttling
    property real pendingVol: -1
    property real pendingBri: -1
    property double lastTouch: 0
    function isTouching() { return (Date.now() - lastTouch) < 1500 }
    function touch() { lastTouch = Date.now() }

    Component.onCompleted: {
        refresh()
        refreshBrightness()
        refreshWifi()
        refreshBt()
    }

    // ---------------- Shell Runner ----------------
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        property var cbs: ({})
        onNewData: function(source, data) {
            exec.disconnectSource(source)
            var cb = cbs[source]
            delete cbs[source]
            if (cb) cb((data["stdout"] || "").trim())
        }
        function run(cmd, cb) {
            if (cb) cbs[cmd] = cb
            connectSource(cmd)
        }
    }

    function sh(cmd, delay) {
        exec.run(cmd)
        afterAction.interval = delay || 600
        afterAction.restart()
    }

    function closeAnd(cmd) {
        closePopup()
        exec.run(cmd)
    }

    // ---------------- Parsing & Formatting ----------------
    function parseSink(s, defName) {
        var rawDesc = s.description || s.name || "Audio Device"
        var label = rawDesc
        var icon = "speaker.svg"
        var lower = (rawDesc + " " + (s.name || "")).toLowerCase()
        if (lower.indexOf("bt51") >= 0 || lower.indexOf("headphone") >= 0 || lower.indexOf("headset") >= 0) {
            icon = "headphones.svg"
            if (lower.indexOf("bt51") >= 0) label = "Yealink BT51"
            else if (lower.indexOf("headphone") >= 0) label = "Headphones"
        } else if (lower.indexOf("hdmi") >= 0 || lower.indexOf("displayport") >= 0) {
            icon = "device-desktop.svg"
            var m = rawDesc.match(/HDMI[^)]*/i)
            label = m ? m[0] : "HDMI Audio"
        } else if (lower.indexOf("speaker") >= 0) {
            label = "Speakers (Built-in)"
            icon = "speaker.svg"
        }
        return {
            name: s.name,
            label: label,
            icon: icon,
            isDefault: (s.name === defName)
        }
    }

    function parseSource(s, defName) {
        var rawDesc = s.description || s.name || "Microphone"
        var label = rawDesc
        var icon = "microphone.svg"
        var lower = (rawDesc + " " + (s.name || "")).toLowerCase()
        if (lower.indexOf("bt51") >= 0 || lower.indexOf("headset") >= 0) {
            icon = "headphones.svg"
            label = "Yealink BT51 Mic"
        } else if (lower.indexOf("webcam") >= 0 || lower.indexOf("c925e") >= 0) {
            label = "Webcam Mic (C925e)"
            icon = "camera.svg"
        } else if (lower.indexOf("digital microphone") >= 0 || lower.indexOf("mic1") >= 0) {
            label = "Internal Mic"
        } else if (lower.indexOf("stereo microphone") >= 0 || lower.indexOf("mic2") >= 0) {
            label = "Headset Jack Mic"
        }
        return {
            name: s.name,
            label: label,
            icon: icon,
            isDefault: (s.name === defName)
        }
    }

    function applyStatus(txt) {
        var o = {}
        txt.split("\n").forEach(function(l) {
            var i = l.indexOf("=")
            if (i <= 0) return
            o[l.substring(0, i)] = l.substring(i + 1)
        })
        now = new Date()

        // Real Physical IP
        activeIp = o.ip || ""
        activeIpType = o.iptype || ""
        activeIpDev = o.ipdev || ""

        // Wi-Fi
        wifiOn = (o.wifi === "enabled")
        wifiConn = (o.wificonn === "1")
        wifiSsid = o.ssid || ""
        wifiSub = !wifiOn ? "Off" : (wifiConn ? (wifiSsid !== "" ? wifiSsid : "Connected") : "On")

        // Ethernet
        if (o.eth && o.eth.indexOf(":") > 0) {
            var ep = o.eth.split(":")
            ethDevice = ep[0]
            ethConn = (ep[2] === "connected")
            ethPresent = true
            var sp = parseInt(o.ethspeed) || 0
            var speedStr = sp >= 1000 ? ((sp / 1000).toFixed(0) + " Gbps") : (sp > 0 ? sp + " Mbps" : "")
            ethSub = ethConn ? ("Connected" + (speedStr ? " · " + speedStr : "")) : "Disconnected"
        } else {
            ethPresent = false
            ethConn = false
            ethSub = "Disconnected"
        }

        // Bluetooth
        btOn = (o.bt === "on")
        btCount = parseInt(o.btcount) || 0
        btSub = !btOn ? "Off" : (btCount > 0 ? ("Connected (" + btCount + ")") : "On")

        // Volume & Mic
        if (o.vol && !isTouching()) volume = parseFloat(o.vol)
        muted = (o.muted === "1")
        micMuted = (o.micmuted === "1")

        // Audio devices
        defsink = o.defsink || ""
        defsource = o.defsource || ""
        try {
            var rawSinks = JSON.parse(o.sinks || "[]")
            var sl = []
            rawSinks.forEach(function(s) {
                if (s && s.name) sl.push(parseSink(s, defsink))
            })
            sinks = sl
            var activeSink = sl.find(function(item) { return item.isDefault })
            defaultSinkLabel = activeSink ? activeSink.label : "Speakers"
        } catch(e) { }

        try {
            var rawSources = JSON.parse(o.sources || "[]")
            var sc = []
            rawSources.forEach(function(s) {
                if (s && s.name && !s.name.endsWith(".monitor")) sc.push(parseSource(s, defsource))
            })
            sources = sc
        } catch(e) { }

        // Power profile
        if (o.profile) {
            profile = o.profile
            profileSub = profileName(profile)
        }

        // Quick states
        caffeine = (o.caffeine === "1")
        dnd = (o.dnd === "1")
        night = (o.night === "true")
        dark = (o.dark === "1")
        airplane = (o.airplane === "1")

        // Media
        hasPlayerctl = (o.playerctl === "1")
        player = o.player || ""
        var m = (o.media || "").split("|||")
        mediaStatus = m[0] || ""
        mediaArtist = m[1] || ""
        mediaTitle = m[2] || ""
        artUrl = m[3] || ""
        mediaPos = (parseFloat(m[4]) || 0) / 1000000
        mediaLen = (parseFloat(m[5]) || 0) / 1000000
    }

    function applyBrightness(line) {
        if (!line || line.trim() === "") {
            brightnessPresent = false
            return
        }
        var p = line.trim().split("|")
        if (p.length >= 3) {
            brightnessDispName = p[0]
            var cur = parseInt(p[1]) || 0
            brightnessMax = Math.max(1, parseInt(p[2]) || 100)
            if (!isTouching()) brightness = cur / brightnessMax
            brightnessPresent = true
        }
    }

    function refresh() {
        exec.run("timeout 8 " + script("status.sh"), applyStatus)
    }

    function refreshBrightness() {
        exec.run("timeout 5 " + script("brightness.sh", "list"), applyBrightness)
    }

    function refreshWifi() {
        if (!wifiOn) {
            wifiNetworks = []
            return
        }
        wifiScanning = true
        exec.run("timeout 6 " + script("wifi.sh", "list"), function(out) {
            wifiScanning = false
            try {
                var list = JSON.parse(out || "[]")
                wifiNetworks = list
            } catch(e) { }
        })
    }

    function rescanWifi() {
        wifiScanning = true
        exec.run("timeout 8 " + script("wifi.sh", "rescan"), function(out) {
            wifiScanning = false
            try {
                var list = JSON.parse(out || "[]")
                wifiNetworks = list
            } catch(e) { }
        })
    }

    function connectWifi(ssid, pwd) {
        wifiConnectingSsid = ssid
        wifiError = ""
        var safeSsid = ssid.replace(/'/g, "'\\''")
        var cmd = "connect '" + safeSsid + "'"
        if (pwd && pwd.length > 0) {
            cmd += " '" + pwd.replace(/'/g, "'\\''") + "'"
        }
        exec.run("timeout 15 " + script("wifi.sh", cmd), function(out) {
            wifiConnectingSsid = ""
            refresh()
            refreshWifi()
        })
    }

    function disconnectWifi() {
        exec.run("timeout 5 " + script("wifi.sh", "disconnect"), function() {
            refresh()
            refreshWifi()
        })
    }

    function refreshBt() {
        if (!btOn) {
            btDevices = []
            return
        }
        exec.run("timeout 5 " + script("bluetooth.sh", "list"), function(out) {
            try {
                btDevices = JSON.parse(out || "[]")
            } catch(e) { }
        })
    }

    function rescanBt() {
        btScanning = true
        exec.run("timeout 8 " + script("bluetooth.sh", "rescan"), function(out) {
            btScanning = false
            try {
                btDevices = JSON.parse(out || "[]")
            } catch(e) { }
        })
    }

    function connectBt(mac) {
        btConnectingMac = mac
        exec.run("timeout 10 " + script("bluetooth.sh", "connect " + mac), function(out) {
            btConnectingMac = ""
            refresh()
            refreshBt()
        })
    }

    function disconnectBt(mac) {
        exec.run("timeout 6 " + script("bluetooth.sh", "disconnect " + mac), function(out) {
            refresh()
            refreshBt()
        })
    }

    function pairBt(mac) {
        btConnectingMac = mac
        exec.run("timeout 15 " + script("bluetooth.sh", "pair " + mac), function(out) {
            btConnectingMac = ""
            refresh()
            refreshBt()
        })
    }

    // ---------------- Actions ----------------
    function setBrightness(v) {
        touch()
        brightness = v
        pendingBri = v
    }

    function setVolume(v) {
        touch()
        volume = v
        muted = false
        pendingVol = v
    }

    function toggleMute() {
        muted = !muted
        sh("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", 300)
    }

    function setSink(name) {
        defsink = name
        sh("pactl set-default-sink '" + name + "'", 400)
    }

    function setSource(name) {
        defsource = name
        sh("pactl set-default-source '" + name + "'", 400)
    }

    function toggleEth() {
        if (ethDevice) sh("nmcli device " + (ethConn ? "disconnect " : "connect ") + ethDevice, 1500)
    }

    function toggleWifi() {
        wifiOn = !wifiOn
        sh("nmcli radio wifi " + (wifiOn ? "on" : "off"), 1500)
        if (wifiOn) refreshWifi()
    }

    function toggleBt() {
        btOn = !btOn
        sh(btOn ? "rfkill unblock bluetooth; bluetoothctl power on" : "bluetoothctl power off", 1200)
        if (btOn) refreshBt()
    }

    function cycleProfile(dir, wrap) {
        var i = profiles.indexOf(profile)
        if (i < 0) i = 1
        var n = i + dir
        n = wrap ? (n + profiles.length) % profiles.length : Math.max(0, Math.min(profiles.length - 1, n))
        profile = profiles[n]
        profileSub = profileName(profile)
        sh("powerprofilesctl set " + profile, 600)
    }

    function toggle(preset) {
        switch (preset) {
        case "airplane":
            airplane = !airplane
            sh(airplane ? "rfkill block all" : "rfkill unblock all", 1500)
            break
        case "dnd":
            dnd = !dnd
            sh(script("dnd.sh"), 800)
            break
        case "caffeine":
            caffeine = !caffeine
            sh(script("inhibit.sh", "caffeine --power --screenSaver"), 800)
            break
        case "night":
            night = !night
            sh(script("night.sh"), 800)
            break
        case "dark":
            dark = !dark
            sh("plasma-apply-colorscheme " + (dark ? conf.darkScheme : conf.lightScheme), 1800)
            break
        case "mic":
            micMuted = !micMuted
            sh("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", 400)
            break
        }
    }

    function pickColor() {
        closePopup()
        exec.run(script("picker.sh", "pick 1"), function(out) {
            openPopup()
        })
    }

    function session(action) {
        switch (action) {
        case "lock": closeAnd("loginctl lock-session"); break
        case "logout": closeAnd("dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout"); break
        case "reboot": closeAnd("dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptReboot"); break
        case "shutdown": closeAnd("dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptShutDown"); break
        }
    }

    function openSettings(kcm) {
        closeAnd("systemsettings " + kcm)
    }

    function mpris(cmd) {
        if (player !== "") sh("playerctl -p '" + player + "' " + cmd, 400)
    }

    function seek(sec) {
        if (player !== "") {
            mediaPos = sec
            sh("playerctl -p '" + player + "' position " + sec, 400)
        }
    }

    // ---------------- Popup Dialog & Timers ----------------
    property bool dialogOpen: dlgLoader.item ? dlgLoader.item.visible : false
    readonly property bool popupOpen: dialogOpen

    onPopupOpenChanged: {
        if (popupOpen) {
            devicesOpen = false
            refresh()
            refreshBrightness()
            refreshWifi()
            refreshBt()
        }
    }

    function togglePopup() {
        if (dlgLoader.item) dlgLoader.item.toggle()
    }
    function openPopup() {
        if (dlgLoader.item) dlgLoader.item.visible = true
    }
    function closePopup() {
        if (dlgLoader.item) dlgLoader.item.visible = false
    }

    Component { id: panelComp; Panel { ctl: root } }
    Loader {
        id: dlgLoader
        active: true
        source: "PopupDialog.qml"
        onLoaded: { item.ctl = root; item.panelComp = panelComp }
    }

    Timer { id: afterAction; interval: 600; onTriggered: { root.refresh(); root.refreshBrightness() } }
    Timer { interval: 3000; running: root.popupOpen; repeat: true; onTriggered: root.refresh() }
    Timer { interval: 6000; running: root.popupOpen; repeat: true; onTriggered: root.refreshBrightness() }
    Timer {
        interval: 1000
        running: root.popupOpen && root.mediaStatus === "Playing"
        repeat: true
        onTriggered: if (root.mediaPos < root.mediaLen) root.mediaPos += 1
    }

    Timer {
        interval: 120
        running: root.popupOpen
        repeat: true
        onTriggered: {
            if (root.pendingVol >= 0) {
                exec.run("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + root.pendingVol.toFixed(2))
                root.pendingVol = -1
            }
            if (root.pendingBri >= 0) {
                var rawVal = Math.round(root.pendingBri * root.brightnessMax)
                exec.run(root.script("brightness.sh", "set " + root.brightnessDispName + " " + rawVal))
                root.pendingBri = -1
            }
        }
    }

    // ---------------- Compact Representation (Panel Icon) ----------------
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 22; height: 22
            source: root.iconBase + "omniflyout.svg"
            isMask: true
            color: (compact.containsMouse || root.popupOpen) ? "#38bdf8" : Kirigami.Theme.textColor
            opacity: (compact.containsMouse || root.popupOpen) ? 1.0 : 0.88
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: 412
        Layout.preferredWidth: 412
        Loader {
            anchors.fill: parent
            sourceComponent: panelComp
        }
    }
}
