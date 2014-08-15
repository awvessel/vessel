cson     = require 'season'
spawn    = require('child_process').spawn
fs       = require 'fs-plus'
restler  = require 'restler'

Listener = require './base'
Logger   = require '../utils/logger'

# Implement listeners that perform git && github actions
#
class Git extends Listener

  events:
    'git:branches:get': 'branches'
    'git:clone':        'clone'
    'git:pull':         'pull'

  # Return a list of all branches for a git repository
  branches: (event, id, host, user, repo, callback) ->
    # Allow for either github.com or an enterprise GitHub instance
    if host == 'github.com'
      url = "https://api.github.com/repos/#{user}/#{repo}/branches"
    else
      url = "https://#{host}/api/v3/repos/#{user}/#{repo}/branches"

    request = restler.get url, rejectUnauthorized=false
    request.on 'complete', (data, response) ->
      if response.statusCode == 200
        event.sender.send callback, id, (b.name for b in data)
      else
        event.sender.send callback, id, []

  clone: (event, url, dest, branch, callback) =>
    Logger.info "[git] Performing clone #{url}, #{dest}, #{branch}"
    branch = if branch? then branch else 'master'
    @_exec event, ['clone', url, dest, '-b', branch], dest, callback

  pull: (event, dest, callback) =>
    Logger.info "[git] Performing pull #{dest}"
    @_exec event, ['pull', dest], dest, callback

  _exec: (event, command, id, callback) ->
    child = spawn 'git', command, {
      cwd: process.cwd
      env: process.env
    }
    output = []
    child.stdout.on 'data', (data) ->
      data = '' + data
      Logger.info "[git]: #{data.trim()}"
      output.push data
    child.stderr.on 'data', (data) ->
      data = '' + data
      Logger.info "[git]: #{data.trim()}"
      output.push data
    child.on 'close', (code) ->
      console.log "[git] #{command.join(' ')} completed (#{code})"
      event.sender.send callback, id, {
        command: command
        result: code is 0
        output: output.join('').replace /\n/g, ''
      }

if not instance?
  instance = new Git

module.exports = instance
