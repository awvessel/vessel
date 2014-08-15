define (require, exports, module) ->

  Model      = require 'model'

  ContainerConfig = Model.extend
    defaults:
      Hostname: null
      User: null
      Memory: null
      MemorySwap: 0
      AttachStdin: false
      AttachStdout: true
      AttachStderr: true
      PortSpecs: null
      Tty: false
      OpenStdin: false
      StdinOnce: false
      Env: null
      Cmd: null
      Dns: null
      Image: null
      Volumes: null
      VolumesFrom: null
      WorkingDir: null

  ContainerConfig
