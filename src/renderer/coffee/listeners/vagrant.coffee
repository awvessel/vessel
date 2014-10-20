define (require, exports, module) ->

  $           = require 'jquery'
  Backbone    = require 'backbone'
  Listener    = require 'listener'

  environment = require 'cs!utils/environment'
  ipc         = require 'cs!utils/ipc'

  Status      = require 'cs!models/status/vagrant'


  # Provide an interface for interacting with Vagrant
  #
  class Vagrant extends Listener

    events:
      'vagrant:box:update':   'updateBox'
      'vagrant:destroy':      'destroy'
      'vagrant:status':       'status'
      'vagrant:halt':         'halt'
      'vagrant:up':           'up'
      'vagrant:scripts:copy': 'scriptsCopy'
      'vagrant:ssh':          'ssh'
      'vagrant:ssh-config':   'sshConfig'

    initialize: ->
      @config = arguments[0].config
      @model = new Status
      @listenTo @model, 'change', (model) =>
        @trigger 'change', model

    destroy: (callback) =>
      ipc.send 'vagrant:destroy'
      , environment.path
      , @config.model.get('password')
      , (result) =>
        @status callback

    scriptsCopy: ->
      ipc.send 'scripts:copy'
      , environment.path
      , (result) ->
        Backbone.trigger 'vagrant:scripts:copy:complete'

    ssh: ->
      ipc.send 'vagrant:ssh', environment.path, (result) ->
        console.log 'ssh'

    status: (callback) =>
      @model.fetch () ->
        if callback?
          callback()

    halt: (callback) =>
      if @model.get('state') is 'running'
        Backbone.trigger 'application:status', 'stopping'
        ipc.send 'vagrant:destroy'
        , environment.path
        , @config.model.get('password')
        , (result) =>
          @status callback

    up: (callback) =>
      Backbone.trigger 'application:status', 'starting'
      ipc.send 'vagrant:up'
      , environment.path
      , @config.vagrant.get('provider')
      , @config.model.get('password')
      , (result) =>
        if result is false
          Backbone.trigger 'vagrant:up:error'
        @status callback

    updateBox: =>
      if @model.get('state') is 'running'
        @halt () =>
          @_updateBox () ->
            Backbone.trigger 'vagrant:request:up'
      else
        @_updateBox()

    _updateBox: (callback) ->
      ipc.send 'vagrant:box:update'
      , environment.path
      , @config.model.get('provider')
      , (result) =>
        @status () ->
          if callback?
            callback()

  Vagrant
