# Provide an interface for interacting with Docker

define (require, exports, module) ->

  Backbone      = require 'backbone'
  Listener      = require 'listener'

  ipc           = require 'cs!utils/ipc'

  Container     = require 'cs!models/status/container'
  Containers    = require 'cs!collections/status/containers'
  Image         = require 'cs!models/status/image'
  Images        = require 'cs!collections/status/images'

  class Docker extends Listener

    events:
      'docker:start':             'start'
      'docker:config':            'config'
      'docker:container:inspect': 'containerInspect'
      'docker:container:start':   'containerStart'
      'docker:container:stop':    'containerStop'
      'docker:containers':        'containerList'
      'docker:images':            'imageList'
      'docker:reset':             'reset'
      'docker:status':            'status'

    ipAddress: null
    port: 4243

    stack: []

    initialize: ->
      @config = arguments[0].config

      @containers = new Containers
      @images = new Images

      @listenTo @containers, 'all', (collection) =>
        @trigger 'containers:change', collection

      @listenTo @images, 'reset', (collection) =>
        @trigger 'images:change', collection

    config: (ipAddress) =>
      @ipAddress = ipAddress

    containerInspect: (id, callback) =>
      ipc.send 'docker:container:inspect', @ipAddress, id, (container) =>
        @_containersUpsertContainer container
        if callback?
          callback(id)

    containerList: (callback) =>
      ipc.send 'docker:containers', @ipAddress, (containers) =>
        # Remove any containers that are not returned from the collection
        ids = (c.Id for c in containers)
        @containers.removeMissing ids

        # if there is a callback, use deferreds to wait on promises
        deferreds = []
        promises = []

        # Iterate through each, filling in the full runtime state w/ inspection
        for container in containers
          deferred = $.Deferred()
          deferreds[container.Id] = deferred
          promises.push deferred.promise()
          @containerInspect container.Id, (id) ->
            deferreds[id].resolve()

        # Wait on promises
        console.debug "Waiting on #{promises.length} promises"
        $.when.apply($, promises).done () ->
          Backbone.trigger 'docker:containers:updated'
          if callback
            callback()

    containerStart: (name, startNext, callback) =>
      $deferred = $.Deferred()
      $promise = $deferred.promise()
      started = null

      # Check to see if it's already running
      container = @containers.getByName name
      if not container?

        @_containerCreate name, (result) =>
          if result
            @_containerStart name, (result) ->
              started = result
              $deferred.resolve()
          else
            started = result
            $deferred.resolve()
      else
        @_containerStart name, (result) ->
          started = result
          $deferred.resolve()

      $.when($promise).done () =>
        if startNext? and startNext
          Backbone.trigger 'modal:status:step'
          @_containerStartNext()
        if callback?
          callback started

    containerStop: (name, callback) =>
      container = @containers.getByName name
      @_setStatus 'container:stop', container: name
      ipc.send 'docker:container:stop'
      , @ipAddress
      , container.get('Id')
      , (response) =>
        if response is true
          @containerInspect container.get('Id'), () =>
            @_setStatus 'container:stopped', container: name
            if callback?
              callback()
        else
          Docker.trigger 'error', 'container:stop', response
          if callback?
            callback()

    imageList: (callback) =>
      ipc.send 'docker:images', @ipAddress, (data) =>
        @images.reset data
        if callback?
          callback()

    reset: (callback) =>
      @images.reset()
      @containers.reset()

    start: (callback) =>
      @containerList () =>
        @stack = (c.get('name') for c in @config.containers.byStartOrder())
        @_containerStartNext()

    status: (callback) =>
      if callback?
        @imageList () =>
          @containerList () ->
            callback()
      else
        @imageList()
        @containerList()

    _containerCreate: (name, callback) ->
      @_setStatus 'container:create', container: name
      container = @config.containers.get name

      config =
        Image: @_dockerImage container.get 'image'
        name: name
      if container.get 'dns'
        config.Dns = container.get 'dns'
      if container.get 'env'
        config.Env = container.get 'env'
      else
        config.Env = []

      # Add the server IP
      network =  @config.vagrant.get 'network'
      config.Env.push "VM_IPADDR=#{network.get 'ip'}"

      if container.get 'hostname'
        config.Hostname = container.get 'hostname'
      if container.get 'memory'
        config.Memory = container.get 'memory'
      if container.get 'memorySwap'
        config.MemorySwap = container.get 'memorySwap'

      containerPorts = container.get 'ports'
      ports = {}
      for port in containerPorts.models
        ports["#{port.get('guest')}/#{port.get('protocol')}"] = {}
      if ports
        config.ExposedPorts = ports

      containerVolumes = container.get 'volumes'
      volumes = {}
      for volume in containerVolumes
        volumes[volume] = {}
      if volumes
        config.Volumes = volumes

      if not @images.getByTag config.Image
        @_containerImageCreate config.Image, (response) =>
          if response is true
            @_containerCreateIPC config, (response) ->
              callback response
          else
            Backbone.trigger 'error', 'image:create', response
            callback response
      else
        @_containerCreateIPC config, (response) ->
          callback response

    _containerCreateIPC: (config, callback) ->
      ipc.send 'docker:container:create', @ipAddress, config, (response) =>
        if response.error?
          # Container already exists
          if response.statusCode is 409
            # Update the container list
            @containerList () ->
              callback true
          else
            console.error "Error creating a container: #{response.message}"
            Backbone.trigger 'error', 'container:create', response
            callback false
        else
          if response.Id?
            @containerInspect response.Id, () ->
              callback true
          else
            @containerList () ->
              callback true

    _containerImageCreate: (tag, callback) ->
      parts = tag.split '/'
      parts.shift()
      @_setStatus 'image:create', image: parts.join('/')
      ipc.send 'docker:image:create'
      , @ipAddress
      , tag
      , 'latest'
      , (response) =>
        if not response?
          console.error "Failed to create #{tag}"
        @imageList () ->
          callback response

    _containerStart: (name, callback) ->
      console.debug "_containerStart: #{name}"
      @_containerStartIPC name, (result) =>
        if result is true
          container = @containers.getByName name
          @containerInspect container.get('Id'), () =>
            @_setStatus "container:started", container: name
            if callback?
              callback result
        else
          Backbone.trigger 'error', 'container:start', result
          if callback?
            callback false

    _containerStartIPC: (name, callback) ->
      console.debug "_containerStartIPC: #{name}"
      container = @containers.getByName(name)
      @_setStatus "container:start", container: name
      [links, ports, volumesFrom] = [[], {}, []]
      containerConfig = @config.containers.getByName name
      dependencies = containerConfig.get 'dependencies'
      if dependencies?
        for depName in dependencies
          dependency = @config.containers.getByName depName
          volumes = dependency.get 'volumes'
          if volumes?
            console.debug "Adding volumes from #{depName}"
            volumesFrom.push depName
          else
            console.debug "Adding dependency #{depName}"
            links.push "#{depName}:#{depName}"

      if not containerConfig.get('standalone')
        repository = containerConfig.get 'repository'
        if repository.get('enabled')
          console.debug 'Adding the SOURCE volume'
          volumesFrom.push 'SOURCE'
        for dependency in @config.containers.requiredDependencies()
          depName = dependency.get('name')
          if depName isnt name
            console.debug "Adding dependency #{depName}"
            links.push "#{depName}:#{depName}"

      containerPorts = containerConfig.get 'ports'
      if containerPorts?
        for port in containerPorts.models
          ports["#{port.get('guest')}/#{port.get('protocol')}"] = [
            HostIp: '0.0.0.0'
            HostPort:"#{port.get('host')}"
          ]

      ipc.send 'docker:container:start'
      , @ipAddress
      , container.get('Id')
      , ports
      , links
      , volumesFrom
      , false
      , (response) =>
        if response.started
          callback true
        else
          if response.error
            @_setStatus "container:error"
            , container: name
            , error: response.message
            console.error "Error starting container #{name}: #{response.error}"
          callback response

    _containerStartNext: () ->
      if @stack.length is 0
        Backbone.trigger 'docker:started'
      else
        name = @stack.shift()
        @containerStart name, true

    _containersUpsertContainer: (container) ->
      model = @containers.get container.Id
      if model?
        model.set container
      else
        @containers.add new Container container

    _dockerImage: (value) ->
      value.replace '<server>', @config.docker.get 'server'

    _setStatus: (status, args...) ->
      Backbone.trigger 'application:status', status, args...

  Docker
