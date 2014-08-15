define (require, exports, module) ->

  _     = require 'underscore'
  Model = require 'model'

  ipc   = require 'cs!utils/ipc'



  Repository = Model.extend

    idAttribute: 'url'

    defaults:
      url:               null
      enabled:           false
      branch:            'master'
      branches:          []
      name:              null

  Repository
