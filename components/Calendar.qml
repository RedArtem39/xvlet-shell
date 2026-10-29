import QtQuick
import qs.services

// A month: Monday first, today a cookie in primary, the arrows step months
Item {
    id: root
    property int off: 0
    readonly property date base: { const d = new Date(); d.setDate(1); d.setMonth(d.getMonth() + off); return d; }
    readonly property var cells: {
        const y = base.getFullYear(), m = base.getMonth(), first = (new Date(y, m, 1).getDay() + 6) % 7, out = [], today = new Date();
        for (let i = 0; i < 42; i++) {
            const d = new Date(y, m, 1 - first + i);
            out.push({ n: d.getDate(), other: d.getMonth() !== m, today: d.toDateString() === today.toDateString() });
        }
        return out;
    }
    implicitHeight: head.height + 10 + grid.implicitHeight

    Item {
        id: head
        width: parent.width; height: 34
        Label { text: Qt.locale("ru_RU").standaloneMonthName(root.base.getMonth()) + " " + root.base.getFullYear(); size: 17; w: Font.Bold; anchors.verticalCenter: parent.verticalCenter; font.capitalization: Font.Capitalize }
        Row {
            anchors.right: parent.right
            IconButton { icon: "chevron_left"; size: 34; iconSize: 20; onClicked: root.off-- }
            IconButton { icon: "chevron_right"; size: 34; iconSize: 20; onClicked: root.off++ }
        }
    }
    Grid {
        id: grid
        y: head.height + 10
        columns: 7
        width: parent.width
        readonly property real cw: width / 7
        Repeater {
            model: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
            Label { required property string modelData; width: grid.cw; height: 26; text: modelData; size: 11; w: Font.Bold; dim: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        Repeater {
            model: root.cells
            Item {
                id: c
                required property var modelData
                width: grid.cw; height: 34
                MShape { anchors.centerIn: parent; width: 34; height: 34; visible: c.modelData.today; shape: Theme.shCookie4; color: Theme.primary }
                Rectangle { anchors.centerIn: parent; width: 34; height: 34; radius: ma.containsMouse ? 10 : 17; visible: !c.modelData.today && ma.containsMouse; color: Theme.surfaceHighest }
                Label {
                    anchors.centerIn: parent
                    text: c.modelData.n; size: 13
                    color: c.modelData.today ? Theme.fgPrimary : c.modelData.other ? Theme.outline : Theme.fgSurface
                }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }
            }
        }
    }
}
