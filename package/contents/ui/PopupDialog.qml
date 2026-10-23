import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore

// Frameless applet popup dialog. KWin blurs the desktop behind it when frameMode is true.
PlasmaCore.Dialog {
    id: dlg
    property var ctl: null
    property var panelComp: null
    property double closedAt: 0
    readonly property bool frameMode: ctl ? ctl.blurOn : false

    visualParent: ctl
    location: ctl ? ctl.plasmoidLocation : PlasmaCore.Types.BottomEdge
    type: PlasmaCore.Dialog.AppletPopup
    hideOnWindowDeactivate: true
    backgroundHints: frameMode ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground
    visible: false

    mainItem: Item {
        id: holder
        readonly property real pad: dlg.frameMode ? 0 : 8

        implicitWidth: ld.implicitWidth + 2 * pad
        implicitHeight: ld.implicitHeight + 2 * pad
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: implicitHeight

        Loader {
            id: ld
            x: holder.pad
            y: holder.pad
            width: implicitWidth
            height: implicitHeight
            active: dlg.panelComp !== null
            sourceComponent: dlg.panelComp
        }
    }

    function toggle() {
        if (visible) visible = false
        else if (Date.now() - closedAt > 250) visible = true
    }
    onVisibleChanged: if (!visible) closedAt = Date.now()
}
