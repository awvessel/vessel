# Provide an interface for creating and reading environment config files

_         = require 'underscore'
exec      = require('child_process').exec
spawn     = require('child_process').spawn
fs        = require 'fs-plus'
restler   = require 'restler'
sudofy    = require 'sudofy'
tempWrite = require 'temp-write'

Listener  = require './base'
Logger    = require '../utils/logger'
SSH       = require '../utils/ssh'


class Config extends Listener

  events:
    'cloudconfig:generate': 'generateCloudConfig'
    'directory:ensure':     'ensureDirectory'
    'etcd:url:fetch':       'fetchEtcdTokenURL'
    'username:fetch':       'fetchUsername'
    'password:validate':    'validatePassword'
    'vagrantfile:generate': 'generateVagrantfile'

  ensureDirectory: (event, path, callback) ->
    if fs.existsSync path
      stats = fs.statSync path
      event.sender.send callback, stats.isDirectory()
    else
      fs.mkdir path, '0755'
      event.sender.send callback, true

  fetchEtcdTokenURL: (event, callback) ->
    request = restler.get 'https://discovery.etcd.io/new'
    , rejectUnauthorized=false
    request.on 'complete', (data, response) ->
      Logger.debug "[config] Got etcd discovery URL of #{data}"
      if response.statusCode == 200
        event.sender.send callback, data
      else
        event.sender.send callback, null

  fetchUsername: (event, callback) ->
    event.sender.send callback, process.env.USER

  generateCloudConfig: (event, path, url, preview, callback) ->
    templatePath = fs.realpathSync "#{__dirname}/../templates/cloud-config.yml"
    template = fs.readFileSync templatePath, 'utf8'
    renderer = _.template template
    try
      value = renderer url: url
    catch err
      value = "Render error: #{err}"
    if preview is true
      event.sender.send callback, value
    else
      fs.writeFile "#{path}/cloud-config.yml", value, 'utf8', (err) ->
        event.sender.send callback, (if err? then false else true)

  generateVagrantfile: (event, values, path, preview, callback) ->
    templatePath = fs.realpathSync "#{__dirname}/../templates/Vagrantfile"
    template = fs.readFileSync templatePath, 'utf8'
    renderer = _.template(template)
    if preview is true
      try
        value = renderer(values)
      catch err
        value = "Render error: #{err}"
      event.sender.send callback, value
    else
      fs.writeFile "#{path}/Vagrantfile", renderer(values), 'utf8', (err) ->
        event.sender.send callback, if err? then false else true

  validatePassword: (event, value, callback) ->
    command = sudofy.command 'true', {
      password: value
    }
    exec command, (err, stdout, stderr) ->
      Logger.info "[config validatePassword]: stderr #{stderr}"
      event.sender.send callback, if err? then false else true

if not instance?
  instance = new Config

module.exports = instance
