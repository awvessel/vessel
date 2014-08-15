_        = require 'underscore'
exec     = require('child_process').exec
spawn    = require('child_process').spawn
sudofy   = require 'sudofy'

Listener = require './base'
Logger   = require '../utils/logger'
SSH      = require '../utils/ssh'

# Provide an interface for interacting with Vagrant
#
class Vagrant extends Listener

  events:
    'vagrant:box:update':        'boxUpdate'
    'vagrant:default_provider':  'defaultProvider'
    'vagrant:destroy':           'destroy'
    'vagrant:halt':              'halt'
    'vagrant:ssh':               'ssh'
    'vagrant:status':            'status'
    'vagrant:up':                'up'

  multiline: []

  @boxOutdated: null

  statusPattern: /^(\d+),(\w+|),([\w-]+),(.*)$/
  sshConfigPattern: /^\s+(\w+)\s(.*)$/

  boxUpdate: (event, path, provider, callback) =>
    Logger.debug 'Vagrant Listener: performing box update'
    child = spawn 'vagrant', ['box', 'update', '--provider', provider]
    , cwd: path

    child.stdout.on 'data', (data) =>
      data = data + ''
      for line in data.split '\n'
        @_logLine line
    child.stderr.on 'data', (data) =>
      data = data + ''
      for line in data.split '\n'
        @_logLine line
    child.on 'close', (code) =>
      Logger.debug "Vagrant Listener: Box update completed (#{code})"
      @boxOutdated = null
      event.sender.send callback, (code is 0)

  defaultProvider: (event, callback) ->
    event.sender.send callback, process.env.VAGRANT_DEFAULT_PROVIDER

  destroy: (event, path, password, callback) =>
    @_sudo_true password, () =>
      child = spawn 'vagrant', ['destroy', '-f'], cwd: path

      child.stdout.on 'data', (data) =>
        data = data + ''
        for line in data.split '\n'
          @_logLine line
      child.stderr.on 'data', (data) =>
        data = data + ''
        for line in data.split '\n'
          @_logLine line
      child.on 'close', (code) ->
        Logger.debug "Vagrant Listener: Destroy completed (#{code})"
        event.sender.send callback, if code is 0 then true else false

  halt: (event, path, callback) =>
    child = spawn 'vagrant', ['halt'], cwd: path
    child.stdout.on 'data', (data) =>
      data = data + ''
      for line in data.split '\n'
        @_logLine line
    child.stderr.on 'data', (data) =>
      data = data + ''
      for line in data.split '\n'
        @_logLine line
    child.on 'close', (code) ->
      Logger.debug "Vagrant Listener: Halt completed (#{code})"
      event.sender.send callback, (code is 0)

  ssh: (event, path, callback) =>
    child = spawn 'osascript', [
      '-e',
      "tell app \"Terminal\" to do script \"cd #{path} && vagrant ssh\""
    ], cwd: path
    child.stdout.on 'data', (data) =>
      data = data + ''
      for line in data.split '\n'
        @_logLine line
    child.stderr.on 'data', (data) =>
      data = data + ''
      for line in data.split '\n'
        @_logLine line
    child.on 'close', (code) ->
      Logger.debug "Vagrant Listener: ssh completed (#{code})"
      event.sender.send callback, if code is 0 then true else false

  status: (event, path, callback) =>
    status =
      timestamp: 0
      vm: null
      ip: null
      outdated: null
      user: null
      ssh_port: 22
      ssh_identity_file: null

    @_getStatus event, path, status, (event, status) =>
      Logger.debug 'Vagrant Listener: Status received'
      @_getSSHConfig event, path, status, (event, status) =>
        Logger.debug 'Vagrant Listener: SSH config received'
        @_isBoxOutdated event, path, status, (event, status) ->
          Logger.debug 'Vagrant Listener: Outdated status received'
          event.sender.send callback, status

  up: (event, path, provider, password, callback) =>
    Logger.debug "Vagrant Listener: Performing up with #{provider}"
    @_sudo_true password, () =>
      child = spawn 'vagrant', ['up', '--provider', provider], cwd: path
      child.stdout.on 'data', (data) =>
        data = data + ''
        for line in data.split '\n'
          @_logLine line
      child.stderr.on 'data', (data) =>
        data = data + ''
        for line in data.split '\n'
          @_logLine line
      child.on 'close', (code) ->
        Logger.debug "Vagrant Listener: Up completed (#{code})"
        event.sender.send callback, if code is 0 then true else false

  _getStatus: (event, path, status, callback) ->
    Logger.debug 'Vagrant Listener: Performing status'
    command = "cd #{path} && vagrant --machine-readable status"
    exec command, (err, stdout, stderr) =>
      for value in @_parseOutput stdout
        if value[0] > status.timestamp
          status.timestamp = value[0]
        if status.vm is null and value[1]
          status.vm = value[1]
        status[value[2].replace /-/g, '_'] = value[3]
      callback event, status

  _getSSHConfig: (event, path, status, callback) ->
    # Use the SSH config output to get the IP address (diff format)
    Logger.debug 'Vagrant Listener: Performing ssh-config'
    command = "cd #{path} && vagrant ssh-config"
    exec command, (err, stdout, stderr) =>
      for line in stdout.split '\n'
        matches = @sshConfigPattern.exec line
        if matches?
          switch matches[1]
            when 'HostName'
              status.ip = matches[2]
            when 'User'
              status.user = matches[2]
            when 'IdentityFile'
              status.ssh_identify_file = matches[2]
            when 'Port'
              status.ssh_port = matches[2]
      @_getUptime event, status, callback

  _getUptime: (event, status, callback) ->
    Logger.debug 'Vagrant Listener: Fetching uptime'
    if status.state is 'running'
      command = "cat /proc/uptime | awk '{print $1}'"
      SSH.exec status, [command], (result) ->
        if result[0]
          status.timestamp = (new Date().valueOf()/1000) - parseInt(result[1])
        callback event, status
    else
      callback event, status

  _isBoxOutdated: (event, path, status, callback) ->
    if @boxOutdated?
      status.outdated = @boxOutdated
      callback event, status
    else
      Logger.info 'Vagrant Listener: Checking if box is outdated'
      exec "cd #{path} && vagrant box outdated", (err, stdout, stderr) ->
        status.outdated = "#{stdout}".indexOf('vagrant box update') > 0
        callback event, status

  _logLine: (line) ->
    if line?
      Logger.info "[vagrant] #{line}"

  _parseOutput: (output) ->
    values = []
    for line in output.split '\n'
      matches = @statusPattern.exec line
      if matches?
        matches.shift()
        matches[0] = parseInt matches[0]
        values.push matches
    values

  _sudo_true: (password, callback) ->
    if not password?
      password = 'foo'
    command = sudofy.command 'true', {
      password: password
    }
    exec command, (err, stdout, stderr) ->
      console.log '_sudo_true', err
      callback if err? then false else true

if not instance?
  instance = new Vagrant

module.exports = instance
