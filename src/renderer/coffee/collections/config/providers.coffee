define (require, exports, module) ->

  Backbone = require 'backbone'
  Provider = require 'cs!models/config/provider'

  Providers = Backbone.Collection.extend

    model: Provider

  Providers
