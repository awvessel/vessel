define (require, exports, module) ->

  $           = require 'jquery'
  Backbone    = require 'backbone'
  i18n        = require 'i18n'

  environment = require 'cs!utils/environment'
  size        = require 'cs!utils/size'

  Containers  = require 'cs!views/tabs/containers'
  Logs        = require 'cs!views/tabs/logs'
  Modals      = require 'cs!views/modals'
  Overview    = require 'cs!views/tabs/overview'
  Preview     = require 'cs!views/tabs/preview'
  Vagrant     = require 'cs!views/tabs/vagrant'

  strings     = require 'strings!content'
  template    = require 'html!content'

  Content = Backbone.View.extend

    initialize: ->
      @$el.html i18n.processStrings strings, template
      document.title = strings['title'] path: environment.path
      @config = arguments[0].config
      @state = arguments[0].state

      @containers = new Containers {
        el: @$el.find '#containers'
        collection: @config.containers
      }

      @logs = new Logs {
        el: @$el.find '#logs'
      }

      @modals = new Modals el: @$el.find '.modals'
      @modals.render()

      @overview = new Overview {
        el: @$el.find '#overview'
        model: @config.model
        state: @state
      }

      @preview = new Preview {
        el: @$el.find '#preview'
        model: @config.model
      }

      @vagrant = new Vagrant {
        el: @$el.find('#vagrant')
        model: @config.vagrant
      }

      @listenToOnce Backbone, 'render:ui', (event) =>
        @render()

    render: ->
      # Set the height of the containers
      @containers.render()
      @logs.render()
      @overview.render()
      @preview.render()
      @vagrant.render()

      @$el.find('.nav-tabs.hidden').removeClass 'hidden'
      $content = @$el.find('#content-panes')
      $content.removeClass 'hidden'
      $content.children('.tab-pane').height 465
      $('footer').removeClass 'hidden'

  Content
