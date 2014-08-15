define (require, exports, module) ->

  Model = require 'model'

  Port = Model.extend

    defaults:
      guest:    null
      guest_ip: null
      host:     null
      host_ip:  null
      protocol: 'tcp'
      auto_correct: true

  Port
