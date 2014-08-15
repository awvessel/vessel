define (require, exports, module) ->

  Backbone   = require 'backbone'
  topsort    = require 'topsort'

  Container  = require 'cs!models/config/container'

  Containers = Backbone.Collection.extend

    model: Container
    sorted: []

    configured: ->
      filtered = @filter (container) ->
        container.get('enabled') is true
      filtered.length > 0

    enabled: ->
      filtered = @filter (container) ->
        container.get('required') is true or container.get('enabled') is true
      filtered

    filterByName: (names) ->
      filtered = @filter (container) ->
        container.get('name') in names
      filtered

    requiredDependencies: ->
      filtered = @filter (container) ->
        container.get('required') is true
      filtered

    getByName: (name) ->
      retval = null
      for model in @models
        if model.get('name') is name
          retval = model
          break
      retval

    required: ->
      filtered = @filter (container) ->
        container.get('required') is true
      filtered

    byStartOrder: ->
      depTree = []
      required = (container.get('name') for container in @required())
      for container in @enabled()
        name = container.get 'name'
        deps = container.get 'dependencies'
        if deps.length > 0
          for dep in deps
            depTree.push [dep, name]
        else
          depTree.push ['', name]
        for container in required
          if container isnt name
            depTree.push [container, name]

      containers = []
      for name in topsort(depTree)
        if name
          containers.push @getByName(name)
      containers

  Containers
