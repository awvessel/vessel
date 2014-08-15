define (require, exports, module) ->

  Backbone = require 'backbone'
  Port     = require 'cs!models/config/port'

  Ports = Backbone.Collection.extend

    model: Port

  Ports
