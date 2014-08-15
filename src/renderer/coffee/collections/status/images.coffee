define (require, exports, module) ->

  Backbone  = require 'backbone'
  Image     = require 'cs!models/status/image'

  Images = Backbone.Collection.extend

    model:  Image

    getByTag: (tag) ->
      retval = null
      for model in @models
        if "#{tag}:latest" in model.get('RepoTags')
          retval = model
          break
      retval

  Images
