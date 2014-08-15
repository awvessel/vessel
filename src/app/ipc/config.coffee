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
    'scripts:copy':         'copyScripts'
    'sshconfig:generate':   'generateSSHConfig'
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

  copyScripts: (event, path, callback) ->
    files = fs.readdirSync("#{__dirname}/../scripts")
    for file in files
      src = "#{__dirname}/../scripts/#{file}"
      dest = "#{path}/scripts/#{file}"
      fs.createReadStream(src).pipe(fs.createWriteStream(dest))
      fs.chmodSync dest, '0755'
    event.sender.send callback, true

  generateSSHConfig: (event, vagrant, ssh, callback) ->
    path = "/home/#{vagrant.user}/.ssh"
    SSH.exec vagrant, ["mkdir -p #{path}"], (result) ->
      Logger.info "[config] Made #{path}"
      SSH.exec vagrant, ["chmod 700 #{path}"], (result) ->
        Logger.info "[config] Fixed permissions on #{path}"
        SSH.scp vagrant
        , "#{__dirname}/../templates/ssh_config", "#{path}/config"
        , (result) ->
          Logger.info "[config] Created #{path}/config"
          tmp = tempWrite.sync ssh.key.private
          SSH.scp vagrant, tmp, "#{path}/id_rsa", (result) ->
            Logger.info "[config] Created #{path}"
            fs.unlinkSync tmp
            SSH.exec vagrant, ["chmod 600 #{path}/id_rsa"]
            , (result) ->
              Logger.info "[config] Fixed permissions on #{path}/id_rsa"
              tmp = tempWrite.sync ssh.key.public
              SSH.scp vagrant, tmp, "#{path}/id_rsa.pub"
              , (result) ->
                fs.unlinkSync tmp
                Logger.info "[config] Created #{path}/id_rsa.pub"
                event.sender.send callback, true

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
