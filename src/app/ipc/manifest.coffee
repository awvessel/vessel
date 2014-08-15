fs       = require 'fs-plus'
ipc      = require 'ipc'
path     = require 'path'
yaml     = require 'js-yaml'

Listener = require './base'


# Read and manage manifest files, respond to manifest IPC requests
#
class Manifest extends Listener

  events:
    'manifest:load':       'load'
    'manifest:local:save': 'save'

  initialize: ->
    @userManifest = "#{fs.getHomeDirectory()}/.vessel/manifest/manifest.yaml"

  load: (event, localPath, callback) =>
    # Paths to look for the Vessel manifest
    localManifest = path.join localPath, '/.vessel.yaml'

    # Check for Environment/Path/.vessel.yaml
    if fs.existsSync localManifest
      manifest = @_read localManifest
    else
      manifest = @_read @userManifest

    event.sender.send callback, manifest

  save: (event, localPath, values, callback) =>
    localManifest = path.join localPath, '/.vessel.yaml'
    @_write localManifest, values
    event.sender.send callback, true

  _read: (filePath) ->
    value = fs.readFileSync filePath, 'utf8'
    yaml.load value

  _write: (filePath, values) ->
    value = yaml.dump values
    fs.writeFileSync filePath, value, 'utf8'

if not instance?
  instance = new Manifest

module.exports = instance
