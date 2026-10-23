import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Dedicated sliding sub-page for Wi-Fi network selection and management (Concept #6).
Item {
    id: sub
    property var ctl
    signal backRequested()

    property string selectedSsid: ""
    property string enteredPassword: ""
    property bool passwordPromptOpen: false

    implicitWidth: parent ? parent.width : 364
    implicitHeight: col.implicitHeight

    function ic(f) { return ctl ? (ctl.iconBase + f) : "" }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        // ================= Header: Back button, Title, Rescan =================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                id: backBtn
                Layout.preferredWidth: 84
                Layout.preferredHeight: 38
                radius: 19
                color: Qt.rgba(1, 1, 1, bm.pressed ? 0.16 : (bm.containsMouse ? 0.12 : 0.07))
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "‹"
                        color: "#38bdf8"
                        font.family: "Inter"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        text: "Back"
                        color: "#ffffff"
                        font.family: "Inter"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
                MouseArea {
                    id: bm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sub.backRequested()
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Wi-Fi Networks"
                color: "#ffffff"
                font.family: "Inter"
                font.pixelSize: 17
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                id: rescanBtn
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: Qt.rgba(1, 1, 1, rm.pressed ? 0.16 : (rm.containsMouse ? 0.12 : 0.07))
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
                Behavior on color { ColorAnimation { duration: 120 } }

                Kirigami.Icon {
                    id: rescanIcon
                    anchors.centerIn: parent
                    width: 18; height: 18
                    source: sub.ic("rotate-clockwise.svg")
                    isMask: true
                    color: ctl && ctl.wifiScanning ? "#38bdf8" : "#ffffff"
                    rotation: ctl && ctl.wifiScanning ? 360 : 0
                    Behavior on rotation { NumberAnimation { duration: 800; loops: Animation.Infinite } }
                }
                MouseArea {
                    id: rm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (ctl) ctl.rescanWifi()
                }
            }
        }

        // ================= Real Physical IP Badge =================
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 30
            implicitWidth: ipRow.implicitWidth + 24
            radius: 15
            color: Qt.rgba(45/255, 212/255, 191/255, 0.12)
            border.width: 1
            border.color: Qt.rgba(45/255, 212/255, 191/255, 0.35)

            RowLayout {
                id: ipRow
                anchors.centerIn: parent
                spacing: 7
                Rectangle {
                    width: 7; height: 7
                    radius: 3.5
                    color: (ctl && ctl.activeIp !== "") ? "#2dd4bf" : "#ef4444"
                }
                Text {
                    text: (ctl && ctl.activeIp !== "")
                          ? ("IP: " + ctl.activeIp + (ctl.activeIpType !== "" ? " (" + ctl.activeIpType + " Active)" : ""))
                          : "No Physical Network Connected"
                    color: "#2dd4bf"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        // ================= Master Wi-Fi Power Card =================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: 20
            color: Qt.rgba(1, 1, 1, 0.065)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Kirigami.Icon {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    source: sub.ic(ctl && ctl.wifiOn ? "wifi.svg" : "wifi-off.svg")
                    isMask: true
                    color: ctl && ctl.wifiOn ? "#38bdf8" : Qt.rgba(1, 1, 1, 0.6)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "Wi-Fi Wireless"
                        color: "#ffffff"
                        font.family: "Inter"
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        text: (ctl && ctl.wifiOn) ? "Enabled · Searching for connections" : "Disabled"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.family: "Inter"
                        font.pixelSize: 11
                    }
                }

                // Frosted switch toggle
                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 26
                    radius: 13
                    color: (ctl && ctl.wifiOn) ? "#38bdf8" : Qt.rgba(1, 1, 1, 0.16)
                    Behavior on color { ColorAnimation { duration: 180 } }

                    Rectangle {
                        width: 20; height: 20
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        x: (ctl && ctl.wifiOn) ? parent.width - width - 3 : 3
                        color: "#ffffff"
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (ctl) ctl.toggleWifi()
                    }
                }
            }
        }

        // ================= If Wi-Fi is Disabled =================
        Rectangle {
            visible: ctl ? !ctl.wifiOn : true
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            radius: 20
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: "Wi-Fi is turned off"
                    color: "#ffffff"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Toggle the switch above to enable Wi-Fi"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: "Inter"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // ================= Password Prompt Dialog (If open) =================
        Rectangle {
            id: promptCard
            visible: sub.passwordPromptOpen
            Layout.fillWidth: true
            Layout.preferredHeight: 130
            radius: 20
            color: Qt.rgba(15/255, 30/255, 45/255, 0.85)
            border.width: 1.5
            border.color: Qt.rgba(56/255, 189/255, 248/255, 0.5)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Connect to \"" + sub.selectedSsid + "\""
                        color: "#ffffff"
                        font.family: "Inter"
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "✕"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { sub.passwordPromptOpen = false; sub.enteredPassword = "" }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.09)
                    border.width: 1
                    border.color: pwdInput.activeFocus ? "#38bdf8" : Qt.rgba(1, 1, 1, 0.2)

                    TextInput {
                        id: pwdInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        font.family: "Inter"
                        font.pixelSize: 13
                        color: "#ffffff"
                        clip: true
                        focus: sub.passwordPromptOpen
                        onTextChanged: sub.enteredPassword = text
                        onAccepted: {
                            if (ctl) ctl.connectWifi(sub.selectedSsid, sub.enteredPassword)
                            sub.passwordPromptOpen = false
                            sub.enteredPassword = ""
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !pwdInput.text && !pwdInput.activeFocus
                            text: "Enter Wi-Fi password..."
                            color: Qt.rgba(1, 1, 1, 0.35)
                            font.family: "Inter"
                            font.pixelSize: 13
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 30
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "#ffffff"
                            font.family: "Inter"
                            font.pixelSize: 12
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { sub.passwordPromptOpen = false; sub.enteredPassword = "" }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 30
                        radius: 10
                        color: "#38bdf8"
                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: "#0f172a"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (ctl) ctl.connectWifi(sub.selectedSsid, sub.enteredPassword)
                                sub.passwordPromptOpen = false
                                sub.enteredPassword = ""
                            }
                        }
                    }
                }
            }
        }

        // ================= Connected Network Card (If any) =================
        ColumnLayout {
            visible: ctl ? (ctl.wifiOn && ctl.wifiConn && ctl.wifiSsid !== "") : false
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "CONNECTED"
                color: Qt.rgba(1, 1, 1, 0.45)
                font.family: "Inter"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.2
                Layout.leftMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: 18
                color: Qt.rgba(56/255, 189/255, 248/255, 0.12)
                border.width: 1.4
                border.color: Qt.rgba(56/255, 189/255, 248/255, 0.5)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Kirigami.Icon {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: sub.ic("check.svg")
                        isMask: true
                        color: "#38bdf8"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: ctl ? ctl.wifiSsid : ""
                            color: "#ffffff"
                            font.family: "Inter"
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: "Connected · Active connection"
                            color: "#38bdf8"
                            font.family: "Inter"
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 84
                        Layout.preferredHeight: 30
                        radius: 15
                        color: discMa.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: "Disconnect"
                            color: "#ffffff"
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        MouseArea {
                            id: discMa
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (ctl) ctl.disconnectWifi()
                        }
                    }
                }
            }
        }

        // ================= Available Networks List =================
        ColumnLayout {
            visible: ctl ? ctl.wifiOn : false
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "AVAILABLE NETWORKS"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.2
                    Layout.leftMargin: 4
                }
                Text {
                    visible: ctl ? ctl.wifiScanning : false
                    text: "Scanning..."
                    color: "#38bdf8"
                    font.family: "Inter"
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(260, Math.max(70, netCol.implicitHeight + 16))
                radius: 20
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)
                clip: true

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 8
                    contentHeight: netCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: netCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: ctl ? ctl.wifiNetworks : []
                            delegate: Rectangle {
                                required property var modelData
                                visible: ctl ? (modelData.ssid !== ctl.wifiSsid) : true
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                radius: 12
                                color: netMa.pressed ? Qt.rgba(1, 1, 1, 0.14) : (netMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    Kirigami.Icon {
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        source: sub.ic("wifi.svg")
                                        isMask: true
                                        color: modelData.signal > 60 ? "#38bdf8" : Qt.rgba(1, 1, 1, 0.7)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.ssid
                                            color: "#ffffff"
                                            font.family: "Inter"
                                            font.pixelSize: 14
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: (modelData.security ? modelData.security + " · " : "") + modelData.signal + "% signal"
                                            color: Qt.rgba(1, 1, 1, 0.45)
                                            font.family: "Inter"
                                            font.pixelSize: 11
                                        }
                                    }

                                    Kirigami.Icon {
                                        visible: modelData.is_locked
                                        Layout.preferredWidth: 14
                                        Layout.preferredHeight: 14
                                        source: sub.ic("lock.svg")
                                        isMask: true
                                        color: Qt.rgba(1, 1, 1, 0.45)
                                    }

                                    Text {
                                        visible: ctl && ctl.wifiConnectingSsid === modelData.ssid
                                        text: "Connecting..."
                                        color: "#38bdf8"
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: netMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.is_locked) {
                                            sub.selectedSsid = modelData.ssid
                                            sub.passwordPromptOpen = true
                                        } else {
                                            if (ctl) ctl.connectWifi(modelData.ssid, "")
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: ctl ? (ctl.wifiNetworks.length === 0 && !ctl.wifiScanning) : false
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "No networks found. Click ⟳ to scan."
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.family: "Inter"
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }

        // ================= Bottom Shortcut to KDE Network Settings =================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 12
            color: Qt.rgba(1, 1, 1, setMa.containsMouse ? 0.08 : 0.04)
            Text {
                anchors.centerIn: parent
                text: "Open System Network Settings →"
                color: setMa.containsMouse ? "#38bdf8" : Qt.rgba(1, 1, 1, 0.6)
                font.family: "Inter"
                font.pixelSize: 12
                font.bold: true
            }
            MouseArea {
                id: setMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (ctl) ctl.openSettings("kcm_networkmanagement")
            }
        }
    }
}
