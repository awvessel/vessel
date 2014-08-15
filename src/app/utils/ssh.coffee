spawn     = require('child_process').spawn

Logger   = require '../utils/logger'

# Wrap SSH and SCP
#
class SSH

  exec: (vagrant, options, callback) ->
    base = ['-o', 'StrictHostKeyChecking=no',
            '-o', 'IdentitiesOnly=yes',
            '-o', 'UserKnownHostsFile=/dev/null',
            '-p', vagrant.ssh_port,
            '-i', vagrant.ssh_identify_file,
            "#{vagrant.user}@#{vagrant.ip}"]
    opts = base.concat options
    @_spawn 'ssh', opts, (result) ->
      callback result

  scp: (vagrant, source, dest, callback) ->
    @_spawn 'scp'
    , ['-o', 'StrictHostKeyChecking=no',
       '-o', 'IdentitiesOnly=yes',
       '-o', 'UserKnownHostsFile=/dev/null',
       '-P', vagrant.ssh_port,
       '-i', vagrant.ssh_identify_file,
       source,
       "#{vagrant.user}@#{vagrant.ip}:#{dest}"]
    , (result) ->
      callback result

  _spawn: (command, options, callback) ->
    Logger.info "[ssh #{command}]: #{options.join(' ')}"
    child = spawn command, options, {
      cwd: process.cwd
      env: process.env
    }
    output = []
    child.stdout.on 'data', (data) ->
      data = '' + data
      output.push data
      #Logger.info "[ssh #{command}]: #{data.trim()}"
    child.stderr.on 'data', (data) ->
      data = '' + data
      Logger.debug "[ssh #{command} stderr]: #{data.trim()}"
    child.on 'close', (code) ->
      Logger.info "[ssh #{command}]: #{options.join(' ')} exited (#{code})"
      callback [code is 0, output.join('').trim()]

if not instance?
  instance = new SSH

module.exports = instance
