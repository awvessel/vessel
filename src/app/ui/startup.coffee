# Perform startup actions

BrowserWindow = require 'browser-window'
exec          = require('child_process').exec
fs            = require 'fs-plus'
ipc           = require 'ipc'
semver        = require 'semver'
yaml          = require 'js-yaml'

class Startup

  minVer: '1.6.0'
  url: 'https://github-enterprise.colo.lair/gavinr/vessel-manifest.git'

  constructor: ->
    @configDir = "#{fs.getHomeDirectory()}/.vessel"
    @manifestDir = "#{@configDir}/manifest"
    @window = null

  initialize: (callback) ->
    @onReady = callback

    if not @_hasConfigDir()
      @_makeConfigDir()

    # Ensure that Vagrant is 1.6.0 or higher
    @_checkVagrantVersion(callback)

  _checkVagrantVersion: (callback) ->
    command = "vagrant --version"
    exec command, (err, stdout, stderr) =>
      if err
        @_onVagrantCheckError 'I could not find the Vagrant application. ' +
                              'Please ensure that Vagrant is installed and ' +
                              'is in the global PATH.'
      else
        version = stdout.split(' ')[1]
        if semver.gte version, @minVer
          @_onVagrantCheckOk(callback)
        else
          @_onVagrantCheckError 'The Vagrant version I found is not ' +
                                'supported. Version ' + version +
                                ' was found but ' + @minVer +
                                ' or greater is required.'

  _onVagrantCheckError: (message) ->
    @window = new BrowserWindow {
      width: 600
      height: 290
      resizable: false
      title: "Vessel Startup Error"
      show: true
    }
    @window.loadUrl "file://#{__dirname}/../startup/error.html##{message}"
    @window.on 'closed', () =>
      @window = null

  _onVagrantCheckOk: (callback) ->
    # Ensure that there is a global manifest
    if not @_hasManifestDir()
      @_createPromptWindow()
    else
      @_gitPullManifestRepo(callback)

  _hasConfigDir: ->
    fs.existsSync @configDir

  _hasManifestDir: ->
    fs.existsSync @manifestDir

  _makeConfigDir: ->
    fs.mkdir @configDir, '0755'

  _gitCloneManifestRepo: (callback) ->
    command = "git clone #{@url} #{@manifestDir}"
    exec command, (err, stdout, stderr) =>
      console.log stdout
      console.log stderr
      console.log err
      @onReady()
      @onReady = null

  _gitPullManifestRepo: (callback) ->
    command = "cd  #{@manifestDir} && git pull origin master"
    exec command, (err, stdout, stderr) ->
      console.log stdout
      console.log stderr
      console.log err
      callback()

  _createPromptWindow: ->
    ipc.on 'setURL', (event, url) =>
      @url = url
      @window.close()
      @_gitCloneManifestRepo()

    @window = new BrowserWindow {
      width: 600
      height: 330
      resizable: false
      title: "Vessel Setup"
      show: true
    }

    @window.loadUrl "file://#{__dirname}/../startup/index.html"

    @window.on 'closed', () =>
      @window = null

module.exports = Startup
