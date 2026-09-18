import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.adam-lagerhausen.backup-status"
  ipcTarget: "io.github.adam-lagerhausen.backup-status"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var status: Model.emptyStatus()
  property double nowMs: Date.now()

  readonly property var barIdentity: hostWidget || root
  readonly property var view: Model.present(status, nowMs)
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    nowMs = Date.now()
    if (hostWidget && hostWidget.refresh) hostWidget.refresh()
    root.controller.show()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function refresh() {
    nowMs = Date.now()
    if (hostWidget && hostWidget.refresh) hostWidget.refresh()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && typeof root.bar.setCenterHoverRevealSuppressed === "function")
      root.bar.setCenterHoverRevealSuppressed(value)
  }

  function pillColor(kind) {
    if (kind === "fail") return Color.urgent
    if (kind === "warn" || kind === "run") return Color.accent
    return foreground
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.refresh()
      }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        Item {
          width: parent.width
          implicitHeight: hero.implicitHeight

          PanelHero {
            id: hero
            width: parent.width
            title: "Backups"
            meta: root.view.meta
            detail: root.view.pill
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              BackupIcon {
                iconSize: Style.font.display
                color: root.view.state === "healthy" ? root.foreground : root.pillColor(root.view.pillKind)
              }
            }
            trailingControl: Component {
              PanelActionButton {
                iconText: "\uf021"
                tooltipText: "Refresh"
                foreground: hero.foreground
                fontFamily: hero.fontFamily
                onClicked: root.refresh()
              }
            }
          }
        }

        PanelSeparator {
          visible: root.view.showQuota
          foreground: root.foreground
        }

        Column {
          visible: root.view.showQuota
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "BORGBASE"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            Text {
              text: root.view.quotaLeft
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Item {
              width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2)
              height: 1
            }

            Text {
              text: root.view.quotaRight
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }

          Rectangle {
            width: parent.width
            height: Style.space(6)
            radius: Style.cornerRadius > 0 ? height / 2 : 0
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

            Rectangle {
              width: Math.round(parent.width * Math.max(0, Math.min(1, root.view.quotaPercent / 100)))
              height: parent.height
              radius: parent.radius
              color: root.view.quotaPercent >= 90 ? Color.accent : Color.accent
            }
          }
        }

        PanelSeparator { foreground: root.foreground }

        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "JOBS"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          JobRow {
            width: parent.width
            job: root.view.databases
            glyph: "\uf1c0"
          }

          JobRow {
            width: parent.width
            job: root.view.workstation
            glyph: "\uf108"
          }
        }

        PanelSeparator {
          visible: root.view.showNotes
          foreground: root.foreground
        }

        Column {
          visible: root.view.showNotes
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "NOTES"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Repeater {
            model: root.view.notes

            Text {
              required property var modelData
              width: column.width
              text: String(modelData.text || "")
              color: modelData.fail === true ? Color.urgent : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }
          }
        }
      }
    }
  }

  Timer {
    interval: 30000
    running: root.opened
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  component JobRow: Item {
    id: row
    property var job: ({})
    property string glyph: ""

    implicitHeight: body.implicitHeight + Style.space(8)

    RowLayout {
      id: body
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(10)

      Text {
        text: row.glyph
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: Style.space(2)
      }

      Column {
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          width: parent.width
          text: String(row.job.title || "")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: String(row.job.sub || "") !== ""
          text: String(row.job.sub || "")
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: String(row.job.archive || "") !== ""
          text: String(row.job.archive || "")
          color: Qt.darker(root.foreground, 1.9)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: String(row.job.err || "") !== ""
          text: String(row.job.err || "")
          color: Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }

      StatusPill {
        kind: String(row.job.pillKind || "ok")
        label: String(row.job.pill || "OK")
        Layout.alignment: Qt.AlignTop
      }
    }
  }

  component StatusPill: Rectangle {
    property string kind: "ok"
    property string label: "OK"

    implicitWidth: pillText.implicitWidth + Style.space(10)
    implicitHeight: pillText.implicitHeight + Style.space(4)
    color: "transparent"
    radius: Style.cornerRadius
    border.width: 1
    border.color: Qt.rgba(root.pillColor(kind).r, root.pillColor(kind).g, root.pillColor(kind).b, 0.55)

    Text {
      id: pillText
      anchors.centerIn: parent
      text: label
      color: root.pillColor(kind)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }
  }
}
