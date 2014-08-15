BrowserWindow = require 'browser-window'
#ipc           = require 'ipc'
moment        = require 'moment'

# Log output to stdout and via IPC messages to the current window
#
class Logger

  _send: (level, message) ->
    sent = false
    window = BrowserWindow.getFocusedWindow()
    if window isnt undefined
      window.webContents.send "log:#{level}", message.trim()
      sent = true
    else
      windows = BrowserWindow.getAllWindows()
      for window in windows
        window.webContents.send "log:#{level}", message.trim()
        sent =true
    sent

  debug: (message) ->
    if not @_send 'debug', message
      console.log ">> [#{moment().format()}:DEBUG] #{message}"

  error: (message) ->
    if not @_send 'error', message
      console.log ">> [#{moment().format()}:ERROR] #{message}"

  info: (message) ->
    if not @_send 'info', message
      console.log ">> [#{moment().format()}:INFO] #{message}"

if not instance?
  instance = new Logger

module.exports = instance
