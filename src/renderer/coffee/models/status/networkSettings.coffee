define (require, exports, module) ->

  Model = require 'model'

  NetworkSettings = Model.extend

    defaults:
      IpAddress: null
      IpPrefixLen: 0
      Gateway: null
      Bridge: null
      Ports: null
      PortMapping: null

  NetworkSettings
