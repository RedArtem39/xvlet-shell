import QtQuick
import qs.services

// A card coming in (the prototype's `rise`): from 16 px lower, a little
// smaller and clear, to its place with the spring -- `index` steps of
// 40 ms after the first. start() plays it again (a popout opening, a tab).
SequentialAnimation {
    id: root
    property Item target
    property int index: 0
    property Translate shift: Translate { y: 0 }
    onTargetChanged: if (target) target.transform = [shift]

    PropertyAction { target: root.target; property: "opacity"; value: 0 }
    PropertyAction { target: root.shift; property: "y"; value: 16 }
    PropertyAction { target: root.target; property: "scale"; value: .97 }
    PauseAnimation { duration: Theme.ms(root.index * 40) }
    ParallelAnimation {
        NumberAnimation { target: root.target; property: "opacity"; to: 1; duration: Theme.ms(260); easing.type: Easing.OutCubic }
        NumberAnimation { target: root.shift; property: "y"; to: 0; duration: Theme.ms(550); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring }
        NumberAnimation { target: root.target; property: "scale"; to: 1; duration: Theme.ms(550); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring }
    }
}
