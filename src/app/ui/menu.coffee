# Implement the Application Menu and its core behaviors

app           = require 'app'
BrowserWindow = require 'browser-window'
Menu          = require 'menu'

newWindow     = require './window'

class AppMenu

  template: [
    {
      label: 'Vessel'
      submenu: [
        {
          label: 'About Vessel',
          selector: 'orderFrontStandardAboutPanel:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Hide Others',
          accelerator: 'Command+Shift+H',
          selector: 'hideOtherApplications:'
        },
        {
          label: 'Show All',
          selector: 'unhideAllApplications:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Quit',
          accelerator: 'Command+Q',
          click: () ->
            app.quit()
        }
      ]
    },
    {
      label: 'File'
      submenu: [
        {
          label: 'Open Environment',
          click: () ->
            newWindow()
        },
        {
          type: 'separator'
        },
        {
          label: 'Build Environment',
          enabled: false
          click: () ->
            newWindow()
        },
        {
          label: 'Start Environment',
          enabled: false
          click: () ->
            newWindow()
        },
      ]
    },
    {
      label: 'Edit'
      submenu: [
        {
          label: 'Undo',
          accelerator: 'Command+Z',
          selector: 'undo:'
        },
        {
          label: 'Redo',
          accelerator: 'Shift+Command+Z',
          selector: 'redo:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Cut',
          accelerator: 'Command+X',
          selector: 'cut:'
        },
        {
          label: 'Copy',
          accelerator: 'Command+C',
          selector: 'copy:'
        },
        {
          label: 'Paste',
          accelerator: 'Command+V',
          selector: 'paste:'
        },
        {
          label: 'Select All',
          accelerator: 'Command+A',
          selector: 'selectAll:'
        }
      ]
    },
    {
      label: 'View',
      submenu: [
        {
          label: 'Toggle DevTools',
          accelerator: 'Alt+Command+I',
          click: () ->
            browserWindow = BrowserWindow.getFocusedWindow()
            browserWindow.toggleDevTools()
            [width, height] = browserWindow.getSize()
            if height > 650
              height -= 310
            else
              height += 310
            browserWindow.setSize(width, height)
        },
      ]
    },
    {
      label: 'Window',
      submenu: [
        {
          label: 'Minimize',
          accelerator: 'Command+M',
          selector: 'performMiniaturize:'
        },
        {
          label: 'Close',
          accelerator: 'Command+W',
          selector: 'performClose:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Bring All to Front',
          selector: 'arrangeInFront:'
        },
      ]
    }
  ]

  constructor: () ->
    menu = Menu.buildFromTemplate @template
    Menu.setApplicationMenu menu

module.exports = AppMenu
