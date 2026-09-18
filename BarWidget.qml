import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "io.github.adam-lagerhausen.backup-status"

  property var status: Model.emptyStatus()
  property bool refreshing: false

  readonly property string barStyle: {
    var value = String(setting("barStyle", "icon"))
    if (value === "pip" || value === "label") return value
    return "icon"
  }
  readonly property int quotaGb: {
    var n = parseInt(String(setting("quotaGb", 250)), 10)
    if (!isFinite(n) || n < 1) return 250
    return n
  }
  readonly property int refreshIntervalSec: {
    var n = parseInt(String(setting("refreshIntervalSec", 60)), 10)
    if (!isFinite(n)) n = 60
    if (n < 15) n = 15
    if (n > 3600) n = 3600
    return n
  }
  readonly property string helperPath: localPath(Qt.resolvedUrl("scripts/status"))
  readonly property var view: Model.present(status, Date.now())
  readonly property color statusColor: colorFor(view.state)

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.substring(7)
    try { return decodeURIComponent(value) } catch (error) { return value }
  }

  function colorFor(state) {
    if (state === "failed" || state === "missing" || state === "warning") return Color.urgent
    if (state === "running") return Color.accent
    return root.bar ? root.bar.barForeground : Color.foreground
  }

  function refresh() {
    if (statusProcess.running) return
    refreshing = true
    statusProcess.command = ["python3", helperPath, String(quotaGb)]
    statusProcess.running = true
  }

  function applyStatus(raw) {
    status = Model.parseStatus(raw)
    injectPanel()
  }

  function open() {
    refresh()
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("status" in target) target.status = root.status
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  onStatusChanged: injectPanel()
  Component.onCompleted: refresh()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "io.github.adam-lagerhausen.backup-status"

    function refresh(): void { root.broadcast("refresh") }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    labelVisible: false
    hasVisualContent: true
    keepSpace: true
    tooltipText: root.opened ? "" : (root.view.meta || "Backup status")
    foreground: root.statusColor
    horizontalMargin: 7
    fixedWidth: contentRow.implicitWidth + Style.space(14)
    fixedHeight: root.barSize
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton || buttonCode === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }

    Row {
      id: contentRow
      anchors.centerIn: parent
      spacing: Style.space(6)

      Item {
        width: Style.space(14)
        height: Style.space(14)

        BackupIcon {
          id: glyph
          anchors.centerIn: parent
          iconSize: Style.space(14)
          color: button.foreground
          opacity: root.view.state === "running" ? 0.55 : 1

          SequentialAnimation on opacity {
            running: root.view.state === "running"
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700 }
            NumberAnimation { to: 1.0; duration: 700 }
          }
        }

        Rectangle {
          visible: root.barStyle === "pip"
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.rightMargin: -1
          anchors.bottomMargin: -1
          width: Style.space(5)
          height: width
          radius: width / 2
          color: root.view.state === "healthy"
            ? Color.accent
            : root.statusColor
          border.width: 1
          border.color: root.bar ? root.bar.background : Color.background
        }
      }

      Text {
        visible: root.barStyle === "label"
        anchors.verticalCenter: parent.verticalCenter
        text: root.view.label
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Rectangle {
      visible: root.opened
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 1
      width: Style.space(10)
      height: Style.space(2)
      radius: 1
      color: button.foreground
      opacity: 0.85
    }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/workstation-backup/STATUS"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/database-backup/staging/backup.log"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  Process {
    id: statusProcess
    running: false
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatus(text)
    }
    onExited: function() {
      root.refreshing = false
    }
  }

  Timer {
    interval: root.view.state === "running" ? 5000 : root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: false
    onTriggered: root.refresh()
  }
}
