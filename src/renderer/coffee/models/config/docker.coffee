define (require, exports, module) ->

  Model = require 'model'

  Docker = Model.extend

    defaults:
      server: null
      path: '/usr/bin/docker'

  Docker
