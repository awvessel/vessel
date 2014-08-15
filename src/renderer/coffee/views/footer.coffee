define (require, exports, module) ->

  Backbone    = require 'backbone'
  i18n        = require 'i18n'

  environment = require 'cs!utils/environment'

  strings     = require 'strings!footer'
  template    = require 'html!footer'

  Footer = Backbone.View.extend

    events:
      'click #build':    'onBuildClick'
      'click #outdated': 'onOutdatedClick'
      'click #power':    'onPowerClick'
      'click #ssh':      'onSSHClick'

    initialize: ->
      @$el.html i18n.processStrings(strings, template)

      @state = arguments[0].state

      @$buildButton = @$el.find('#build')
      @$outdatedButton = @$el.find('#outdated')
      @$powerButton = @$el.find("#power")
      @$powerButtonLabel = @$powerButton.find('span')
      @$sshButton = @$el.find("#ssh")

      @listenTo Backbone, 'footer:buttons:toggle'
      , (build, outdated, power, isUp) ->
        @_toggleButtons build, outdated, power, isUp

    onBuildClick: (e) ->
      e.preventDefault()
      @$buildButton.blur()
      @$buildButton.prop('disabled', true)
      Backbone.trigger 'environment:build:request'

    onOutdatedClick: (e) ->
      e.preventDefault()
      @$outdatedButton.blur()
      @$outdatedButton.prop('disabled', true)
      Backbone.trigger 'vagrant:request:update'

    onPowerClick: (e) ->
      @$powerButton.blur()
      switch @$powerButton.attr 'data-state'
        when 'true'
          Backbone.trigger 'vagrant:request:halt'
        else
          Backbone.trigger 'vagrant:request:up'

    onSSHClick: (e) ->
      e.preventDefault()
      @$sshButton.blur()
      Backbone.trigger 'vagrant:ssh'

    _toggleButtons: (build, outdated, power, isUp) ->
      @_toggleBuild build
      @_toggleOutdated outdated
      @_togglePower power, isUp

    _toggleBuild: (enable) ->
      @$buildButton.prop('disabled', not enable)
      if enable
        @$buildButton.addClass 'btn-primary'
      else
        @$buildButton.removeClass 'btn-primary'

    _toggleOutdated: (enable) ->
      switch enable
        when true
          @$outdatedButton.removeClass('hidden').show()
        when false
          @$outdatedButton.hide()

    _togglePower: (enable, isUp) ->
      @$powerButton.prop('disabled', not enable)
      @$sshButton.prop('disabled', not isUp)
      value = if isUp is false then 'on' else 'off'
      @$powerButtonLabel.text strings[value]()
      @$powerButton.attr('data-state', isUp)
      switch enable
        when true
          switch value
            when 'on'
              @$powerButton.addClass 'btn-success'
              @$powerButton.removeClass 'btn-danger'
              @$sshButton.removeClass 'btn-secondary'
            else
              @$powerButton.addClass 'btn-danger'
              @$powerButton.removeClass 'btn-success'
              @$sshButton.addClass 'btn-secondary'
        when false
          @$powerButton.removeClass 'btn-danger'
          @$powerButton.removeClass 'btn-success'

  Footer
