import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Dedicated sliding sub-page for Bluetooth device selection and management (Concept #6 extension).
Item {
    id: sub
    property var ctl
    signal backRequested()

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
                        color: "#3b82f6"
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
                text: "Bluetooth Devices"
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
                    color: (ctl && ctl.btScanning) ? "#3b82f6" : "#ffffff"
                    rotation: (ctl && ctl.btScanning) ? 360 : 0
                    Behavior on rotation { NumberAnimation { duration: 800; loops: Animation.Infinite } }
                }
                MouseArea {
                    id: rm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (ctl) ctl.rescanBt()
                }
            }
        }

        // ================= Discoverable Telemetry Badge =================
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 30
            implicitWidth: aliasRow.implicitWidth + 24
            radius: 15
            color: Qt.rgba(59/255, 130/255, 246/255, 0.12)
            border.width: 1
            border.color: Qt.rgba(59/255, 130/255, 246/255, 0.35)

            RowLayout {
                id: aliasRow
                anchors.centerIn: parent
                spacing: 7
                Rectangle {
                    width: 7; height: 7
                    radius: 3.5
                    color: (ctl && ctl.btOn) ? "#3b82f6" : "#ef4444"
                }
                Text {
                    text: (ctl && ctl.btOn)
                          ? ("Discoverable as \"" + (ctl.btAlias || "cachy-vitg") + "\"")
                          : "Bluetooth Radio Off"
                    color: "#60a5fa"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        // ================= Master Bluetooth Power Card =================
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
                    source: sub.ic((ctl && ctl.btOn) ? "bluetooth.svg" : "bluetooth-off.svg")
                    isMask: true
                    color: (ctl && ctl.btOn) ? "#3b82f6" : Qt.rgba(1, 1, 1, 0.6)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "Bluetooth Radio"
                        color: "#ffffff"
                        font.family: "Inter"
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        text: (ctl && ctl.btOn)
                              ? ("Enabled · " + (ctl.btCount > 0 ? ctl.btCount + " connected" : "Ready for connections"))
                              : "Disabled"
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
                    color: (ctl && ctl.btOn) ? "#3b82f6" : Qt.rgba(1, 1, 1, 0.16)
                    Behavior on color { ColorAnimation { duration: 180 } }

                    Rectangle {
                        width: 20; height: 20
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        x: (ctl && ctl.btOn) ? parent.width - width - 3 : 3
                        color: "#ffffff"
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (ctl) ctl.toggleBt()
                    }
                }
            }
        }

        // ================= If Bluetooth is Disabled =================
        Rectangle {
            visible: ctl ? !ctl.btOn : true
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
                    text: "Bluetooth is turned off"
                    color: "#ffffff"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Toggle the switch above to enable Bluetooth"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: "Inter"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // ================= Connected Device Card(s) =================
        ColumnLayout {
            id: connGroup
            visible: (ctl && ctl.btOn && sub.hasConnectedDevice)
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

            Repeater {
                model: ctl ? ctl.btDevices : []
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.connected
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    radius: 18
                    color: Qt.rgba(59/255, 130/255, 246/255, 0.12)
                    border.width: 1.4
                    border.color: Qt.rgba(59/255, 130/255, 246/255, 0.55)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Kirigami.Icon {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            source: sub.ic(modelData.icon)
                            isMask: true
                            color: "#60a5fa"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            RowLayout {
                                spacing: 6
                                Text {
                                    text: modelData.name
                                    color: "#ffffff"
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    visible: modelData.battery !== null
                                    radius: 6
                                    color: Qt.rgba(34/255, 197/255, 94/255, 0.2)
                                    implicitWidth: battText.implicitWidth + 8
                                    implicitHeight: 18
                                    Text {
                                        id: battText
                                        anchors.centerIn: parent
                                        text: (modelData.battery !== null ? modelData.battery + "% 🔋" : "")
                                        color: "#4ade80"
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }
                            Text {
                                text: "Active · Connected"
                                color: "#60a5fa"
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
                                onClicked: if (ctl) ctl.disconnectBt(modelData.mac)
                            }
                        }
                    }
                }
            }
        }

        // ================= Paired & Available Devices List =================
        ColumnLayout {
            visible: ctl ? ctl.btOn : false
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "PAIRED DEVICES"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.2
                    Layout.leftMargin: 4
                }
                Text {
                    visible: ctl ? ctl.btScanning : false
                    text: "Scanning..."
                    color: "#60a5fa"
                    font.family: "Inter"
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(270, Math.max(70, devCol.implicitHeight + 16))
                radius: 20
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)
                clip: true

                Flickable {
                    id: devFlick
                    anchors.fill: parent
                    anchors.margins: 8
                    contentHeight: devCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        target: devFlick
                    }

                    ColumnLayout {
                        id: devCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: ctl ? ctl.btDevices : []
                            delegate: Rectangle {
                                required property var modelData
                                visible: !modelData.connected
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                radius: 12
                                color: devMa.pressed ? Qt.rgba(1, 1, 1, 0.14) : (devMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    Kirigami.Icon {
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        source: sub.ic(modelData.icon)
                                        isMask: true
                                        color: Qt.rgba(1, 1, 1, 0.7)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            color: "#ffffff"
                                            font.family: "Inter"
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: modelData.paired ? "Paired" : "Nearby Device"
                                            color: Qt.rgba(1, 1, 1, 0.45)
                                            font.family: "Inter"
                                            font.pixelSize: 11
                                        }
                                    }

                                    Text {
                                        visible: ctl && ctl.btConnectingMac === modelData.mac
                                        text: "Connecting..."
                                        color: "#60a5fa"
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                    }

                                    Rectangle {
                                        visible: !(ctl && ctl.btConnectingMac === modelData.mac)
                                        Layout.preferredWidth: 68
                                        Layout.preferredHeight: 28
                                        radius: 8
                                        color: Qt.rgba(59/255, 130/255, 246/255, btnMa.containsMouse ? 0.3 : 0.18)
                                        border.width: 1
                                        border.color: Qt.rgba(59/255, 130/255, 246/255, 0.4)
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.paired ? "Connect" : "Pair"
                                            color: "#93c5fd"
                                            font.family: "Inter"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                        MouseArea {
                                            id: btnMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.paired) {
                                                    if (ctl) ctl.connectBt(modelData.mac)
                                                } else {
                                                    if (ctl) ctl.pairBt(modelData.mac)
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: devMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.paired) {
                                            if (ctl) ctl.connectBt(modelData.mac)
                                        } else {
                                            if (ctl) ctl.pairBt(modelData.mac)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: (ctl ? ctl.btDevices.length === 0 : false) && !(ctl && ctl.btScanning)
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "No paired devices found. Click ⟳ to scan."
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.family: "Inter"
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }

        // ================= Bottom Button: Open Bluetooth Settings =================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 12
            color: setMa.pressed ? Qt.rgba(1, 1, 1, 0.12) : (setMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.045))
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)
            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Kirigami.Icon {
                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 15
                    source: sub.ic("adjustments-horizontal.svg")
                    isMask: true
                    color: Qt.rgba(1, 1, 1, 0.6)
                }
                Text {
                    text: "Open Advanced Bluetooth Settings"
                    color: Qt.rgba(1, 1, 1, 0.8)
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            MouseArea {
                id: setMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (ctl) ctl.openSettings("kcm_bluetooth")
            }
        }
    }

    readonly property bool hasConnectedDevice: {
        if (!ctl || !ctl.btDevices) return false
        for (var i = 0; i < ctl.btDevices.length; i++) {
            if (ctl.btDevices[i].connected) return true
        }
        return false
    }
}
