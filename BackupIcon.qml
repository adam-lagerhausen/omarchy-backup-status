import QtQuick
import QtQuick.Shapes
import qs.Commons

Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  Shape {
    anchors.fill: parent
    antialiasing: true
    layer.enabled: true
    layer.samples: 4

    ShapePath {
      strokeColor: root.color
      strokeWidth: Math.max(1.2, root.iconSize * 0.09)
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      fillColor: "transparent"
      startX: root.width * 0.16
      startY: root.height * 0.28
      PathLine { x: root.width * 0.16; y: root.height * 0.78 }
      PathLine { x: root.width * 0.84; y: root.height * 0.78 }
      PathLine { x: root.width * 0.84; y: root.height * 0.28 }
      PathLine { x: root.width * 0.16; y: root.height * 0.28 }
    }

    ShapePath {
      strokeColor: root.color
      strokeWidth: Math.max(1.2, root.iconSize * 0.09)
      capStyle: ShapePath.RoundCap
      fillColor: "transparent"
      startX: root.width * 0.16
      startY: root.height * 0.42
      PathLine { x: root.width * 0.84; y: root.height * 0.42 }
    }

    ShapePath {
      strokeColor: root.color
      strokeWidth: Math.max(1.2, root.iconSize * 0.09)
      capStyle: ShapePath.RoundCap
      fillColor: "transparent"
      startX: root.width * 0.32
      startY: root.height * 0.60
      PathLine { x: root.width * 0.52; y: root.height * 0.60 }
    }
  }
}
