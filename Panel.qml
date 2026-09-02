import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Panel {
  id: root

  moduleName: "io.github.tyrichards.sidekick"
  ipcTarget: "io.github.tyrichards.sidekick"
  manageIpc: false

  readonly property string pluginDir: (Quickshell.env("HOME") || "")
    + "/.config/omarchy/plugins/io.github.tyrichards.sidekick"
  readonly property string sidekickCommand: pluginDir + "/bin/sidekick"
  readonly property string preferencesPath: (Quickshell.env("HOME") || "")
    + "/.config/omarchy/sidekick.json"
  readonly property string agentPath: (Quickshell.env("HOME") || "")
    + "/.config/omarchy/defaults/agent"
  readonly property string stripStatePath: (Quickshell.env("HOME") || "")
    + "/.local/state/omarchy/sidekick-strip.json"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property string panelSide: "right"
  property string displayPreference: "tui"
  property string defaultAgent: ""
  property string pendingDefaultAgent: ""
  property bool defaultAgentInitialized: false
  property bool emptyTerminal: false
  property bool webError: false
  property bool desktopError: false
  property bool desktopAppAvailable: false
  property bool displayResetPrompt: false
  property bool preferencesLoaded: false
  property bool cursorActive: false
  property int focusSection: 0
  property int sideCursorIndex: 1
  property int displayCursorIndex: 1
  property int jokeIndex: 0
  property int inheritedMotionDuration: 379
  property var inheritedMotionCurve: [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]
  readonly property real shakeDirection: bar && bar.position === "left" ? 1 : -1
  readonly property var sidekickJokes: [
    "DIVING INTO THE DETAILS",
    "TAKING CARE OF THE REST",
    "BACKING YOU UP",
    "SUITING UP FOR THE FIX",
    "SWOOPING IN TO HELP",
    "SAVING THE DAY AGAIN",
    "KEEPING WATCH FROM HERE",
    "POWERING UP THE PLAN",
    "FLYING INTO THE FIX",
    "PUNCHING THROUGH THE BUG",
    "ODDJOBB-ING THE ODD JOB",
    "HOLY SMOKES, BATMAN!",
    "TASKING THE RANDOM TASK"
  ]
  property var stripState: ({ visible: false, side: "right", width: 0, monitor: "", address: "", paneWidth: 0 })

  readonly property bool leader: {
    var screens = Quickshell.screens || []
    return screens.length === 0 || String(Screen.name) === String(screens[0].name)
  }
  readonly property var anchorWindow: button ? button.QsWindow.window : null
  readonly property string screenName: anchorWindow && anchorWindow.screen
    ? String(anchorWindow.screen.name || "") : ""
  readonly property bool paddingCoverVisible: stripState.coverVisible === undefined
    ? stripState.visible === true : stripState.coverVisible === true
  readonly property bool paddingMotionOpen: stripState.paddingOpen === undefined
    ? stripState.visible === true : stripState.paddingOpen === true
  readonly property real paddingMotionDistance: Math.max(1, Number(stripState.paneWidth || 466))
  property real paddingSlideOffset: paddingMotionOpen ? 0 : -paddingMotionDistance
  readonly property real innerSideCoverWidth: Math.max(0, Math.min(
    Math.round(Number(bar ? bar.barSize : 0)),
    paddingSlideOffset + paddingMotionDistance))
  Behavior on paddingSlideOffset {
    NumberAnimation {
      duration: root.inheritedMotionDuration
      easing.type: Easing.BezierSpline
      easing.bezierCurve: root.inheritedMotionCurve
    }
  }
  readonly property bool showInnerSidePadding: paddingCoverVisible
    && String(stripState.monitor || "") === screenName
    && bar && (bar.position === "left" || bar.position === "right")
    && String(stripState.side || "") === bar.position
  readonly property bool showInnerHorizontalPadding: paddingCoverVisible
    && String(stripState.monitor || "") === screenName
    && bar && bar.barHidden !== true
    && (bar.position === "top" || bar.position === "bottom")
    && !(bar.position === "top" && displayPreference === "web")

  function loadMotionProfile(raw) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "")) } catch (error) { parsed = null }
    if (!parsed || !parsed[0]) return
    var animations = parsed[0]
    var curves = parsed[1] || []
    function named(values, name) {
      for (var i = 0; i < values.length; i++) if (values[i].name === name) return values[i]
      return null
    }
    var move = named(animations, "windowsMove") || {}
    var windows = named(animations, "windows") || {}
    var global = named(animations, "global") || {}
    var effective = move.overridden ? move : windows.overridden ? windows : global
    inheritedMotionDuration = effective.enabled === false
      ? 1 : Math.max(1, Math.round(Number(effective.speed || 0) * 100))
    var curve = named(curves, String(effective.bezier || "default"))
    inheritedMotionCurve = curve
      ? [curve.X0, curve.Y0, curve.X1, curve.Y1, 1.0, 1.0]
      : [0.0, 0.0, 1.0, 1.0, 1.0, 1.0]
  }

  function loadStripState(raw) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "")) } catch (error) { parsed = null }
    stripState = parsed && typeof parsed === "object"
      ? parsed : ({ visible: false, side: "right", width: 0, monitor: "", address: "", paneWidth: 0 })
  }

  function sidekickToplevelByAddress(address) {
    var wanted = String(address || "").replace(/^0x/, "")
    var values = Hyprland.toplevels ? Hyprland.toplevels.values : []
    for (var i = 0; i < values.length; i++)
      if (String(values[i].address || "").replace(/^0x/, "") === wanted) return values[i]
    return null
  }

  readonly property var liveSidekickToplevel: sidekickToplevelByAddress(stripState.address)

  function syncBarGeometryNow() {
    if (!bar || stripState.visible !== true) return false
    var address = String(stripState.address || "")
    var toplevel = sidekickToplevelByAddress(address)
    if (!toplevel || !toplevel.monitor) return false
    var monitor = toplevel.monitor
    var scale = Number(monitor.scale || 1)
    var monitorX = Number(monitor.x || 0)
    var monitorY = Number(monitor.y || 0)
    var monitorWidth = Math.floor(Number(monitor.width || 0) / scale)
    var monitorHeight = Math.floor(Number(monitor.height || 0) / scale)
    var basePaneWidth = Math.floor(Math.min(monitorWidth / 3, 1400 / 3))
    var side = String(stripState.side || panelSide)
    var hidden = bar.barHidden === true
    var sameVerticalSide = !hidden && (bar.position === "left" || bar.position === "right")
      && side === bar.position
    var stripWidth = sameVerticalSide ? Math.round(Number(bar.barSize || 0)) : 0
    var paneWidth = basePaneWidth
    if (Number(stripState.width || 0) !== stripWidth) {
      var nextState = {}
      for (var key in stripState) nextState[key] = stripState[key]
      nextState.width = stripWidth
      stripState = nextState
    }

    var window = "address:" + address
    var data = toplevel.lastIpcObject || {}
    var at = data.at || []
    var size = data.size || []
    // Brave Web Apps and the native ChatGPT client both enforce a 480-unit
    // minimum. Accept that settled width while clipping the extra 14 units
    // beyond the selected edge, instead of repeatedly resizing and bouncing.
    var clientClass = String(data.class || data.initialClass || "").toLowerCase()
    var clientTitle = String(toplevel.title || data.title || "")
    var constrainedClient = clientTitle === "ChatGPT"
      || clientClass.indexOf("brave-") === 0
      || clientClass.indexOf("chromium") >= 0
      || clientClass.indexOf("google-chrome") >= 0
    var expectedWindowWidth = constrainedClient ? Math.max(paneWidth, 480) : paneWidth
    var overflowWidth = expectedWindowWidth - paneWidth
    var targetX = side === "left"
      ? monitorX - overflowWidth
      : monitorX + monitorWidth - paneWidth
    var targetY = monitorY - 4
    var targetBottom = monitorY + monitorHeight + 4
    var targetHeight = targetBottom - targetY

    var geometryWrong = at.length < 2 || size.length < 2
      || Math.round(Number(at[0])) !== targetX || Math.round(Number(at[1])) !== targetY
      || Math.round(Number(size[0])) !== expectedWindowWidth || Math.round(Number(size[1])) !== targetHeight
    var activeWorkspaceId = monitor.activeWorkspace ? Number(monitor.activeWorkspace.id) : 0
    var windowWorkspace = data.workspace || {}
    var workspaceWrong = activeWorkspaceId > 0 && Number(windowWorkspace.id || 0) !== activeWorkspaceId
    var modeWrong = data.floating === false || data.pinned === false || Number(data.fullscreen || 0) !== 0 || workspaceWrong
    if (!geometryWrong && !modeWrong) return true

    Hyprland.dispatch("hl.dsp.window.set_prop({ window = \"" + window
      + "\", prop = \"no_anim\", value = \"1\" })")
    if (Number(data.fullscreen || 0) !== 0)
      Hyprland.dispatch("hl.dsp.window.fullscreen_state({ window = \"" + window + "\", internal = 0, client = 0 })")
    if (workspaceWrong)
      Hyprland.dispatch("hl.dsp.window.move({ window = \"" + window + "\", workspace = \"" + activeWorkspaceId + "\", follow = false })")
    if (data.floating === false)
      Hyprland.dispatch("hl.dsp.window.float({ window = \"" + window + "\", action = \"enable\" })")
    if (data.pinned === false)
      Hyprland.dispatch("hl.dsp.window.pin({ window = \"" + window + "\", action = \"enable\" })")
    Hyprland.dispatch("hl.dsp.window.set_prop({ window = \"" + window
      + "\", prop = \"min_size\", value = \"" + expectedWindowWidth + " " + targetHeight + "\" })")
    Hyprland.dispatch("hl.dsp.window.set_prop({ window = \"" + window
      + "\", prop = \"max_size\", value = \"" + expectedWindowWidth + " " + targetHeight + "\" })")
    Hyprland.dispatch("hl.dsp.window.resize({ window = \"" + window
      + "\", x = " + expectedWindowWidth + ", y = " + targetHeight + " })")
    Hyprland.dispatch("hl.dsp.window.move({ window = \"" + window
      + "\", x = " + targetX + ", y = " + targetY + " })")
    Qt.callLater(function() {
      Hyprland.dispatch("hl.dsp.window.set_prop({ window = \"" + window
        + "\", prop = \"no_anim\", value = \"unset\" })")
    })
    return true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Override the base panel lifecycle so every open path (bar click, IPC,
  // keyboard summon) installs the cursor guard, and every dismissal path
  // restores it—including outside-click dismissal from KeyboardPanel.
  function open() {
    Quickshell.execDetached([sidekickCommand, "cursor-guard", "on"])
    controller.show()
  }
  function close() {
    Quickshell.execDetached([sidekickCommand, "cursor-guard", "off"])
    controller.hide()
  }
  function toggle() { opened ? close() : open() }

  function normalizeSide(value) {
    return String(value || "").toLowerCase() === "left" ? "left" : "right"
  }

  function normalizeDisplay(value) {
    var normalized = String(value || "").toLowerCase()
    return normalized === "web" || normalized === "desktop" ? normalized : "tui"
  }

  function displayIndex(value) {
    var normalized = normalizeDisplay(value)
    return normalized === "tui" ? 0 : normalized === "web" ? 1 : 2
  }

  function displayAt(index) {
    return index === 0 ? "tui" : index === 1 ? "web" : "desktop"
  }

  function agentHasWebApp(value) {
    switch (String(value || "")) {
    case "chatgpt":
    case "claude":
    case "codex":
    case "grok":
    case "gemini":
    case "copilot": return true
    default: return false
    }
  }

  function agentHasDesktopApp(value) {
    var agent = String(value || "")
    return agent === "codex" || agent === "chatgpt"
  }

  function rejectWebApp() {
    desktopError = false
    webError = true
    rejectShake.restart()
  }

  function rejectDesktopApp() {
    webError = false
    desktopError = true
    rejectShake.restart()
  }

  function agentName(value) {
    switch (String(value || "")) {
    case "pi": return "Pi"
    case "omp": return "Oh My Pi"
    case "opencode": return "OpenCode"
    case "claude": return "Claude Code"
    case "codex": return "Codex"
    case "grok": return "Grok"
    case "gemini": return "Gemini"
    case "copilot": return "GitHub Copilot"
    case "crush": return "Crush"
    case "chatgpt": return "ChatGPT"
    default: return value === "" ? "Not set" : value
    }
  }

  function observeDefaultAgent(raw) {
    var next = String(raw || "").trim()
    if (!defaultAgentInitialized) {
      defaultAgent = next
      pendingDefaultAgent = next
      defaultAgentInitialized = true
      return
    }
    pendingDefaultAgent = next
    defaultAgentChangeTimer.restart()
  }

  function commitDefaultAgentChange() {
    var next = String(pendingDefaultAgent || "")
    if (next === defaultAgent) return
    // Default changes update the modal and future fallback immediately, but
    // never replace a live or persisted Sidekick terminal session.
    defaultAgent = next
    webError = false
    desktopError = false
  }

  function loadPreferences(raw) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "")) } catch (error) { parsed = null }
    if (parsed && typeof parsed === "object") {
      panelSide = normalizeSide(parsed.side)
      displayPreference = normalizeDisplay(parsed.display)
      emptyTerminal = parsed.emptyTerminal === true
    }
    preferencesLoaded = true
    if (!parsed) flushPreferences()
    if (leader) setupIntegrations()
  }

  function flushPreferences() {
    if (!preferencesLoaded) return
    preferencesFile.setText(JSON.stringify({
      version: 1,
      side: panelSide,
      display: displayPreference,
      emptyTerminal: emptyTerminal
    }, null, 2) + "\n")
  }

  function setupIntegrations() {
    Quickshell.execDetached([sidekickCommand, "setup", panelSide])
  }

  function syncGeometryDetached() {
    Quickshell.execDetached([
      sidekickCommand,
      "sync-geometry",
      panelSide,
      bar && bar.barHidden ? "hidden" : "shown"
    ])
  }

  function setPanelSide(value) {
    var next = normalizeSide(value)
    var previous = panelSide
    panelSide = next
    sideCursorIndex = next === "left" ? 0 : 1
    webError = false
    desktopError = false
    flushPreferences()
    Quickshell.execDetached([
      sidekickCommand,
      "select-side",
      previous,
      next,
      displayPreference,
      defaultAgent,
      emptyTerminal ? "true" : "false"
    ])
  }

  function setDisplayPreference(value) {
    var next = normalizeDisplay(value)
    if (next === "web" && !emptyTerminal && !agentHasWebApp(defaultAgent)) {
      rejectWebApp()
      return
    }
    if (next === "desktop" && !emptyTerminal
        && (!agentHasDesktopApp(defaultAgent) || !desktopAppAvailable)) {
      rejectDesktopApp()
      return
    }
    webError = false
    desktopError = false
    displayPreference = next
    displayCursorIndex = displayIndex(next)
    flushPreferences()
    displayResetPrompt = true
  }

  function confirmDisplayReset(shouldReset) {
    displayResetPrompt = false
    if (!shouldReset) return
    Quickshell.execDetached([
      sidekickCommand,
      "select-mode",
      panelSide,
      displayPreference,
      defaultAgent,
      emptyTerminal ? "true" : "false"
    ])
  }

  function setEmptyTerminal(value) {
    emptyTerminal = value === true
    webError = false
    desktopError = false
    displayResetPrompt = false
    flushPreferences()
    Quickshell.execDetached([
      sidekickCommand,
      "select-mode",
      panelSide,
      displayPreference,
      defaultAgent,
      emptyTerminal ? "true" : "false"
    ])
  }

  function openAgentMenu() {
    close()
    Quickshell.execDetached(["omarchy-menu", "summon", "setup.default.agent"])
  }

  function toggleAgentPanel() {
    close()
    Quickshell.execDetached([
      sidekickCommand,
      "toggle",
      panelSide,
      displayPreference,
      defaultAgent,
      emptyTerminal ? "true" : "false"
    ])
  }

  function closeAgentPanel() {
    Quickshell.execDetached([sidekickCommand, "close"])
  }

  function resetSidekick() {
    webError = false
    desktopError = false
    displayResetPrompt = false
    close()
    Quickshell.execDetached([
      sidekickCommand,
      "select-mode",
      panelSide,
      displayPreference,
      defaultAgent,
      emptyTerminal ? "true" : "false"
    ])
  }

  function collapseAgentPanel() {
    Quickshell.execDetached([sidekickCommand, "collapse", panelSide])
  }

  function moveCursor(delta) {
    cursorActive = true
    focusSection = Math.max(0, Math.min(4, focusSection + delta))
    if (focusSection === 0) sideCursorIndex = panelSide === "left" ? 0 : 1
    if (focusSection === 2) displayCursorIndex = displayIndex(displayPreference)
  }

  function adjustCurrent(delta) {
    cursorActive = true
    if (focusSection === 0) {
      sideCursorIndex = Math.max(0, Math.min(1, sideCursorIndex + delta))
      setPanelSide(sideCursorIndex === 0 ? "left" : "right")
    } else if (focusSection === 2) {
      displayCursorIndex = Math.max(0, Math.min(2, displayCursorIndex + delta))
      setDisplayPreference(displayAt(displayCursorIndex))
    }
  }

  function activateCurrent() {
    cursorActive = true
    if (focusSection === 0) setPanelSide(sideCursorIndex === 0 ? "left" : "right")
    else if (focusSection === 1 && !emptyTerminal) openAgentMenu()
    else if (focusSection === 2) setDisplayPreference(displayAt(displayCursorIndex))
    else if (focusSection === 3) setEmptyTerminal(!emptyTerminal)
    else if (focusSection === 4) resetSidekick()
  }

  Component.onCompleted: {
    Quickshell.execDetached(["mkdir", "-p", (Quickshell.env("HOME") || "") + "/.config/omarchy"])
    Qt.callLater(function() {
      preferencesFile.reload()
      agentFile.reload()
      stripStateFile.reload()
      motionProfileProcess.running = true
      desktopAppProbe.running = true
    })
  }

  onOpenedChanged: {
    if (opened) {
      jokeIndex = (jokeIndex + 1) % sidekickJokes.length
      cursorActive = false
      focusSection = 0
      sideCursorIndex = panelSide === "left" ? 0 : 1
      displayCursorIndex = displayIndex(displayPreference)
      agentFile.reload()
    }
  }

  Component.onDestruction: if (opened)
    Quickshell.execDetached([sidekickCommand, "cursor-guard", "off"])

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "configreloaded") {
        if (root.leader) root.setupIntegrations()
        if (!motionProfileProcess.running) motionProfileProcess.running = true
      } else if (["monitoradded", "monitoraddedv2", "monitorremoved",
                  "monitorremovedv2"].indexOf(event.name) >= 0) {
        if (root.leader) Quickshell.execDetached([
          root.sidekickCommand, "monitor-change", root.panelSide
        ])
      } else if (root.stripState.visible !== true
          && ["workspace", "workspacev2", "focusedmon"].indexOf(event.name) >= 0) {
        // Restage the loaded storage-workspace client for the newly focused
        // monitor before its next reveal.
        root.syncGeometryDetached()
      }
    }
  }

  Connections {
    target: root.bar
    function onBarHiddenChanged() {
      if (root.stripState.visible === true) {
        if (!root.syncBarGeometryNow()) geometrySyncTimer.restart()
      } else {
        root.syncGeometryDetached()
      }
    }
    function onPositionChanged() {
      if (root.stripState.visible === true) geometrySyncTimer.restart()
      else root.syncGeometryDetached()
    }
  }

  Connections {
    target: root.liveSidekickToplevel
    function onLastIpcObjectChanged() { root.syncBarGeometryNow() }
    function onWorkspaceChanged() {
      if (root.stripState.visible === true) root.syncBarGeometryNow()
      else root.syncGeometryDetached()
    }
  }

  Timer {
    interval: 120
    repeat: true
    running: root.stripState.visible === true
    onTriggered: {
      Hyprland.refreshToplevels()
      Qt.callLater(function() { root.syncBarGeometryNow() })
    }
  }

  Timer {
    id: geometrySyncTimer
    interval: 30
    repeat: false
    onTriggered: Quickshell.execDetached([
      root.sidekickCommand,
      "sync-geometry",
      root.panelSide,
      root.bar && root.bar.barHidden ? "hidden" : "shown"
    ])
  }

  Process {
    id: motionProfileProcess
    command: ["hyprctl", "animations", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.loadMotionProfile(text)
    }
  }

  Process {
    id: desktopAppProbe
    command: ["sh", "-lc", "command -v chatgpt >/dev/null"]
    onExited: function(exitCode) { root.desktopAppAvailable = exitCode === 0 }
  }

  Timer {
    id: defaultAgentChangeTimer
    interval: 60
    repeat: false
    onTriggered: root.commitDefaultAgentChange()
  }

  Timer {
    interval: 9000
    repeat: true
    running: true
    onTriggered: root.jokeIndex = (root.jokeIndex + 1) % root.sidekickJokes.length
  }

  SequentialAnimation {
    id: rejectShake
    running: false
    // The card is clamped against the screen edge, so pulse its invisible
    // anchor inward and back. KeyboardPanel follows the anchor, moving the
    // complete modal surface—background and border included.
    PropertyAnimation { target: modalAnchorOffset; property: "x"; to: 5 * root.shakeDirection; duration: 34; easing.type: Easing.OutQuad }
    PropertyAnimation { target: modalAnchorOffset; property: "x"; to: 0; duration: 36; easing.type: Easing.InOutQuad }
    PropertyAnimation { target: modalAnchorOffset; property: "x"; to: 3 * root.shakeDirection; duration: 28; easing.type: Easing.OutQuad }
    PropertyAnimation { target: modalAnchorOffset; property: "x"; to: 0; duration: 32; easing.type: Easing.InQuad }
  }

  FileView {
    id: preferencesFile
    path: root.preferencesPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadPreferences(text())
    onLoadFailed: root.loadPreferences("")
    onFileChanged: reload()
  }

  FileView {
    id: agentFile
    path: root.agentPath
    watchChanges: true
    printErrors: false
    onLoaded: root.observeDefaultAgent(text())
    onLoadFailed: root.observeDefaultAgent("")
    onFileChanged: reload()
  }

  FileView {
    id: stripStateFile
    path: root.stripStatePath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadStripState(text())
    onLoadFailed: root.loadStripState("")
    onFileChanged: reload()
  }

  PanelWindow {
    screen: root.anchorWindow ? root.anchorWindow.screen : null
    visible: true
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.max(1, root.innerSideCoverWidth)
    color: root.showInnerSidePadding && root.innerSideCoverWidth > 0
      && String(root.stripState.side || "") === "left"
      ? Color.background : "transparent"
    mask: Region {}
    margins { left: 0 }
    anchors { top: true; bottom: true; left: true }
    WlrLayershell.namespace: "sidekick-inner-padding-left"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  }

  PanelWindow {
    screen: root.anchorWindow ? root.anchorWindow.screen : null
    visible: true
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.max(1, root.innerSideCoverWidth)
    color: root.showInnerSidePadding && root.innerSideCoverWidth > 0
      && String(root.stripState.side || "") === "right"
      ? Color.background : "transparent"
    mask: Region {}
    margins { right: 0 }
    anchors { top: true; bottom: true; right: true }
    WlrLayershell.namespace: "sidekick-inner-padding-right"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  }

  PanelWindow {
    screen: root.anchorWindow ? root.anchorWindow.screen : null
    visible: true
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.max(1, Number(root.stripState.paneWidth || 0))
    implicitHeight: Math.max(1, Math.round(Number(root.bar ? root.bar.barSize : 0)))
    color: root.showInnerHorizontalPadding && String(root.stripState.side || "") === "left"
      ? Color.background : "transparent"
    mask: Region {}
    margins { left: root.paddingSlideOffset }
    anchors {
      top: !(root.showInnerHorizontalPadding && root.bar && root.bar.position === "bottom")
      bottom: root.showInnerHorizontalPadding && root.bar && root.bar.position === "bottom"
      left: true
    }
    WlrLayershell.namespace: "sidekick-horizontal-padding-left"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  }

  PanelWindow {
    screen: root.anchorWindow ? root.anchorWindow.screen : null
    visible: true
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.max(1, Number(root.stripState.paneWidth || 0))
    implicitHeight: Math.max(1, Math.round(Number(root.bar ? root.bar.barSize : 0)))
    color: root.showInnerHorizontalPadding && String(root.stripState.side || "") === "right"
      ? Color.background : "transparent"
    mask: Region {}
    margins { right: root.paddingSlideOffset }
    anchors {
      top: !(root.showInnerHorizontalPadding && root.bar && root.bar.position === "bottom")
      bottom: root.showInnerHorizontalPadding && root.bar && root.bar.position === "bottom"
      right: true
    }
    WlrLayershell.namespace: "sidekick-horizontal-padding-right"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  }

  IpcHandler {
    target: root.ipcTarget

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function openSettings(): string { root.open(); return "ok" }
    function togglePanel(): string { root.toggleAgentPanel(); return "ok" }
    function collapsePanel(): string { root.collapseAgentPanel(); return "ok" }
    function closePanel(): string { root.closeAgentPanel(); return "ok" }
    function focusAway(direction: string): string {
      Quickshell.execDetached([root.sidekickCommand, "focus-away", direction])
      return "ok"
    }
    function focusSidekickAtEdge(direction: string, previousAddress: string): string {
      Quickshell.execDetached([
        root.sidekickCommand,
        "focus-at-edge",
        direction,
        previousAddress
      ])
      return "ok"
    }
    function setSideFromBinding(side: string): string {
      var next = root.normalizeSide(side)
      if (next !== root.panelSide) root.setPanelSide(next)
      return "ok"
    }
    function rejectWebApp(): string { root.open(); root.rejectWebApp(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.panelSide === "left" ? "" : ""
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.toggleAgentPanel()
      else root.toggle()
    }
  }

  Item {
    id: panelAnchor
    anchors.fill: button
    transform: Translate { id: modalAnchorOffset; x: 0 }
  }

  KeyboardPanel {
    id: panel
    anchorItem: panelAnchor
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(settingsColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.moveCursor(dy)
        else if (dx !== 0) root.adjustCurrent(dx)
      }
      onActivateRequested: root.activateCurrent()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: settingsColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        // Audio-panel header geometry: display icon, title/tagline, trailing
        // status, then a full-width separator.
        Item {
          width: parent.width
          implicitHeight: Math.max(headerIcon.implicitHeight, headerLabels.implicitHeight, resetHeaderAction.implicitHeight)

          Text {
            id: headerIcon
            text: root.panelSide === "left" ? "" : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Item {
            id: resetHeaderAction
            readonly property bool hot: resetHeaderMouse.containsMouse
              || (root.cursorActive && root.focusSection === 4)
            implicitWidth: resetHeaderRow.implicitWidth + Style.space(10)
            implicitHeight: resetHeaderRow.implicitHeight + Style.space(4)
            width: implicitWidth
            height: implicitHeight
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Row {
              id: resetHeaderRow
              anchors.centerIn: parent
              spacing: Style.spacing.controlGap

              Text {
                text: "RESET"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: ""
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle * 1.5
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              id: resetHeaderMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onContainsMouseChanged: if (containsMouse) {
                root.cursorActive = true
                root.focusSection = 4
              }
              onClicked: root.resetSidekick()
            }
          }

          Column {
            id: headerLabels
            anchors.left: headerIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: resetHeaderAction.left
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              width: parent.width
              text: "Sidekick"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: root.sidekickJokes[root.jokeIndex]
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
            }
          }
        }

        PanelSeparator {
          foreground: root.foreground
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "SIDE PANEL"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Row {
            width: parent.width
            spacing: Style.spacing.md

            Button {
              width: (parent.width - parent.spacing) / 2
              text: "Left"
              iconText: ""
              selected: root.panelSide === "left"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.spacing.controlPaddingY
              hasCursor: root.cursorActive && root.focusSection === 0 && root.sideCursorIndex === 0
              onHovered: function(on) {
                if (on) {
                  root.cursorActive = true
                  root.focusSection = 0
                  root.sideCursorIndex = 0
                }
              }
              onClicked: root.setPanelSide("left")
            }

            Button {
              width: (parent.width - parent.spacing) / 2
              text: "Right"
              iconText: ""
              selected: root.panelSide === "right"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.spacing.controlPaddingY
              hasCursor: root.cursorActive && root.focusSection === 0 && root.sideCursorIndex === 1
              onHovered: function(on) {
                if (on) {
                  root.cursorActive = true
                  root.focusSection = 0
                  root.sideCursorIndex = 1
                }
              }
              onClicked: root.setPanelSide("right")
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "DEFAULT AGENT · " + (root.defaultAgent === ""
              ? "NOT SET" : root.agentName(root.defaultAgent).toUpperCase())
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Button {
            width: parent.width
            text: root.defaultAgent === "" ? "Set Default Agent" : "Reset Default Agent"
            iconText: "󱚣"
            bordered: true
            enabled: !root.emptyTerminal
            opacity: root.emptyTerminal ? 0.35 : 1.0
            foreground: root.foreground
            fontFamily: root.fontFamily
            hasCursor: root.cursorActive && root.focusSection === 1
            onHovered: function(on) {
              if (on && !root.emptyTerminal) {
                root.cursorActive = true
                root.focusSection = 1
              }
            }
            onClicked: root.openAgentMenu()
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(8)
          opacity: root.emptyTerminal ? 0.35 : 1.0

          PanelSectionHeader {
            text: "DISPLAY PREFERENCE"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Row {
            width: parent.width
            spacing: Style.spacing.md

            Button {
              width: (parent.width - parent.spacing * 2) / 3
              text: "Terminal"
              iconText: ""
              selected: root.displayPreference === "tui"
              bordered: true
              enabled: !root.emptyTerminal
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.spacing.controlPaddingY
              hasCursor: !root.emptyTerminal && root.cursorActive && root.focusSection === 2 && root.displayCursorIndex === 0
              onHovered: function(on) {
                if (on && !root.emptyTerminal) {
                  root.cursorActive = true
                  root.focusSection = 2
                  root.displayCursorIndex = 0
                }
              }
              onClicked: root.setDisplayPreference("tui")
            }

            Button {
              width: (parent.width - parent.spacing * 2) / 3
              text: "Web App"
              iconText: ""
              selected: root.displayPreference === "web"
              bordered: true
              enabled: !root.emptyTerminal
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.spacing.controlPaddingY
              hasCursor: !root.emptyTerminal && root.cursorActive && root.focusSection === 2 && root.displayCursorIndex === 1
              onHovered: function(on) {
                if (on && !root.emptyTerminal) {
                  root.cursorActive = true
                  root.focusSection = 2
                  root.displayCursorIndex = 1
                }
              }
              onClicked: root.setDisplayPreference("web")
            }

            Button {
              width: (parent.width - parent.spacing * 2) / 3
              text: "Desktop"
              iconText: "󰍹"
              selected: root.displayPreference === "desktop"
              bordered: true
              enabled: !root.emptyTerminal
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.spacing.controlPaddingY
              hasCursor: !root.emptyTerminal && root.cursorActive && root.focusSection === 2 && root.displayCursorIndex === 2
              onHovered: function(on) {
                if (on && !root.emptyTerminal) {
                  root.cursorActive = true
                  root.focusSection = 2
                  root.displayCursorIndex = 2
                }
              }
              onClicked: root.setDisplayPreference("desktop")
            }
          }

          Text {
            visible: root.webError || root.desktopError
            width: parent.width
            text: root.desktopError
              ? (root.desktopAppAvailable
                ? "Desktop App requires Codex or ChatGPT."
                : "Install the ChatGPT Desktop App to use this mode.")
              : "Your default agent does NOT have a web app."
            color: root.bar ? root.bar.urgent : Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }

          Column {
            visible: root.displayResetPrompt && !root.emptyTerminal
            width: parent.width
            spacing: Style.space(6)

            Text {
              width: parent.width
              text: "Reset current Sidekick panel?"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
            }

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(6)

              Button {
                text: "Yes"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                horizontalPadding: Style.space(12)
                verticalPadding: Style.space(3)
                onClicked: root.confirmDisplayReset(true)
              }

              Button {
                text: "No"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                horizontalPadding: Style.space(12)
                verticalPadding: Style.space(3)
                onClicked: root.confirmDisplayReset(false)
              }
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          ToggleSwitch {
            id: emptyTerminalSwitch
            checked: root.emptyTerminal
            hasCursor: root.cursorActive && root.focusSection === 3
            foreground: root.foreground
            anchors.verticalCenter: parent.verticalCenter
            onHovered: function(on) {
              if (on) {
                root.cursorActive = true
                root.focusSection = 3
              }
            }
            onToggled: root.setEmptyTerminal(!root.emptyTerminal)
          }

          Text {
            id: emptyTerminalLabel
            text: "USE EMPTY TERMINAL"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onContainsMouseChanged: if (containsMouse) {
                root.cursorActive = true
                root.focusSection = 3
              }
              onClicked: root.setEmptyTerminal(!root.emptyTerminal)
            }
          }

          Item {
            width: Math.max(0, parent.width - emptyTerminalSwitch.width
              - emptyTerminalLabel.width - footerShortcutHint.width - parent.spacing * 3)
            height: 1
          }

          Text {
            id: footerShortcutHint
            text: "SUPER + \\"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
