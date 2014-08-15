# Main application entry point

app           = require 'app'
crashReporter = require 'crash-reporter'
ipc           = require 'ipc'

Menu          = require './ui/menu'
newWindow     = require './ui/window'
Startup       = require './ui/startup'
TrayIcon      = require './ui/tray-icon'

Config        = require './ipc/config'
Docker        = require './ipc/docker'
Git           = require './ipc/git'
Highlighter   = require './ipc/highlighter'
Manifest      = require './ipc/manifest'
Vagrant       = require './ipc/vagrant'

# Main Application
#
# Responsible for the management of the crash-reporter, window agnostic IPC
# objects, and the app itself.
class Application

  name: 'Vessel'
  company: 'AWeber Communications'
  crashURL: 'https://your-domain.com/url-to-submit'

  constructor: ->

    # Start the Crash Reporter
    #crashReporter.start {
    #  autoSubmit: true
    #  productName: @name
    #  companyName: @company
    #  crashURL: @crashURL
    #}

    # The startup object will ensure everything is needed to start the app
    startup = new Startup

    # When the app is ready, setup the main window
    app.on 'ready', () ->

      # Create the application menu
      @menu = new Menu

      # Create the tray icon
      @tray = new TrayIcon

      # Perform the startup initialization and wait for a callback response
      startup.initialize () ->

        # Open a new environment window
        newWindow()

    ipc.on 'app:badge:get', (event) ->
      event.returnValue = app.dock.getBadge()

    ipc.on 'app:badge:set', (event, value) ->
      app.dock.setBadge value
      event.returnValue = true

    ipc.on 'app:bounce', (event) ->
      event.returnValue = app.dock.bounce()

    ipc.on 'app:bounce:cancel', (event, id) ->
      app.dock.cancelBounce id
      event.returnValue = true

# Create the new application
new Application()
