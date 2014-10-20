define (require, exports, module) ->

  _           = require 'underscore'
  $           = require 'jquery'
  Backbone    = require 'backbone'
  Listener    = require 'listener'

  environment = require 'cs!utils/environment'
  ipc         = require 'cs!utils/ipc'
  uri         = require 'cs!utils/uri'

  Config      = require 'cs!models/config'

  # Contains the configuration loaded from the manifest in a combination of
  # models and containers. On change of the configuration, the application
  # status will be updated
  #
  class Configuration extends Listener

    events:
      'auth:password':               'onAuthPassword'
      'container:toggle':            'containerToggle'
      'container:repository:toggle': 'containerRepositoryToggle'
      'configuration:save':          'saveLocalManifest'

    initialize: ->

      @model = new Config

      # Shortcuts to child objects for external reference
      @containers = @model.get 'containers'
      @docker     = @model.get 'docker'
      @etcd       = @model.get 'etcd'
      @vagrant    = @model.get 'vagrant'

      # Listen for changes in the containers
      @listenTo @model, 'change', (model) =>
        @trigger 'dirty', model

    # Toggle a container and its dependencies
    #
    # @param [String] the container name
    # @param [Boolean] indicate if the container is enabled
    #
    containerToggle: (name, enabled) =>
      if enabled is true
        @_enableContainer name
      else
        @_disableContainer name
      @_updateVagrantPorts()
      if @containers.configured()
        @trigger 'dirty', @model
      else
        @trigger 'empty', @model

    # Toggle a container and its dependencies
    #
    # @param [String] the container name
    # @param [Boolean] indicate if the container is enabled
    #
    containerRepositoryToggle: (name, enabled) =>
      container = @containers.get name
      if container?
        repository = container.get 'repository'
        repository.set 'enabled', enabled

    # Load the manifest file into the local collection and models
    #
    load: ->
      # Send the IPC request to load either the global or local manifest
      ipc.send "manifest:load", environment.path, (manifest) =>
        @docker.set manifest.docker
        @vagrant.set manifest.vagrant
        if not @vagrant.get('provider')?
          ipc.send 'vagrant:default_provider', (response) =>
            if response?
              @vagrant.set 'provider', response
            else
              @vagrant.set 'provider', 'virtualbox'

        # Load the repository branches then trigger done
        @_processContainers manifest.containers, () =>
          @trigger 'loaded'

    # Set the password that is being passed in the event
    #
    onAuthPassword: (value) =>
      @model.set password: value

    # Safe the local manifest file out to the environment directory
    #
    saveLocalManifest: =>
      Backbone.trigger 'application:status', 'saving-config'
      config = @model.toJSON()
      delete config.password
      for index, item of config.containers

        # Prune unneeded config options
        for key of item

          # Remove null values
          if config.containers[index][key] is null
            delete config.containers[index][key]

          # Remove empty arrays
          if _.isArray config.containers[index][key]
            if config.containers[index][key].length is 0
              delete config.containers[index][key]

      ipc.send 'manifest:local:save', environment.path, config, (response) =>
        @trigger 'saved'

    # Disable the indicated container and dependencies that are enabled with
    # no other dependents
    #
    # @param [String] the container name to disable
    #
    _disableContainer: (name) ->
      container = @containers.get name
      if container?
        container.set 'enabled', false
        deps = @containers.filterByName container.get 'dependencies'
        for dependency in deps
          dependency.removeDependent name
          if dependency.get('dependents').length is 0
            @_disableContainer dependency.get 'name'
      else
        console.error "Could not find #{name} in @containers"

    # Enable the indicated container and dependency containers
    #
    # @param [String] the container name to enable
    #
    _enableContainer: (name) ->
      container = @containers.get name
      if container?
        container.set('enabled', true)
        deps = @containers.filterByName container.get('dependencies')
        for dependency in deps
          dependency.addDependent(name)
          @_enableContainer dependency.get 'name'
      else
        console.error "Could not find #{name} in @containers"

    # Iterate through all of the containers, normalizing ports and load branch
    # information from the github repository.
    #
    # @param [Object] the manifest object to create the containers from
    # @param [Function] the function to call when the repositories are loaded
    #
    _processContainers: (containers, callback) ->
      for index, container of containers

        # If the port is just a number, turn it into an object
        if container.ports?
          ports = []
          for port in container.ports
            if _.isNumber port
              obj =
                guest: port
                host: port
                protocol: 'tcp'
              ports.push obj
            else
              ports.push port
          containers[index].ports = ports

      @containers.reset containers
      deferreds = []
      promises = []
      for container in @containers.models
        url = container.get('repository').get 'url'
        if url?
          deferred = $.Deferred()
          deferreds[container.id] = deferred
          promises.push deferred.promise()
          parts = uri.parse url
          container.get('repository').set name: parts[3]
          ipc.send 'git:branches:get', container.id
          , parts[1], parts[2], parts[3], (id, values) =>
            @containers.get(id).get('repository').set branches: values
            deferreds[id].resolve()

      console.debug "Waiting on #{promises.length} promises"
      $.when.apply($, promises).done () ->
        console.debug "Promises complete"
        callback()

    # Update the Vagrant model with the list of enabled ports that should be
    # exposed in the configuration due to enabled container port definitions.
    #
    _updateVagrantPorts: ->
      containers = @containers.enabled()
      ports = []
      for container in containers
        containerPorts = container.get('ports')
        if containerPorts?.length > 0
          ports = _.union(ports, containerPorts.toJSON())
      @vagrant.set 'ports', ports

    # Create the object that will be used to populate the
    #
    # @param [Object] the manifest vagrant object to create the model from
    # @return [Vagrant] an instance of the Vagrant model
    #
    _vagrantValues: (vagrant) ->
      values = {
        box: if vagrant.box? then vagrant.box else \
        Vagrant.prototype.defaults.box
        hostname: if vagrant.hostname? then vagrant.hostname else \
        Vagrant.prototype.defaults.hostname
        cpu_count: if vagrant.cpu_count? then vagrant.cpu_count else \
        Vagrant.prototype.defaults.cpu_count
        ram: if vagrant.ram? then vagrant.ram else \
        Vagrant.prototype.defaults.ram
        gui: if vagrant.gui? then vagrant.gui else \
        Vagrant.prototype.defaults.gui
        network: {
          ip: vagrant.network.ip
          type: vagrant.network.type
        }
        providers: vagrant.providers
        synced_folders: vagrant.synced_folders
      }
      values

  Configuration
