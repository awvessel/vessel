define (require, exports, module) ->

  Model = require 'model'

  Network = Model.extend

    defaults:
      type:    'private'
      ip:      null

  Network
