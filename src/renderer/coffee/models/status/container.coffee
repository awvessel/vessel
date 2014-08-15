define (require, exports, module) ->

  Model           = require 'model'

  Config          = require 'cs!models/status/config'
  State           = require 'cs!models/status/state'
  HostConfig      = require 'cs!models/status/hostConfig'
  NetworkSettings = require 'cs!models/status/networkSettings'


  Container = Model.extend

    idAttribute: 'Id'

    defaults:
      Id: null
      Created: null
      Path: null
      Args: []
      Config: Config
      State: State
      Image: null
      Name: null
      Names: []
      NetworkSettings: NetworkSettings
      Ports: []
      Status: null
      SysInitPath: null
      ResolvConfPath: null
      Volumes: {}
      VolumesRW: {}
      HostConfig: HostConfig

    set: (attributes, options) ->
      for own key, val of attributes
        switch key
          when 'ID'
            attributes.Id = val
          when 'Name'
            if val.charAt 0 is '/'
              attributes[key] = val.substring(1)
          when 'Names'
            for index, value of val
              if value.charAt 0 is '/'
                val[index] = value.substring 1
            if val?.length > 0 and 'Name' not in attributes and not @get 'Name'
              attributes.Name = val[0]

      Model.prototype.set.call @, attributes, options

  Container
