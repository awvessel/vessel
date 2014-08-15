define (require, exports, module) ->

  Backbone   = require 'backbone'
  Container  = require 'cs!models/status/container'

  Containers = Backbone.Collection.extend

    model:  Container

    getByName: (name) ->
      retval = null
      for model in @models
        if model.get('Name') is name
          retval = model
          break
        if name in model.get('Names')
          retval = model
          break
      retval

    removeMissing: (ids) ->
      for model in @models
        if not model?
          @remove model
        if model?.get 'Id' not in ids
          @remove model

  Containers
