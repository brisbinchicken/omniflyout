import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// Small round quick toggle with a label underneath. Glows in its own colour when active.
Item {
    id: r
    property string label: ""
    property url iconSource
    property bool active: false
    property color accent: "#fbbf24"
    signal clicked()

    Layout.fillWidth: true
    implicitWidth: 50
    implicitHeight: 48 + 8 + lbl.implicitHeight

    RectangularShadow {
        anchors.fill: disc
        radius: disc.radius
        blur: 20
        spread: 1
        color: Qt.rgba(r.accent.r, r.accent.g, r.accent.b, r.active ? 0.6 : 0)
        Behavior on color { ColorAnimation { duration: 220 } }
    }

    Rectangle {
        id: disc
        width: 48; height: 48
        radius: 24
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        color: r.active
               ? Qt.tint(Qt.rgba(0.086, 0.094, 0.114, 0.82), Qt.rgba(r.accent.r, r.accent.g, r.accent.b, 0.22))
               : Qt.rgba(1, 1, 1, ma.containsMouse ? 0.12 : 0.075)
        border.width: r.active ? 1.6 : 1
        border.color: r.active ? Qt.rgba(r.accent.r, r.accent.g, r.accent.b, 0.95) : Qt.rgba(1, 1, 1, 0.15)
        scale: ma.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Behavior on color { ColorAnimation { duration: 180 } }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 21; height: 21
            source: r.iconSource
            isMask: true
            color: r.active ? Qt.lighter(r.accent, 1.15) : Qt.rgba(1, 1, 1, 0.82)
        }
    }

    Text {
        id: lbl
        anchors.top: disc.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: r.label
        color: r.active ? Qt.lighter(r.accent, 1.1) : Qt.rgba(1, 1, 1, 0.62)
        font.family: "Inter"
        font.pixelSize: 12
    }

    MouseArea {
        id: ma
        anchors.fill: disc
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: r.clicked()
    }
}
