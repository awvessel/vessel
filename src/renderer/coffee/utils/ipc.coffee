# Wrap the ipc.send functionality in a non-blocking way

define (require, exports, module) ->

  ipc  = nodeRequire 'ipc'
  _    = require 'underscore'
  $    = require 'jquery'

  class IPC

    promises: {}

    send: (channel, options..., callback) ->
      promiseId = _.uniqueId 'ipc-promise-'
      @promises[promiseId] = callback
      ipc.once promiseId, (args...) =>
        #console.log "Callback received for #{promiseId}"
        callback = @promises[promiseId]
        delete @promises[promiseId]
        callback args...
      ipc.send channel, options..., promiseId

  if not instance?
    instance = new IPC

  instance
