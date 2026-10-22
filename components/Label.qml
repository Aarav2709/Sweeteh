import QtQuick
import qs.theme

// themed text
Text {
    id: root

    // variable fonts ignore named weights, so the weight is mirrored onto the weight axis
    function syncAxes(): void {
        const axes = font.variableAxes;
        if (axes.wght === font.weight && axes.ROND === Theme.font.round)
            return;
        font.variableAxes = {
            "wght": font.weight,
            "ROND": Theme.font.round
        };
    }

    color: Theme.color.ink
    font.family: Theme.font.family
    font.pixelSize: Theme.font.body
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    onFontChanged: syncAxes()
    Component.onCompleted: syncAxes()

    Connections {
        target: Theme.font

        function onRoundChanged(): void {
            root.syncAxes();
        }
    }

    Behavior on color {
        ColorAnim {}
    }
}
