# Provide an interface for interacting with Docker

cson     = require 'season'
restler  = require 'restler'

Listener = require './base'
Logger   = require '../utils/logger'


class Docker extends Listener


  apiVersion: 'v1.11'

  events:
    'docker:build':                'build'
    'docker:containers':           'containers'
    'docker:container:create':     'containerCreate'
    'docker:container:inspect':    'containerInspect'
    'docker:container:kill':       'containerKill'
    'docker:container:restart':    'containerRestart'
    'docker:container:start':      'containerStart'
    'docker:container:stop':       'containerStop'
    'docker:events':               'eventLog'
    'docker:images':               'images'
    'docker:image:create':         'imageCreate'
    'docker:info':                 'info'
    'docker:ping':                 'ping'
    'docker:version':              'version'

  containers: (event, host, callback) =>
    @_get host, "containers/json?all=true", (statusCode, data) ->
      switch statusCode
        when null
          event.sender.send callback, error: 'no-response'
        when 200
          event.sender.send callback, data
        else
          event.sender.send callback, statusCode, data

  containerCreate: (event, host, config, callback) =>
    path = "containers/create?name=#{config.name}"
    delete config.name
    @_post host, path, config, false, (statusCode, data) ->
      switch statusCode
        when 201
          event.sender.send callback, data
        else
          event.sender.send callback, {
            error: true
            statusCode: statusCode
            message: data
          }

  containerInspect: (event, host, id, callback) =>
    @_get host, "containers/#{id}/json", (statusCode, data) ->
      if data.ID?
        data.Id = data.ID
        delete data.ID
      event.sender.send callback, data

  containerKill: (event, host, id, callback) =>
    @_post host, "containers/#{id}/kill", null,  fallse, (statusCode, data) ->
      event.sender.send callback, data

  containerRestart: (event, host, id, killDelay, callback) =>
    path = "containers/#{id}/restart"
    if killDelay?
      path = "containers/#{id}/restart?t=#{killDelay}"
    @_post host, path, null, false, (statusCode, data) ->
      event.sender.send callback, data

  containerStart: (event, host, id, ports, links, vol, priv, callback) =>
    @_post host, "containers/#{id}/start", {
      PortBindings: if ports? then ports else {}
      Links: if links? then links else []
      VolumesFrom: if vol? then vol else []
      Privileged: if priv? then priv else false
    }, false, (statusCode, data) ->
      Logger.debug "[docker]: containers/#{id}/start (#{statusCode})"
      switch statusCode
        when 204
          event.sender.send callback, started: true, error: false
        when 404
          event.sender.send callback
          , started: false, error:true, message: 'No such container'
        when 406
          event.sender.send callback
          , started: false, error:true, message: 'Error in start request'
        when 500
          event.sender.send callback
          , started: false, error:true, message: data
        when null
          event.sender.send callback
          , started: false, error:true, message: 'timeout'
        else
          Logger.error "[docker] @containerStart error: #{statusCode}"
          Logger.info data
          event.sender.send callback, false

  containerStop: (event, host, id, callback) =>
    @_post host, "containers/#{id}/stop", null, false, (statusCode, data) ->
      switch statusCode
        when 204
          event.sender.send callback, true
        when 404
          event.sender.send callback
          , started: false, error:true, message: 'No such container'
        when 500
          event.sender.send callback
          , started: false, error:true, message: data
        when null
          event.sender.send callback
          , started: false, error:true, message: 'timeout'

  eventLog: (event, host, callback) =>
    @_get host, "events", (statusCode, data) ->
      event.sender.send callback, data

  images: (event, host, callback) =>
    @_get host, "images/json?all=0", (statusCode, data) ->
      event.sender.send callback, data

  imageCreate: (event, host, image, tag, callback) =>
    image = image.replace /\//g, '%2f'
    url = "images/create?fromImage=#{image}"
    @_post host, url, null, true, (statusCode, data) ->
      switch statusCode
        when 200
          event.sender.send callback, true
        when 500
          event.sender.send callback, false
        when null
          Logger.debug "[docker] @imageCreate no response from docker"
          event.sender.send callback, false
        else
          Logger.debug "[docker] @imageCreate unexpected return: #{statusCode}"
          event.sender.send callback, false

  info: (event, host, callback) =>
    @_get "info", (statusCode, data) ->
      event.sender.send callback, data

  ping: (event, host, callback) =>
    @_get "_ping", (statusCode, data) ->
      event.sender.send callback, data

  version: (event, host, callback) =>
    @_get "version", (statusCode, data) ->
      event.sender.send callback, data

  _get: (host, path, callback) ->
    Logger.debug "Docker: @_get #{path}"
    request = restler.get "http://#{host}:4243/#{@apiVersion}/#{path}"
    request.on 'complete', (data, response) ->
      if response?
        callback response.statusCode, data
      else
        callback null, null

  _post: (host, path, data, noParser, callback) ->
    Logger.debug "Docker: @_post http://#{host}:4243/#{@apiVersion}/#{path}"
    options = {}
    if noParser is true
      options.parser = (data, callback) ->
        callback(null, data)
    if data?
      request = restler.postJson "http://#{host}:4243/#{@apiVersion}/#{path}"
      , data, options
    else
      request = restler.post "http://#{host}:4243/#{@apiVersion}/#{path}"
      , options
    request.on 'complete', (data, response) ->
      if response?
        callback response.statusCode, data
      else
        callback null, null

if not instance?
  instance = new Docker

module.exports = instance
