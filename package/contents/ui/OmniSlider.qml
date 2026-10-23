import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Modern track slider: an illuminated fill sits inset inside a translucent track.
// Click or drag to set, mouse wheel to nudge. Optional label on the right side of the track.
Item {
    id: s
    property real value: 0
    property real step: 0.05
    property url iconSource
    property string label: ""
    property bool iconClickable: false
    property bool dragging: false
    property real dragValue: 0
    readonly property real shown: dragging ? dragValue : value
    signal moved(real v)
    signal iconClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 52
    implicitHeight: 52

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, ma.containsMouse ? 0.09 : 0.065)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Rectangle {
        id: fill
        readonly property real inset: 5
        readonly property real minW: height
        x: inset
        y: inset
        height: parent.height - 2 * inset
        width: minW + (parent.width - 2 * inset - minW) * Math.max(0, Math.min(1, s.shown))
        radius: height / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#f4f4f6" }
            GradientStop { position: 1.0; color: "#d6d6db" }
        }
        Behavior on width { enabled: !s.dragging; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    Kirigami.Icon {
        source: s.iconSource
        isMask: true
        color: "#2a2a30"
        width: 20; height: 20
        x: fill.x + (fill.minW - width) / 2
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: lbl
        visible: s.label !== ""
        text: s.label
        // dark text once the light fill reaches it, so it always stays readable
        color: (fill.x + fill.width > x + 4) ? "#2a2a30" : Qt.rgba(1, 1, 1, 0.9)
        font.family: "Inter"
        font.pixelSize: 15
        elide: Text.ElideRight
        width: Math.min(implicitWidth, s.width * 0.5)
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function update(mx) {
            var span = s.width - 2 * fill.inset - fill.minW
            var v = Math.max(0, Math.min(1, (mx - fill.inset - fill.minW / 2) / span))
            if (v < 0.01) v = 0
            s.dragValue = v
            s.moved(v)
        }
        onPressed: function(m) {
            if (s.iconClickable && m.x < fill.minW + fill.inset) { s.iconClicked(); return }
            s.dragging = true
            update(m.x)
        }
        onPositionChanged: function(m) { if (s.dragging) update(m.x) }
        onReleased: s.dragging = false
        onWheel: function(w) {
            var dir = w.angleDelta.y > 0 ? 1 : (w.angleDelta.y < 0 ? -1 : 0)
            if (dir !== 0) s.moved(Math.max(0, Math.min(1, Math.round((s.value + dir * s.step) * 100) / 100)))
            w.accepted = true
        }
    }
}
