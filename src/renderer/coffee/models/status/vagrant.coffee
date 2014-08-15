define (require, exports, module) ->

  Model       = require 'model'

  environment = require 'cs!utils/environment'
  ipc         = require 'cs!utils/ipc'

  VagrantState = Model.extend

    defaults:
      ip: null
      outdated: false
      provider_name: null
      user: null
      ssh_port: 22
      ssh_identify_file: null
      state: null
      state_human_long: null
      state_human_short: null
      timestamp: 0
      vm: null

    fetch: (callback) ->
      ipc.send 'vagrant:status', environment.path, (status) =>
        values = {}
        for k, v of status
          if @get(k) isnt v
            values[k] = v
        if values
          @set values
        if callback?
          callback status

  VagrantState
