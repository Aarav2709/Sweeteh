import QtQuick
import qs.theme

// physical spring using the shared motion tokens, overshoots and settles instead of easing
SpringAnimation {
    spring: Theme.anim.spring
    damping: Theme.anim.damping
    epsilon: 0.25
}
