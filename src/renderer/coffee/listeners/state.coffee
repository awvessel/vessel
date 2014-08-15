define (require, exports, module) ->

  $           = require 'jquery'
  Backbone    = require 'backbone'
  Listener    = require 'listener'

  environment = require 'cs!utils/environment'
  ipc         = require 'cs!utils/ipc'

  # Coordinate UI actions based upon state requirements
  #
  class State extends Listener

    events:
      'application:status':             'onApplicationStatus'
      'auth:password':                  'onAuthPassword'
      'cloud-config:built':             'onCloudConfigBuilt'
      'docker:started':                 'onDockerStarted'
      'docker:container:request:start': 'onDockerStartRequest'
      'docker:container:request:stop':  'onDockerStopRequest'
      'docker:containers:updated':      'onDockerContainers'
      'environment:build:request':      'onBuildRequest'
      'environment:build:complete':     'onBuildComplete'
      'error':                          'onError'
      'timers:pause':                   'pauseTimer'
      'timers:resume':                  'startTimer'
      'vagrant:log':                    'onVagrantLog'
      'vagrant:request:halt':           'onVagrantHalt'
      'vagrant:request:update':         'onVagrantUpdate'
      'vagrant:request:up':             'onVagrantUp'
      'vagrant:ssh-config:complete':    'onSSHConfigCreated'
      'vagrant:scripts:copy:complete':  'onScriptsCopyComplete'
      'vagrant:up:error':               'onVagrantUpError'

    vagrantSteps: [
      'Bringing machine'
      'Importing base box'
      'SSH username'
      'Machine booted and ready!'
      'Configuring and enabling network'
      'Exporting NFS shared folders'
      'Mounting NFS shared folders'
      'Running provisioner: file'
      'Running provisioner: shell'
    ]

    _dirty: false
    _refreshTimer: null
    _singleAction: null
    _state: null

    initialize: ->

      @_setState 'initializing'

      @_deferreds =
        config: $.Deferred()
        containers: $.Deferred()
        images: $.Deferred()
        vagrant: $.Deferred()

      $.when(@_deferreds.config.promise(),
             @_deferreds.containers.promise(),
             @_deferreds.images.promise(),
             @_deferreds.vagrant.promise()).done () =>
        @_onInitialized()

      @_listeners =
        build: arguments[0].build
        config: arguments[0].config
        docker: arguments[0].docker
        vagrant: arguments[0].vagrant

      @config = @_listeners.config.model
      @containers = @_listeners.docker.containers
      @images = @_listeners.docker.images
      @vagrant = @_listeners.vagrant.model

      @listenTo @_listeners.build, 'dirty', () =>
        @_onBuildEvent()

      @listenToOnce @_listeners.config, 'loaded', () =>
        @_onConfigLoaded()

      @listenTo @_listeners.config, 'dirty', (model) =>
        if @_state isnt 'initializing'
          @_onConfigDirty()

      @listenTo @_listeners.config, 'saved', (model) =>
        @_setState 'saved'
        @_dirty = false
        @_toggleFooterButtons()
        Backbone.trigger 'modal:status:hide'

      @listenTo @_listeners.docker, 'images:change', (collection) =>
        @_onImagesChange(collection)

      @listenTo @_listeners.vagrant, 'change', (model) =>
        @_onVagrantChange(model)

    onApplicationStatus: (status, args...) =>
      switch status
        when 'container:started'
          if @_singleAction is true
            @_singleAction = null
            Backbone.trigger 'modal:status:hide'
        when 'container:stopped'
          if @_singleAction is true
            @_singleAction = null
            Backbone.trigger 'modal:status:hide'

    onAuthPassword: (value) =>
      if @_vagrantRunning() is true
        @_vagrantDestroy()
      else
        @_vagrantUp()

    onBuildComplete: ->
      Backbone.trigger 'configuration:save'

    onBuildRequest: =>
      @_setState 'build:start'
      Backbone.trigger 'modal:status:show', 'build:start', true, true
      Backbone.trigger 'environment:build'

    onCloudConfigBuilt: =>
      Backbone.trigger 'modal:status:step'
      @_setState 'vagrant:starting'
      Backbone.trigger 'vagrant:up'

    onDockerContainers: =>
      if @_state is 'initializing'
        @_deferreds.containers.resolve()

    onDockerStartRequest: (name) =>
      @_singleAction = true
      @_stopRefreshTimer()
      Backbone.trigger 'modal:status:show', 'docker:start', false, true
      Backbone.trigger 'docker:container:start', name

    onDockerStopRequest: (name) =>
      @_singleAction = true
      Backbone.trigger 'modal:status:show', 'docker:stop', false, true
      Backbone.trigger 'docker:container:stop', name

    onDockerStarted: =>
      @_setState 'running'
      @_startRefreshTimer()
      @_toggleFooterButtons()
      Backbone.trigger 'modal:status:hide'

    onError: (reason) =>
      switch reason
        when 'image:create'
          if @_singleAction
            @single_action = null
            Backbone.trigger 'modal:status:hide'

    onScriptsCopyComplete: ->
      Backbone.trigger 'modal:status:step'
      Backbone.trigger 'docker:start'

    onSSHConfigCreated: ->
      Backbone.trigger 'modal:status:step'
      Backbone.trigger 'modal:status:hideLogs',
      Backbone.trigger 'vagrant:scripts:copy'

    onVagrantHalt: =>
      @_stopRefreshTimer()
      # If the password is set, assume it's corrent and start the build
      if @config.get('password')?
        @_vagrantDestroy()
      else
        # Dont show dialog if sudo has cached authentication creds
        ipc.send 'password:validate', 'null', (result) =>
          if result
            @_vagrantDestroy()
          else
            Backbone.trigger 'modal:dialog:auth:show'

    onVagrantLog: (message) =>
      for step in @vagrantSteps
        if message.indexOf(step) > -1
          Backbone.trigger 'modal:status:step'
          break

    onVagrantUp: =>
      @_stopRefreshTimer()
      # If the password is set, assume it's corrent and start the build
      if @config.get('password')?
        @_vagrantUp()
      else
        # Dont show dialog if sudo has cached authentication creds
        ipc.send 'password:validate', 'null', (result) =>
          if result
            @_vagrantUp()
          else
            Backbone.trigger 'modal:dialog:auth:show'

    onVagrantUpdate: =>
      @_stopRefreshTimer()
      @_setState 'vagrant:updating'
      Backbone.trigger 'modal:status:show', 'updating', false, true, true
      Backbone.trigger 'vagrant:box:update'

    onVagrantUpError: =>
      @_setState 'vagrant:error'
      @_toggleFooterButtons()
      Backbone.trigger 'modal:status:hide'
      Backbone.trigger 'error', 'vagrant:start'

    pauseTimer: () ->
      @_stopRefreshTimer()

    resumeTimer: () ->
      @_startRefreshTimer()

    _onConfigDirty: () ->
      if @_state isnt 'initializing'
        @_dirty = true
        @_setState 'build:required'
        @_toggleFooterButtons()

    _onConfigLoaded: () ->
      @_deferreds.config.resolve()
      network =  @_listeners.config.vagrant.get 'network'
      Backbone.trigger 'application:ready'
      Backbone.trigger 'docker:config', network.get 'ip'
      Backbone.trigger 'vagrant:status'

    _onImagesChange: (collection) ->
      if @_state is 'initializing'
        @_deferreds.images.resolve()

    _onInitialized: ->
      @_setState 'initialized'
      if not @_listeners.config.containers.configured()
        $('a[href="#containers"]').click()
      Backbone.trigger 'render:ui'
      Backbone.trigger 'modal:status:hide'

    _onVagrantChange: (model) ->
      switch @_state
        when 'initializing'
          switch model.get 'state'
            when 'running'
              @_deferreds.vagrant.resolve()
              Backbone.trigger 'docker:status'
            else
              @_deferreds.containers.resolve()
              @_deferreds.images.resolve()
              @_deferreds.vagrant.resolve()
        when 'vagrant:starting'
          @_setState 'configuring-ssh'
          Backbone.trigger 'modal:status:step'
          Backbone.trigger 'vagrant:ssh-config'
        when 'vagrant:updating'
          @_setState 'updated'
          Backbone.trigger 'modal:status:hide'
        when 'vagrant:stopping'
          @_setState 'stopped'
          Backbone.trigger 'docker:reset'
          Backbone.trigger 'modal:status:hide'

      @_toggleFooterButtons()

    _setState: (state) ->
      if state isnt @_state
        @_state = state
        Backbone.trigger 'application:state', @_state

    _startRefreshTimer: ->
      if not @_refreshTimer?
        @_refreshTimer = setInterval () =>
          Backbone.trigger 'vagrant:status', () =>
            if @_vagrantRunning()
              Backbone.trigger 'docker:status'
        , 15000

    _stopRefreshTimer: ->
      if @_refreshTimer?
        clearInterval @_refreshTimer
        @_refreshTimer = null

    _toggleFooterButtons: ->
      build = @_state is 'build:required'
      outdated = @vagrant.get 'outdated'
      power = @_state isnt 'build:required'
      isUp  = @_vagrantRunning()
      Backbone.trigger 'footer:buttons:toggle', build, outdated, power, isUp

    _vagrantDestroy: ->
      @_setState 'vagrant:stopping'
      Backbone.trigger 'modal:status:show', 'stopping', false, true, true
      Backbone.trigger 'vagrant:halt'

    _vagrantRunning: ->
      @vagrant.get('state') is 'running'

    _vagrantUp: ->
      containers = @config.get('containers')
      containerCount = containers.byStartOrder().length
      steps = 4 + @vagrantSteps.length + containerCount
      Backbone.trigger 'modal:status:steps', steps
      Backbone.trigger 'modal:status:show', 'starting', true, true, true
      Backbone.trigger 'cloud-config:build'

  State
