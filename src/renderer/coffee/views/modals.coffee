define (require, exports, module) ->

  shell    = nodeRequire 'shell'

  $        = require 'jquery'
  Backbone = require 'backbone'
  i18n     = require 'i18n'
  moment   = require 'moment'

  ipc      = require 'cs!utils/ipc'
  size     = require 'cs!utils/size'

  errors   = require 'strings!errors'
  status   = require 'strings!status'
  strings  = require 'strings!modals'
  template = require 'html!modals'


  Modals = Backbone.View.extend

    events:
      'click #auth-dialog .btn-primary':           'onAuthenticate'
      'click #auth-dialog [data-dismiss="modal"]': 'onAuthCancelled'

    initialize: ->
      @$el.html i18n.processStrings(strings, template)

      @$errorDialog   = @$el.find '#error-dialog'
      @$tabContent    = @$el.find '.tab-content'
      @$statusDialog  = @$el.find '#status-dialog'
      @$sdLogs        = @$statusDialog.find '#status-logs'
      @$sdLogEntries  = @$statusDialog.find '#status-log-entries'
      @$sdProgress    = @$statusDialog.find '.progress'
      @$sdProgressBar = @$sdProgress.find '.progress-bar'
      @$sdTimer       = @$statusDialog.find '#state-timer'
      @$sdBarValue    = @$sdProgress.find '.sr-only'
      @sdBarStep      = 0
      @sdBarSteps     = 0
      @$authDialog    = @$el.find '#auth-dialog'
      @$authAlert     = @$el.find '.alert'

      @$statusDialog.modal backdrop: 'static', keyboard: false, show: false

      @_bindListenEvents()

      @timerStart = moment()
      @interval = null

      ipc.send 'username:fetch', (username) =>
        @username = username
        @render()

    onAuthenticate: (e) ->
      e.preventDefault()
      $password = @$authDialog.find '#password'
      @$authDialog.prop 'disabled', true
      ipc.send 'password:validate', $password.val(), (response) =>
        if response
          @$authDialog.modal 'hide'
          Backbone.trigger 'auth:password', $password.val()
        else
          @$authAlert.removeClass 'hidden'
          $password.focus().select()
        @$authDialog.prop 'disabled', false

    onAuthCancelled: (e) ->
      Backbone.trigger 'modal:dialog:auth:cancelled'

    render: ->
      @$authDialog.render username: @username

    _bindListenEvents: ->

      @listenTo Backbone, 'error', (message, args) =>
        @_errorDialogShow message, args

      @listenTo Backbone, 'modal:error:show', (message) =>
        @_errorDialogShow message

      @listenTo Backbone, 'modal:dialog:auth:show', () =>
        @_authDialogShow()

      @listenTo Backbone, 'modal:status:hide', () =>
        @_statusDialogHide()

      @listenTo Backbone, 'modal:status:hideLogs', () =>
        @$sdLogs.hide()
        @_centerDialog @$statusDialog

      @listenTo Backbone, 'modal:status:show'
      , (value, progress, reset, logs) =>
        @_statusDialogShow value, progress, reset, logs

      @listenTo Backbone, 'modal:status:steps', (value) =>
        @sdBarStep = 0
        @sdBarSteps = value
        @_statusDialogProgress 0

      @listenTo Backbone, 'modal:status:step', () =>
        @sdBarStep++
        @_statusDialogProgress ((100 / @sdBarSteps) * @sdBarStep)

      @listenTo Backbone, 'application:status', (value, values) =>
        if status[value]?
          value = status[value](values)
        @$statusDialog.render status: value

      @listenTo Backbone, 'vagrant:log', (message) =>
        @$sdLogEntries.append "#{message}<br>"
        @$sdLogs.scrollTop(@$sdLogs[0].scrollHeight)

    _authDialogShow: () ->
      @$authDialog.modal 'show'
      @$authDialog.find('#password').focus()

    _centerDialog: ($modal) ->
      $dlg = $modal.find '.modal-dialog'
      $dlg.css 'padding-top', 0
      $dlg.css 'margin-top', (($(document).height()/ 2) - ($dlg.height()/2))

    _errorDialogShow: (error, args) ->
      if not args?
        args =
          messsage: ''
      if errors[error]?
        message = errors[error](args)
      @$errorDialog.render error: message, message: args.message
      @$errorDialog.modal 'show'
      @_centerDialog @$errorDialog
      shell.beep()

    _statusDialogHide: ->
      @_statusDialogTimerStop()
      @$statusDialog.modal 'hide'
      @$sdTimer.hide()

    _statusDialogProgress: (percent) ->
      @$sdProgressBar.attr 'aria-valuenow', "#{percent}%"
      @$sdProgressBar.css 'width', "#{percent}%"
      @$sdBarValue.text strings['percentComplete']({percent: percent})

    _statusDialogShow: (value, progress, resetTimer, logs) ->
      switch progress
        when true
          @_statusDialogProgress 0
          @$sdProgress.removeClass 'hidden'
        when false
          @$sdProgress.addClass 'hidden'
      if resetTimer
        @timerStart = moment()

      if status[value]?
        value = status[value]()

      if logs? and logs
        @$sdLogEntries.html ''
        @$sdLogs.show()
      else
        @$sdLogs.hide()

      @_statusDialogTimerStart()
      @$statusDialog.render status: value
      @$statusDialog.modal 'show'
      @_centerDialog @$statusDialog

    _statusDialogTimerStart: ->
      @$sdTimer.text ''
      @$sdTimer.show()
      @interval = setInterval ()=>
        seconds = moment().unix() - @timerStart.unix()
        @$sdTimer.text status['seconds'] duration: seconds
      , 1000

    _statusDialogTimerStop: ->
      if @interval?
        clearInterval @interval
        @interval = null

  Modals
