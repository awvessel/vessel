define (require, exports, module) ->

  _        = require 'underscore'
  i18n     = require 'i18n'
  moment   = require 'moment'
  Backbone = require 'backbone'

  ipc      = require 'cs!utils/ipc'
  size     = require 'cs!utils/size'

  strings  = require 'strings!logs'
  status   = require 'strings!status'
  template = require 'html!tabs/logs'

  Logs = Backbone.View.extend

    ignore: [
      'auth:password'
      'log:debug'
      'log:error'
      'log:info'
      'vagrant:log'
    ]

    maxEntries: 1000
    directives:
      events:
        when:
          text: (el) ->
            @when.format('HH:mm:ss')
      statuses:
        when:
          text: (el) ->
            @when.format('HH:mm:ss')
      vagrantLogs:
        when:
          text: (el) ->
            @when.format('HH:mm:ss')

    initialize: ->
      # Append the template
      @$el.html i18n.processStrings(strings, template)
      @$panel = null

      @statuses = []
      @events = []
      @vlogs = []
      @timeout = null

      @listenTo Backbone, 'all', (event, payload, args...) =>
        timestamp = moment()
        if event is 'application:status'
          @statuses.unshift when: timestamp, message: status[payload](args...)
        else if _.isString(payload) and payload.indexOf('[vagrant]') is 0
          for message in payload.split '\n'
            message = @_cleanup(message)
            if message
              @vlogs.unshift when: timestamp, message: message
              Backbone.trigger 'vagrant:log', message
        else if event not in @ignore
          @events.unshift when: timestamp, message: event
        if @timeout is null
          @timeout = setTimeout () =>
            @render()
          , 1000

    _cleanup: (message) ->
      message = message.replace '[vagrant]', ''
      matches = message.match /\s+==\>\s+[a-z\-]+\:/g
      if matches?
        for match in matches
          message = message.replace /\s+==\>\s+[a-z\-]+\:/, ''
      message = message.replace /^\s+[a-z\-]+\:/, ''
      message.trim()
      matches = message.match /\'([\w\s\-\.]+)\'/g
      if matches?
        for match in matches
          message = message.replace /\'([\w\s\-\.]+)\'/
          , "<code>$1</code>"
      matches = message.match /\`([\w\s\-]+)\`/g
      if matches?
        for match in matches
          message = message.replace /\`([\w\s\-]+)\`/, " <kbd>$1</kbd> "
      matches = message.match /^\-\- (\d+)\s=\>\s(\d+)/
      if matches
        value = strings['port-forward'] from: matches[1], to: matches[2]
        message = message.replace /^\-\- (\d+)\s=\>\s(\d+)/, value
      message.trim()

    render: ->
      @timeout = null
      if not @$panel?
        @$panel = @$el.find '.tab-content'
        @$panel.css 'height': '100%'
        @$panel.find('div').css 'height': '100%'

      @$panel.render {
        events: @events
        statuses: @statuses
        vagrantLogs: @vlogs
      }, @directives

  Logs
