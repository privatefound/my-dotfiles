import QtQuick
import qs.Commons

// 1px horizontal divider for panel sections. The alpha-on-foreground tint
// keeps the rule legible against the panel background without competing
// with text or borders.
import qs.Commons as OmarchyCommons
Rectangle {
  id: root

  property color foreground: OmarchyCommons.Color.foreground
  property real strength: 0.12

  width: parent ? parent.width : implicitWidth
  implicitWidth: 100
  implicitHeight: 1
  height: 1
  color: Qt.rgba(foreground.r, foreground.g, foreground.b, strength)
}
