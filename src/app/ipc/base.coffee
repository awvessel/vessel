_   = require 'underscore'
ipc = require 'ipc'

# IPC Listener base class that defines a IPC listener behavior similar to the
# Backbone.View DOM event binding behavior, allowing classes that define the
# events to listen to and automatically binding them on creation
#
class Listener

  events: {}

  constructor: (options = {}) ->
    if options?
      for key, value of options
        @[key] = value

    @_bindEvents()

    if _.isFunction @['initialize']
      @initialize()

  _bindEvents: ->
    for key of @events
      method = @events[key]
      if !_.isFunction @events[key]
        method = @[@events[key]]
      if method?
        ipc.on key, method

module.exports = Listener
