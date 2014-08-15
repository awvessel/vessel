define (require, exports, module) ->

  $           = require 'jquery'
  Backbone    = require 'backbone'
  Listener    = require 'listener'

  environment = require 'cs!utils/environment'
  ipc         = require 'cs!utils/ipc'


  # Perform all actions required to build the environment
  #
  class Build extends Listener

    nonContainerSteps: 3

    events:
      'environment:build':  'onBuild'
      'cloud-config:build': 'onCloudConfigBuild'

    initialize: ->
      @config = arguments[0].config

    onBuild: =>
      Backbone.trigger 'modal:status:steps', @_calculateSteps()
      @_generateVagrantfile (result) =>
        if not result
          console.error "Error generating vagrantfile"
        @_stepComplete()
        @_installScripts (result) =>
          if not result
            console.error "Error installing scripts"
          @_stepComplete()
          @_cloneSource () ->
            console.log "Cloned"
            Backbone.trigger 'environment:build:complete'

    onCloudConfigBuild: (url) =>
      console.log "Fetching new etcd discovery URL"
      ipc.send 'etcd:url:fetch', (url) =>
        console.debug "Received URL: #{url}"
        @config.etcd.set 'url', url
        @_generateCloudConfig url, (result) ->
          console.log "Cloud config generated"
          if not result
            console.error "Error generating cloud config"
          Backbone.trigger 'cloud-config:built'

    _calculateSteps: ->
      containers = @config.containers.enabled()
      containers.length + @nonContainerSteps

    _cloneSource: (callback) ->
      basePath = "#{environment.path}/source"
      ipc.send 'directory:ensure', basePath, () =>
        Backbone.trigger 'application:status', 'cloning'
        deferreds = {}
        promises = []
        for container in @config.containers.enabled()
          repository = container.get("repository")
          if repository.get('url')? and repository.get('enabled')
            url = repository.get 'url'
            path = "#{basePath}/#{repository.get('name')}"
            branch = repository.get 'branch'
            console.debug "Git clone: #{url}, #{path}, #{branch}"

            deferreds[path] = $.Deferred()
            promises.push deferreds[path].promise()

            ipc.send 'git:clone', url, path, branch, (path, response) =>
              if response.result is false
                if not response.output.indexOf 'already exists'
                  console.error "Error doing git clone: #{response.output}"
              @_stepComplete()
              deferreds[path].resolve()
          else
            @_stepComplete()

        console.log "Waiting on #{promises.length} promises"
        $.when.apply($, promises).done () ->
          console.log "Promises complete"
          callback()

    _generateCloudConfig: (url, callback) ->
      console.log "Generating cloud-config: #{url}"
      Backbone.trigger 'application:status', 'generate-cloudconfig'
      ipc.send 'cloudconfig:generate'
      , environment.path, url, false, (result) ->
        console.log "Heard back from generate: #{result}"
        callback(result)

    _generateVagrantfile: (callback) ->
      Backbone.trigger 'application:status', 'generate-vagrantfile'
      ipc.send 'vagrantfile:generate', @config.model.toJSON()
      , environment.path, false, (result) ->
        callback(result)

    _installScripts: (callback) ->
      Backbone.trigger 'application:status', 'installing-scripts'
      # @todo: actually copy any scripts in that are required
      ipc.send 'directory:ensure', "#{environment.path}/scripts", (result) ->
        console.log "Path ensured"
        callback(result)

    _stepComplete: ->
      Backbone.trigger 'modal:status:step'

  Build
