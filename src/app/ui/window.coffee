# Window Management

BrowserWindow = require 'browser-window'
crypto        = require 'crypto'
dialog        = require 'dialog'
fs            = require 'fs-plus'
ipc           = require 'ipc'

# Handle for a stack of windows
_windows = {}

# Arguments for the new environment dialoag
newWindowDialogArgs =
  title: 'Environment Directory'
  defaultPath: fs.getHomeDirectory()
  properties: ['openDirectory', 'createDirectory']

# New environment window
#
# Prompts the user for a path to the environment, then checks to make sure
# that the path does not already exist in the stack of windows. If it does,
# just focus that window. Otherwise, create a new AppWindow instance and
# add it to the stack.
newWindow = ->
  dialog.showOpenDialog newWindowDialogArgs, (path) ->
    if path?.length > 0
      if path not of _windows
        _windows[path] = new AppWindow path[0]
      else
        _windows[path].browser.focus()

# Application Window
#
# Responsible for creating the UI window, objects for reading the manifest
# file, configuration and responding to window related IPC events.
#
# Windows have an ID value that is the sha1 hash of the path. This value is
# passed around in ipc requests to ensure that ipc listeners only respond to
# events that are for them.
class AppWindow

  # Default window creation arguments
  args:
    center: false
    height: 647
    resizable: false
    show: false
    width: 1070

  constructor: (@path) ->
    # Create an ID for the window
    id = @_pathHash()
    appPath = fs.realpathSync "#{__dirname}/.."
    @args.icon = "#{appPath}/images/icon@2x.png"

    # Create a new BrowserWindow and load the  src/browser application
    @browser = new BrowserWindow @args
    ePath = encodeURIComponent(@path)
    url = "file://#{appPath}/renderer/index.html?id=#{id}&path=#{ePath}"
    @browser.loadUrl url

    # When the browser window closes, destroy references to itself
    @browser.on 'closed', (event) =>
      _windows[@path] = null
      @browser = null

    # Listen for configuration IPC requests
    ipc.on "window:show:#{id}", (event) =>
      @browser.show()
      event.returnValue = true

  # Create a hash for identifying the window
  #
  # Returns a string
  _pathHash: ->
    sha = crypto.createHash 'sha1'
    sha.update @path
    sha.digest 'hex'

module.exports = newWindow
