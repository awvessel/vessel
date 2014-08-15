define (require, exports, module) ->

  ipc      = nodeRequire 'ipc'

  Backbone = require 'backbone'

  # Wrap the ipc.send functionality in a non-blocking way
  #
  class Logger

    ignore: [
      'auth:password'
      'log:debug'
      'log:error'
      'log:info'
    ]

    constructor: ->

      ipc.on 'log:debug', (message) ->
        console.debug message
        Backbone.trigger 'log:debug', message
      ipc.on 'log:error', (message) ->
        console.error message
        Backbone.trigger 'log:error', message
      ipc.on 'log:info', (message) ->
        console.log message
        Backbone.trigger 'log:info', message

      # Log backbone events
      Backbone.on 'all', (event, args...) =>
        if not event in @ignore
          if args?
            console.log "#{event}: #{args}"
          else
            console.log event

          # Have the backend log the messages
          ipc.send 'log', event, args...

  if not instance?
    instance = new Logger

  instance
