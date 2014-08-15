define (require, exports, module) ->

  Model = require 'model'

  HostConfig = Model.extend

    defaults:
      Binds: null
      ContainerIDFile: null
      LxcConf: []
      Privileged: false
      PortBindings: {}
      Links: null
      PublishAllPorts: false

  HostConfig
