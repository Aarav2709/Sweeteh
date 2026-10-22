import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.services
import qs.components

// large clock and date straight on the wallpaper
ColumnLayout {
    spacing: -Theme.spacing.small
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.alpha("#000000", 0.45)
        shadowBlur: 0.6
        shadowVerticalOffset: 2
    }

    Label {
        text: Time.hours + ":" + Time.minutes
        font.pixelSize: Theme.font.hero
        font.weight: Font.DemiBold
        color: Theme.color.ink
    }

    Label {
        Layout.leftMargin: Theme.spacing.xs
        text: Time.date
        font.pixelSize: Theme.font.title
        font.weight: Font.Medium
        color: Theme.color.primary
    }
}
