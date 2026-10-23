import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// The visible OmniFlyout popup with sliding sub-page support (Concept #6).
Item {
    id: panel
    property var ctl
    readonly property int pad: 24
    readonly property int gap: 16
    property int currentPage: 0 // 0: Main Flyout, 1: Wi-Fi Sub-Page, 2: Bluetooth Sub-Page

    Connections {
        target: panel.ctl
        function onPopupOpenChanged() {
            if (panel.ctl && !panel.ctl.popupOpen) {
                panel.currentPage = 0
            }
        }
    }

    implicitWidth: 412
    implicitHeight: sliderArea.implicitHeight + 2 * pad
    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    function ic(f) { return ctl.iconBase + f }

    // ---- flyout body. With blur on, KWin's frosted frame sits behind this and we only add a dark tint.
    Rectangle {
        anchors.fill: parent
        radius: ctl.blurOn ? 14 : 24
        color: ctl.blurOn ? Qt.rgba(0.04, 0.04, 0.06, ctl.tint * 0.6)
                          : Qt.rgba(0.075, 0.078, 0.094, 0.94)
        border.width: ctl.blurOn ? 0 : 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.045) }
                GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(1, 1, 1, 0.09)
    }

    // Sliding pages container
    Item {
        id: sliderArea
        x: 0
        y: panel.pad
        width: panel.width
        clip: true
        implicitHeight: panel.currentPage === 0 ? mainCol.implicitHeight : (panel.currentPage === 1 ? Math.max(mainCol.implicitHeight, wifiSubView.implicitHeight) : Math.max(mainCol.implicitHeight, btSubView.implicitHeight))
        height: implicitHeight
        Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Item {
            id: pagesRow
            width: panel.width * 3
            height: parent.height
            x: panel.currentPage === 0 ? 0 : (panel.currentPage === 1 ? -panel.width : -panel.width * 2)
            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // ================= PAGE 0: MAIN FLYOUT =================
            Item {
                id: mainPageItem
                x: 0; y: 0
                width: panel.width
                height: parent.height

                ColumnLayout {
                    id: mainCol
                    x: panel.pad
                    y: 0
                    width: panel.width - 2 * panel.pad
                    spacing: panel.gap

                    // ================= Header: Clock, Date, Physical IP, Session Buttons =================
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 4
                        spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: Qt.formatTime(ctl.now, "h:mm")
                                color: "#ffffff"
                                font.family: "Inter"
                                font.pixelSize: 50
                                font.weight: Font.Normal
                                font.letterSpacing: -1
                            }
                            Text {
                                text: Qt.locale().toString(ctl.now, "dddd, d MMMM")
                                color: Qt.rgba(1, 1, 1, 0.88)
                                font.family: "Inter"
                                font.pixelSize: 15
                            }
                            // Real Physical IP Badge
                            Rectangle {
                                Layout.topMargin: 3
                                Layout.preferredHeight: 24
                                implicitWidth: ipText.implicitWidth + 18
                                radius: 12
                                color: Qt.rgba(45/255, 212/255, 191/255, 0.12)
                                border.width: 1
                                border.color: Qt.rgba(45/255, 212/255, 191/255, 0.3)
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle {
                                        width: 6; height: 6
                                        radius: 3
                                        color: panel.ctl.activeIp !== "" ? "#2dd4bf" : "#ef4444"
                                    }
                                    Text {
                                        id: ipText
                                        text: panel.ctl.activeIp !== "" 
                                              ? (panel.ctl.activeIp + (panel.ctl.activeIpType !== "" ? " · " + panel.ctl.activeIpType : ""))
                                              : "Offline"
                                        color: "#2dd4bf"
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: [
                                { f: "lock.svg",             k: "lock" },
                                { f: "logout.svg",           k: "logout" },
                                { f: "rotate-clockwise.svg", k: "reboot" },
                                { f: "power.svg",            k: "shutdown" }
                            ]
                            delegate: OmniIconButton {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 10
                                iconSource: panel.ic(modelData.f)
                                onClicked: ctl.session(modelData.k)
                            }
                        }
                    }

                    // ================= Brightness (built-in screen only) =================
                    OmniSlider {
                        visible: ctl.brightnessPresent
                        iconSource: panel.ic("sun.svg")
                        label: "Built-in Display"
                        value: ctl.brightness
                        onMoved: function(v) { ctl.setBrightness(v) }
                    }

                    // ================= Volume + output picker =================
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        OmniSlider {
                            iconSource: panel.ic(ctl.muted ? "volume-off.svg" : "volume.svg")
                            iconClickable: true
                            value: ctl.muted ? 0 : ctl.volume
                            onMoved: function(v) { ctl.setVolume(v) }
                            onIconClicked: ctl.toggleMute()
                        }
                        Rectangle {
                            id: devBtn
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 52
                            radius: 26
                            color: ctl.devicesOpen ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, dm.containsMouse ? 0.11 : 0.065)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, ctl.devicesOpen ? 0.24 : 0.14)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 14
                                spacing: 6
                                Text {
                                    Layout.fillWidth: true
                                    text: ctl.defaultSinkLabel
                                    color: "#ffffff"
                                    font.family: "Inter"
                                    font.pixelSize: 15
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Kirigami.Icon {
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    source: panel.ic("chevron-down.svg")
                                    isMask: true
                                    color: "#ffffff"
                                    rotation: ctl.devicesOpen ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: 160 } }
                                }
                            }
                            MouseArea {
                                id: dm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ctl.devicesOpen = !ctl.devicesOpen
                            }
                        }
                    }

                    // ================= Audio device list (outputs + inputs) =================
                    Rectangle {
                        id: devCard
                        visible: ctl.devicesOpen
                        Layout.fillWidth: true
                        Layout.preferredHeight: devCol.implicitHeight + 20
                        radius: 20
                        color: Qt.rgba(1, 1, 1, 0.055)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)

                        ColumnLayout {
                            id: devCol
                            x: 10; y: 10
                            width: parent.width - 20
                            spacing: 2

                            Repeater {
                                model: [
                                    { title: "Output", list: ctl.sinks, kind: "sink" },
                                    { title: "Input",  list: ctl.sources, kind: "source" }
                                ]
                                delegate: ColumnLayout {
                                    id: grp
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        Layout.leftMargin: 10
                                        Layout.topMargin: grp.modelData.kind === "source" ? 8 : 2
                                        Layout.bottomMargin: 2
                                        text: grp.modelData.title.toUpperCase()
                                        color: Qt.rgba(1, 1, 1, 0.45)
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                        font.letterSpacing: 1.2
                                    }
                                    Repeater {
                                        model: grp.modelData.list
                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 40
                                            radius: 14
                                            color: modelData.isDefault ? Qt.rgba(0.176, 0.831, 0.749, 0.14)
                                                                       : Qt.rgba(1, 1, 1, rm.containsMouse ? 0.07 : 0)
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 12
                                                spacing: 10
                                                Kirigami.Icon {
                                                    Layout.preferredWidth: 18
                                                    Layout.preferredHeight: 18
                                                    source: panel.ic(modelData.icon)
                                                    isMask: true
                                                    color: modelData.isDefault ? "#5eead4" : Qt.rgba(1, 1, 1, 0.7)
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.label
                                                    color: modelData.isDefault ? "#ffffff" : Qt.rgba(1, 1, 1, 0.8)
                                                    font.family: "Inter"
                                                    font.pixelSize: 14
                                                    elide: Text.ElideRight
                                                }
                                                Kirigami.Icon {
                                                    visible: modelData.isDefault
                                                    Layout.preferredWidth: 16
                                                    Layout.preferredHeight: 16
                                                    source: panel.ic("check.svg")
                                                    isMask: true
                                                    color: "#5eead4"
                                                }
                                            }
                                            MouseArea {
                                                id: rm
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: grp.modelData.kind === "sink" ? ctl.setSink(modelData.name) : ctl.setSource(modelData.name)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Divider { Layout.topMargin: 2 }

                    // ================= Big pill toggles =================
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 14
                        rowSpacing: 14

                        OmniPill {
                            visible: ctl.ethPresent
                            title: "Ethernet"
                            sub: ctl.ethSub
                            active: ctl.ethConn
                            accent: "#2dd4bf"
                            showChevron: false
                            iconSource: panel.ic(ctl.ethConn ? "ethernet.svg" : "ethernet-off.svg")
                            onClicked: ctl.toggleEth()
                            onIconClicked: ctl.toggleEth()
                            onRightClicked: ctl.openSettings("kcm_networkmanagement")
                        }
                        OmniPill {
                            title: "Wi-Fi"
                            sub: ctl.wifiSub
                            active: ctl.wifiOn
                            accent: "#38bdf8"
                            showChevron: true
                            chevronSource: panel.ic("chevron-right.svg")
                            iconSource: panel.ic(ctl.wifiOn ? "wifi.svg" : "wifi-off.svg")
                            onIconClicked: ctl.toggleWifi()
                            onClicked: {
                                if (!ctl.wifiOn) ctl.toggleWifi()
                                panel.currentPage = 1
                                ctl.refreshWifi()
                            }
                            onChevronClicked: {
                                if (!ctl.wifiOn) ctl.toggleWifi()
                                panel.currentPage = 1
                                ctl.refreshWifi()
                            }
                            onRightClicked: ctl.openSettings("kcm_networkmanagement")
                        }
                        OmniPill {
                            title: "Bluetooth"
                            sub: ctl.btSub
                            active: ctl.btOn
                            accent: "#3b82f6"
                            showChevron: true
                            chevronSource: panel.ic("chevron-right.svg")
                            iconSource: panel.ic(ctl.btOn ? "bluetooth.svg" : "bluetooth-off.svg")
                            onIconClicked: ctl.toggleBt()
                            onClicked: {
                                if (!ctl.btOn) ctl.toggleBt()
                                panel.currentPage = 2
                                ctl.refreshBt()
                            }
                            onChevronClicked: {
                                if (!ctl.btOn) ctl.toggleBt()
                                panel.currentPage = 2
                                ctl.refreshBt()
                            }
                            onRightClicked: ctl.openSettings("kcm_bluetooth")
                        }
                        OmniPill {
                            title: "Power"
                            sub: ctl.profileSub
                            active: true
                            accent: ctl.profile === "performance" ? "#f97316" : (ctl.profile === "power-saver" ? "#84cc16" : "#22c55e")
                            showChevron: false
                            iconSource: panel.ic(ctl.profile === "power-saver" ? "leaf.svg" : (ctl.profile === "performance" ? "rocket.svg" : "gauge.svg"))
                            onClicked: ctl.cycleProfile(1, true)
                            onIconClicked: ctl.cycleProfile(1, true)
                            onRightClicked: ctl.openSettings("kcm_powerdevilprofilesconfig")
                            onWheelMoved: function(dir) { ctl.cycleProfile(dir, false) }
                        }
                    }

                    Divider { Layout.topMargin: 2 }

                    // ================= Round quick toggles =================
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        OmniRound { label: "Airplane"; accent: "#60a5fa"; active: ctl.airplane; iconSource: panel.ic("plane.svg"); onClicked: ctl.toggle("airplane") }
                        OmniRound { label: "DND";      accent: "#f472b6"; active: ctl.dnd;      iconSource: panel.ic("moon.svg");  onClicked: ctl.toggle("dnd") }
                        OmniRound { label: "Caffeine"; accent: "#fb923c"; active: ctl.caffeine; iconSource: panel.ic("coffee.svg"); onClicked: ctl.toggle("caffeine") }
                        OmniRound { label: "Night";    accent: "#fbbf24"; active: ctl.night;    iconSource: panel.ic("bulb.svg");  onClicked: ctl.toggle("night") }
                        OmniRound { label: "Dark";     accent: "#a78bfa"; active: ctl.dark;     iconSource: panel.ic("contrast.svg"); onClicked: ctl.toggle("dark") }
                        OmniRound { label: "Mic";      accent: "#2dd4bf"; active: !ctl.micMuted; iconSource: panel.ic(ctl.micMuted ? "microphone-off.svg" : "microphone.svg"); onClicked: ctl.toggle("mic") }
                        OmniRound { label: "Picker";   accent: "#e879f9"; active: false;        iconSource: panel.ic("color-picker.svg"); onClicked: ctl.pickColor() }
                    }

                    Divider { Layout.topMargin: 2 }

                    // ================= Media card =================
                    Rectangle {
                        id: media
                        readonly property bool live: ctl.mediaActive
                        Layout.fillWidth: true
                        Layout.preferredHeight: 118
                        radius: 22
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.13)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            Item {
                                Layout.preferredWidth: 86
                                Layout.preferredHeight: 86
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    visible: !media.live || ctl.artUrl === ""
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "#7c3aed" }
                                        GradientStop { position: 1.0; color: "#0ea5e9" }
                                    }
                                    opacity: media.live ? 0.9 : 0.35
                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: 32; height: 32
                                        source: panel.ic("music.svg")
                                        isMask: true
                                        color: "#ffffff"
                                    }
                                }
                                Image {
                                    id: art
                                    anchors.fill: parent
                                    source: media.live ? ctl.artUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize: Qt.size(172, 172)
                                    layer.enabled: true
                                    visible: false
                                }
                                Rectangle { id: artMask; anchors.fill: parent; radius: 12; layer.enabled: true; visible: false }
                                MultiEffect {
                                    anchors.fill: parent
                                    source: art
                                    maskEnabled: true
                                    maskSource: artMask
                                    visible: media.live && ctl.artUrl !== "" && art.status === Image.Ready
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 0
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3
                                        Text {
                                            Layout.fillWidth: true
                                            text: media.live ? ctl.mediaTitle : "Nothing playing"
                                            color: "#ffffff"
                                            font.family: "Inter"
                                            font.pixelSize: 17
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: media.live ? ctl.mediaArtist : (ctl.hasPlayerctl ? "Play something to see it here" : "Install playerctl for media")
                                            color: Qt.rgba(1, 1, 1, 0.55)
                                            font.family: "Inter"
                                            font.pixelSize: 14
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Repeater {
                                        model: [
                                            { f: "player-skip-back.svg", c: "previous" },
                                            { f: "", c: "play-pause" },
                                            { f: "player-skip-forward.svg", c: "next" }
                                        ]
                                        delegate: Item {
                                            Layout.preferredWidth: modelData.c === "play-pause" ? 34 : 28
                                            Layout.preferredHeight: 34
                                            opacity: media.live ? (pm.containsMouse ? 1 : 0.92) : 0.35
                                            Kirigami.Icon {
                                                anchors.centerIn: parent
                                                width: modelData.c === "play-pause" ? 26 : 20
                                                height: width
                                                source: modelData.c === "play-pause"
                                                        ? panel.ic(ctl.mediaStatus === "Playing" ? "player-pause.svg" : "player-play.svg")
                                                        : panel.ic(modelData.f)
                                                isMask: true
                                                color: "#ffffff"
                                            }
                                            MouseArea {
                                                id: pm
                                                anchors.fill: parent
                                                enabled: media.live
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ctl.mpris(modelData.c)
                                            }
                                        }
                                    }
                                }
                                Item { Layout.fillHeight: true }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 14
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 4
                                        radius: 2
                                        color: Qt.rgba(1, 1, 1, 0.16)
                                        Rectangle {
                                            width: (media.live && ctl.mediaLen > 0) ? parent.width * Math.min(1, ctl.mediaPos / ctl.mediaLen) : 0
                                            height: parent.height
                                            radius: 2
                                            color: Qt.rgba(1, 1, 1, 0.92)
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: media.live && ctl.mediaLen > 0
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: function(m) { ctl.seek(Math.round(m.x / width * ctl.mediaLen)) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= PAGE 1: WI-FI SUBPAGE (Concept #6) =================
            Item {
                id: wifiPageItem
                x: panel.width; y: 0
                width: panel.width
                height: parent.height

                WifiSubPage {
                    id: wifiSubView
                    x: panel.pad
                    y: 0
                    width: panel.width - 2 * panel.pad
                    ctl: panel.ctl
                    onBackRequested: panel.currentPage = 0
                }
            }

            // ================= PAGE 2: BLUETOOTH SUBPAGE =================
            Item {
                id: btPageItem
                x: panel.width * 2; y: 0
                width: panel.width
                height: parent.height

                BluetoothSubPage {
                    id: btSubView
                    x: panel.pad
                    y: 0
                    width: panel.width - 2 * panel.pad
                    ctl: panel.ctl
                    onBackRequested: panel.currentPage = 0
                }
            }
        }
    }
}
