import QtQuick
import org.kde.kirigami as Kirigami

// Round icon button (header session actions).
Rectangle {
    id: b
    property url iconSource
    property string tip: ""
    signal clicked()

    width: 42; height: 42
    radius: 21
    color: Qt.rgba(1, 1, 1, ma.pressed ? 0.16 : (ma.containsMouse ? 0.13 : 0.08))
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.16)
    Behavior on color { ColorAnimation { duration: 120 } }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: 19; height: 19
        source: b.iconSource
        isMask: true
        color: "#ffffff"
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
