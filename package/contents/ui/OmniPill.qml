import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// Large pill toggle: coloured icon disc + title/subtitle, neon outline and soft glow when active.
// Clicking icon disc = iconClicked(), clicking body/chevron = clicked().
Item {
    id: p
    property string title: ""
    property string sub: ""
    property url iconSource
    property url chevronSource: ""
    property bool active: false
    property color accent: "#2dd4bf"
    property bool showChevron: false
    signal clicked()
    signal iconClicked()
    signal chevronClicked()
    signal rightClicked()
    signal wheelMoved(int dir)

    Layout.fillWidth: true
    Layout.preferredHeight: 64
    implicitHeight: 64

    RectangularShadow {
        anchors.fill: bg
        radius: bg.radius
        blur: 24
        spread: 1
        color: Qt.rgba(p.accent.r, p.accent.g, p.accent.b, p.active ? 0.55 : 0)
        Behavior on color { ColorAnimation { duration: 220 } }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2
        color: p.active
               ? Qt.tint(Qt.rgba(0.086, 0.094, 0.114, 0.82), Qt.rgba(p.accent.r, p.accent.g, p.accent.b, 0.16))
               : Qt.rgba(1, 1, 1, ma.containsMouse ? 0.10 : 0.065)
        border.width: p.active ? 1.6 : 1
        border.color: p.active ? Qt.rgba(p.accent.r, p.accent.g, p.accent.b, 0.9) : Qt.rgba(1, 1, 1, 0.14)
        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: p.showChevron ? 14 : 14
        spacing: 12

        // Icon circle
        Rectangle {
            id: iconDisc
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            radius: 21
            color: p.active ? p.accent : Qt.rgba(1, 1, 1, iconMa.containsMouse ? 0.20 : 0.12)
            Behavior on color { ColorAnimation { duration: 180 } }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 20; height: 20
                source: p.iconSource
                isMask: true
                color: p.active ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
            }

            MouseArea {
                id: iconMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: p.iconClicked()
            }
        }

        // Title & Subtitle
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: p.title + "  <font color='#80ffffff'>·</font>"
                textFormat: Text.StyledText
                color: "#ffffff"
                font.family: "Inter"
                font.pixelSize: 15
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: p.sub
                color: p.active ? Qt.lighter(p.accent, 1.25) : Qt.rgba(1, 1, 1, 0.5)
                font.family: "Inter"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        // Chevron icon on the right
        Kirigami.Icon {
            visible: p.showChevron
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
            source: p.chevronSource
            isMask: true
            color: p.active ? Qt.lighter(p.accent, 1.25) : Qt.rgba(1, 1, 1, 0.6)
            opacity: ma.containsMouse ? 1.0 : 0.75
        }
    }

    // Body mouse area: covers everything to the right of the icon disc
    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.leftMargin: 56
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(m) {
            if (m.button === Qt.RightButton) {
                p.rightClicked()
            } else {
                p.clicked()
                if (p.showChevron) p.chevronClicked()
            }
        }
        onWheel: function(w) {
            var dir = w.angleDelta.y > 0 ? 1 : (w.angleDelta.y < 0 ? -1 : 0)
            if (dir !== 0) p.wheelMoved(dir)
        }
    }
}
