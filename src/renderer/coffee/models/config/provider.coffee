define (require, exports, module) ->

  Model = require 'model'

  Provider = Model.extend

    idAttribute: 'name'

    defaults:
      min_version: null
      name: null
      url: null

  Provider
