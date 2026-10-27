import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.theme
import qs.services
import qs.components

// frozen screen to select a region or window, saved and copied as png or recorded
PanelWindow {
    id: root

    required property string kind
    property string mode: kind === "screen" || kind === "record" ? "region" : kind
    property bool record: kind === "record"
    property rect selection: Qt.rect(0, 0, 0, 0)
    property bool ready: frozen.hasContent
    readonly property real dpr: screen?.devicePixelRatio ?? 1
    readonly property var monitor: Hypr.focusedMonitor
    readonly property var windows: Hypr.toplevels.values.filter(t => t.workspace?.id === Hypr.activeWorkspace && t.lastIpcObject?.at).map(t => Qt.rect(t.lastIpcObject.at[0] - (monitor?.x ?? 0), t.lastIpcObject.at[1] - (monitor?.y ?? 0), t.lastIpcObject.size[0], t.lastIpcObject.size[1]))
    property rect hovered: Qt.rect(0, 0, 0, 0)
    // the window the arrow keys picked, in window mode
    property int windowIndex: -1

    // everything works from the keyboard, tab flips the mode, arrows move, shift arrows resize, alt for single pixels
    function nudge(dx: int, dy: int, resize: bool): void {
        if (mode === "window") {
            if (windows.length === 0)
                return;
            windowIndex = (windowIndex + (dx + dy > 0 ? 1 : -1) + windows.length) % windows.length;
            hovered = windows[windowIndex];
            return;
        }
        // the first arrow press starts from a centered half of the screen
        let r = selection.width > 0 ? selection : Qt.rect(width / 4, height / 4, width / 2, height / 2);
        if (selection.width > 0) {
            if (resize)
                r = Qt.rect(r.x, r.y, Math.max(8, r.width + dx), Math.max(8, r.height + dy));
            else
                r = Qt.rect(r.x + dx, r.y + dy, r.width, r.height);
        }
        selection = Qt.rect(Math.max(0, Math.min(width - r.width, r.x)), Math.max(0, Math.min(height - r.height, r.y)), Math.min(width, r.width), Math.min(height, r.height));
    }

    function capture(): void {
        if (mode === "window" && hovered.width > 0)
            save(hovered);
        else
            save(selection.width > 0 ? selection : Qt.rect(0, 0, width, height));
    }

    signal finished

    screen: Hypr.screenFor(Hypr.focusedScreenName)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sweeteh-screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    onReadyChanged: {
        if (ready && kind === "screen")
            save(Qt.rect(0, 0, width, height));
    }

    function save(r: rect): void {
        if (r.width < 4 || r.height < 4)
            return;
        if (record) {
            // full screen records the monitor itself, anything smaller its region in layout pixels
            const whole = r.width >= width - 1 && r.height >= height - 1;
            const g = `${Math.round((monitor?.x ?? 0) + r.x)},${Math.round((monitor?.y ?? 0) + r.y)} ${Math.round(r.width)}x${Math.round(r.height)}`;
            root.finished();
            Recorder.start(whole ? "" : g);
            return;
        }
        crop.sourceRect = r;
        crop.width = r.width;
        crop.height = r.height;
        const dir = Paths.expand(Config.options.general.screenshotDir);
        const file = dir + "/Screenshot_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".png";
        Quickshell.execDetached(["mkdir", "-p", dir]);
        crop.grabToImage(result => {
            if (!result.saveToFile(file)) {
                Actions.say("error", "Could not save the screenshot.");
                root.finished();
                return;
            }
            Quickshell.execDetached(["sh", "-c", `command -v wl-copy >/dev/null && wl-copy --type image/png < ${Paths.quote(file)}; notify-send -a Sweeteh -i ${Paths.quote(file)} -h ${Paths.quote("string:image-path:" + file)} 'Screenshot saved' ${Paths.quote(file.replace(Paths.home, "~"))}`]);
            Actions.say("screenshot", "Screenshot saved and copied.");
            root.finished();
        }, Qt.size(Math.round(r.width * dpr), Math.round(r.height * dpr)));
    }

    ScreencopyView {
        id: frozen

        anchors.fill: parent
        captureSource: root.screen
        live: false
    }

    ShaderEffectSource {
        id: crop

        // sits behind the frozen view, grabbing needs it in the scene
        z: -1
        sourceItem: frozen
        live: true
    }

    Item {
        anchors.fill: parent
        visible: root.ready && root.kind !== "screen"
        focus: true
        Keys.onEscapePressed: root.finished()
        Keys.onReturnPressed: root.capture()
        Keys.onEnterPressed: root.capture()
        Keys.onSpacePressed: root.capture()
        Keys.onPressed: e => {
            const step = (e.modifiers & Qt.AltModifier) ? 1 : 20;
            const resize = (e.modifiers & Qt.ShiftModifier) !== 0;
            const moves = { [Qt.Key_Left]: [-step, 0], [Qt.Key_Right]: [step, 0], [Qt.Key_Up]: [0, -step], [Qt.Key_Down]: [0, step] };
            if (moves[e.key]) {
                root.nudge(moves[e.key][0], moves[e.key][1], resize);
            } else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
                root.mode = root.mode === "window" ? "region" : "window";
                root.selection = Qt.rect(0, 0, 0, 0);
                root.windowIndex = -1;
                root.hovered = Qt.rect(0, 0, 0, 0);
                if (root.mode === "window")
                    root.nudge(1, 0, false);
            } else if (e.key === Qt.Key_F) {
                root.save(Qt.rect(0, 0, root.width, root.height));
            } else if (e.key === Qt.Key_R) {
                root.record = !root.record;
            } else {
                return;
            }
            e.accepted = true;
        }

        // dim everything outside the selection
        Repeater {
            model: [Qt.rect(0, 0, root.width, root.selection.y), Qt.rect(0, root.selection.y + root.selection.height, root.width, root.height), Qt.rect(0, root.selection.y, root.selection.x, root.selection.height), Qt.rect(root.selection.x + root.selection.width, root.selection.y, root.width, root.selection.height)]

            Rectangle {
                required property rect modelData

                x: modelData.x
                y: modelData.y
                width: Math.max(0, modelData.width)
                height: Math.max(0, modelData.height)
                color: Theme.color.scrim
                opacity: 0.45
            }
        }

        Rectangle {
            x: root.selection.x
            y: root.selection.y
            width: root.selection.width
            height: root.selection.height
            color: "transparent"
            border.width: 2
            border.color: root.record ? Theme.color.error : Theme.color.primary
            visible: root.selection.width > 0
        }

        Rectangle {
            visible: root.mode === "window" && root.hovered.width > 0
            x: root.hovered.x
            y: root.hovered.y
            width: root.hovered.width
            height: root.hovered.height
            color: Qt.alpha(Theme.color.primary, 0.15)
            border.width: 2
            border.color: Theme.color.primary
            radius: Theme.radius.small
        }

        Surface {
            visible: root.selection.width > 0
            x: Math.min(root.width - width - Theme.spacing.small, root.selection.x)
            y: root.selection.y > height + Theme.spacing.small ? root.selection.y - height - Theme.spacing.small : root.selection.y + Theme.spacing.small
            implicitWidth: dims.implicitWidth + Theme.spacing.medium * 2
            implicitHeight: 28
            radius: Theme.radius.full
            color: Theme.color.primary

            Label {
                id: dims

                anchors.centerIn: parent
                text: Math.round(root.selection.width * root.dpr) + " x " + Math.round(root.selection.height * root.dpr)
                color: Theme.color.fgPrimary
                font.pixelSize: Theme.font.small
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.mode === "window" ? Qt.PointingHandCursor : Qt.CrossCursor
            property point origin

            onPositionChanged: e => {
                if (root.mode === "window") {
                    root.hovered = root.windows.find(w => e.x >= w.x && e.x <= w.x + w.width && e.y >= w.y && e.y <= w.y + w.height) ?? Qt.rect(0, 0, 0, 0);
                } else if (pressed) {
                    root.selection = Qt.rect(Math.min(origin.x, e.x), Math.min(origin.y, e.y), Math.abs(e.x - origin.x), Math.abs(e.y - origin.y));
                }
            }
            onPressed: e => {
                origin = Qt.point(e.x, e.y);
                if (root.mode !== "window")
                    root.selection = Qt.rect(e.x, e.y, 0, 0);
            }
            onReleased: {
                if (root.mode === "window" && root.hovered.width > 0)
                    root.save(root.hovered);
                else if (root.selection.width > 4)
                    root.save(root.selection);
            }
        }

        Surface {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spacing.xxl
            implicitWidth: Math.max(bar.implicitWidth, hint.implicitWidth + Theme.spacing.large * 2) + Theme.spacing.small * 2
            implicitHeight: bar.implicitHeight + hint.implicitHeight + Theme.spacing.small * 3
            radius: Theme.radius.full
            color: Theme.color.panel
            border.width: Theme.depth.rim
            border.color: Theme.color.depthRim

            Depth {}

            Label {
                id: hint

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacing.small
                text: root.mode === "window" ? "Tab region  ·  arrows pick a window  ·  R record  ·  F full screen  ·  Enter capture" : "Tab window  ·  arrows move  ·  shift resize  ·  alt fine  ·  R record  ·  F full screen  ·  Enter capture"
                font.pixelSize: Theme.font.tiny
                color: Theme.color.inkMeta
            }

            RowLayout {
                id: bar

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.spacing.small
                spacing: Theme.spacing.xs

                IconButton {
                    icon: "screenshot_region"
                    checked: root.mode === "region"
                    onClicked: root.mode = "region"
                }

                IconButton {
                    icon: "select_window"
                    checked: root.mode === "window"
                    onClicked: {
                        root.mode = "window";
                        root.selection = Qt.rect(0, 0, 0, 0);
                    }
                }

                IconButton {
                    icon: "screenshot_monitor"
                    onClicked: root.save(Qt.rect(0, 0, root.width, root.height))
                }

                Rectangle {
                    implicitWidth: 1
                    implicitHeight: 20
                    color: Theme.color.hairline
                }

                IconButton {
                    icon: root.record ? "videocam" : "photo_camera"
                    checked: root.record
                    background: root.record ? Theme.color.error : "transparent"
                    foreground: root.record ? Theme.color.fgError : Theme.color.inkMeta
                    onClicked: root.record = !root.record
                }

                IconButton {
                    icon: "close"
                    onClicked: root.finished()
                }
            }
        }
    }
}
