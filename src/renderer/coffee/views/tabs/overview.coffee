define (require, exports, module) ->

  shell     = nodeRequire 'shell'

  _         = require 'underscore'
  Backbone  = require 'backbone'
  i18n      = require 'i18n'
  moment    = require 'moment'

  strings   = require 'strings!overview'
  status    = require 'strings!status'
  template  = require 'html!tabs/overview'

  Overview = Backbone.View.extend

    events:
      'click [href=#consul]': 'onConsulClick'
      'click [href=#toggle]': 'onContainerToggle'

    containerDirectives:
      control:
        class: () ->
          switch @status
            when 'Running' then  'fa fa-pause'
            when 'Uncreated' then 'fa fa-play'
            when 'Not Started' then 'fa fa-play'
        text: () ->
          ''
      icon:
        class: () ->
          if @icon
            if @icon[0..1] is 'fa'
              "fa #{@icon}"
            else
              "ossicon ossicon-#{@icon}"
          else
            "fa fa-cube"
        html: () ->
          ''
      ipaddr:
        class: () ->
          if @status isnt 'Running'
            'hidden'
      status:
        class: () ->
          if @status isnt 'Running'
            'text-muted'
      toggle:
        class: () ->
          switch @status
            when 'Running' then 'text-warning'
            else 'text-success'
        'data-target': () ->
          @name
        'data-original-title': () ->
          switch @status
            when 'Running'
              strings['stop']()
            when 'Uncreated'
              strings['create']()
            when 'Not Started'
              strings['start']()
      uptime:
        text: () ->
          if @status isnt 'Running'
            ''
          else
            @uptime

    topBarDirectives:
      config:
        'span.vagrant.network.ip':
          text: () ->
            @vagrant.network.ip
        'vagrant.provider':
          text: () ->
            @vagrant.provider

    moment: null
    state: null
    timer: null

    initialize: ->
      # Append the template
      @$el.html i18n.processStrings(strings, template)
      @$dockerTable = @$el.find '#docker-overview'
      @$topBar = @$el.find '#top-bar'
      @$containers = @$el.find '[data-bind="containers"]'
      @$containers.parent().parent().height 370
      @$consulIcon = @$el.find '#consul-icon'

      @state = arguments[0].state

      @listenTo @state.vagrant, 'change', () =>
        @render()

      @listenTo @state.containers, 'change', () =>
        @renderContainers()

    onConsulClick: (e) ->
      e.preventDefault()
      config = @state.config.toJSON()
      shell.openExternal "http://#{config.vagrant.network.ip}:8500/ui/"

    onContainerToggle: (e) ->
      e.preventDefault()
      target = $(e.currentTarget).attr 'data-target'
      container = @state.containers.getByName target
      if container
        state = container.get 'State'
        running = state.get 'Running'
      else
        running = false
      if running
        Backbone.trigger 'docker:container:request:stop', target
      else
        Backbone.trigger 'docker:container:request:start', target

    render: ->
      vagrant = @state.vagrant.toJSON()
      if status[vagrant.state]?
        vagrant.state = status[vagrant.state]()
      if vagrant.state == 'Running'
        vagrant.duration = moment.unix(vagrant.timestamp).fromNow true
      else
        vagrant.duration = '-'

      @$topBar.render {
        status: vagrant
        config: @state.config.toJSON()
      }, @topBarDirectives

      if vagrant.state != 'Running'
        @$el.find('[href=#toggle]').hide()
        @$consulIcon.hide()
      else
        @$el.find('[href=#toggle]').show()
        @$consulIcon.show()

      @renderContainers()

      @$el.find('[data-toggle="tooltip"]').tooltip()

      if @timer is null
        # Update the status every 10 seconds
        @timer = setInterval () =>
          @render()
        , 10000

    renderContainers: ->
      collection = @state.config.get 'containers'
      containers = []
      for container in collection.models
        value = container.toJSON()
        if value.visible
          created = @state.containers.getByName value.name
          if created?
            state = created.get 'State'
            if state.get 'Running'
              value.status = status['running']()
              startTime = state.get 'StartedAt'
              start = moment startTime
              value.uptime = start.fromNow true
            else
              value.status = status['stopped']()
              value.uptime = '-'
            ns = created.get 'NetworkSettings'
            value.ipaddr = ns.get 'IPAddress'
          else
            value.ipaddr = '-'
            value.status = status['uncreated']()
            value.uptime = '-'

          value.ports = (port: port.host for port in value.ports)
          if value.enabled or value.required
            containers.push value

      sortedContainers = _.sortBy containers, (item) ->
        item.name

      if sortedContainers.length > 0
        @$containers.render sortedContainers, @containerDirectives
        @$containers.show()
        #@$containers.find('[data-toggle="tooltip"]').tooltip()
      else
        @$containers.hide()

  Overview
