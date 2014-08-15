# Main application that kicks off the router and does global configuration

define (require, exports, module) ->

  Logger          = require 'cs!utils/logger'

  ipc             = nodeRequire 'ipc'

  $               = require 'jquery'
  Backbone        = require 'backbone'
  Bootstrap       = require 'bootstrap'
  BootstrapSelect = require 'bootstrap-select'
  Transparency    = require 'transparency'

  environment     = require 'cs!utils/environment'

  Configuration   = require 'cs!listeners/config'
  Build           = require 'cs!listeners/build'
  Docker          = require 'cs!listeners/docker'
  State           = require 'cs!listeners/state'
  Vagrant         = require 'cs!listeners/vagrant'

  ContentView     = require 'cs!views/content'
  FooterView      = require 'cs!views/footer'

  # Redefine transparency's matcher to only match data-bind elements
  Transparency.matcher = (element, key) ->
    bind = element.el.getAttribute 'data-bind'
    bind == key

  # Attach transparency's jQuery plugin to $
  $.fn.render = Transparency.jQueryPlugin

  # Main application coordinates the startup behavior, holds instances of
  # the main application listener objects, and starts up the primary views.
  #
  class App

    constructor: ->
      # Object that manages the configuration state
      @config = new Configuration

      # Load the event listeners for building, docker and vagrant
      @build = new Build config: @config
      @docker = new Docker config: @config
      @vagrant = new Vagrant config: @config

      # New state management listener
      @state = new State {
        build: @build
        config: @config
        docker: @docker
        vagrant: @vagrant
      }

      # Create and render the main content and footer views
      @content = new ContentView {
        el: $('#content')
        config: @config,
        state: @state
      }

      @footer = new FooterView {
        el: $('footer')
        state: @state
      }

      # Trigger the modal window
      Backbone.trigger 'modal:status:show', 'Initializing', false

      # Show the main window
      ipc.sendSync "window:show:#{environment.id}"

      # Load the config
      @config.load()

  App
