define (require, exports, module) ->

  _          = require 'underscore'
  Model      = require 'model'

  Ports      = require 'cs!collections/config/ports.coffee'
  Repository = require 'cs!models/config/repository.coffee'

  Container = Model.extend

    idAttribute: 'name'

    defaults:
      category:          null
      cpuShares:         null
      dependencies:      []
      dependents:        []
      dns:               null
      enabled:           false
      env:               null
      icon:              null
      image:             null
      hostname:          null
      memory:            null
      memorySwap:        null
      name:              null
      path:              null
      ports:             Ports
      repository:        Repository
      required:          false
      standalone:        false
      tags:              []
      type:              null
      user:              null
      visible:           true
      volumes:           []

    addDependent: (name) ->
      if name not in @get 'dependents'
        dependents = _.clone(@get 'dependents')
        dependents.push name
        @set 'dependents', dependents

    removeDependent: (name) ->
      if name in @get 'dependents'
        dependents = _.without _.clone(@get 'dependents'), name
        @set 'dependents', dependents

  Container
