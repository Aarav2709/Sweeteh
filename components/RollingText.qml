import QtQuick
import qs.theme

// one character that rolls up out of view as the next rolls in from below, for clocks
Item {
    id: root

    property string text
    property alias font: now.font
    property alias color: now.color

    implicitWidth: Math.max(now.implicitWidth, old.implicitWidth)
    implicitHeight: now.implicitHeight
    clip: true

    onTextChanged: {
        if (now.text === text)
            return;
        old.text = now.text;
        now.text = text;
        if (Theme.anim.speed > 0 && old.text !== "")
            roll.restart();
    }

    Component.onCompleted: now.text = text

    Label {
        id: old

        y: -root.height
        font: now.font
        color: now.color
        opacity: 0
    }

    Label {
        id: now

        font.features: ({
                "tnum": 1
            })
    }

    ParallelAnimation {
        id: roll

        NumberAnimation {
            target: old
            property: "y"
            from: 0
            to: -root.height * 0.6
            duration: Theme.anim.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.anim.accel
        }

        NumberAnimation {
            target: old
            property: "opacity"
            from: 1
            to: 0
            duration: Theme.anim.normal
        }

        NumberAnimation {
            target: now
            property: "y"
            from: root.height * 0.6
            to: 0
            duration: Theme.anim.slow
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.anim.decel
        }

        NumberAnimation {
            target: now
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.anim.slow
        }
    }
}
