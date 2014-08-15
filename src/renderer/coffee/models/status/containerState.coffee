define (require, exports, module) ->

  Model = require 'model'

  ContainerState = Model.extend

    defaults:
      Running: false
      Pid: 0
      ExitCode: 0
      StartedAt: null
      Ghost: false

  ContainerState
