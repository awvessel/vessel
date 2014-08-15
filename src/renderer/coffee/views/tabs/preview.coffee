define (require, exports, module) ->

  $        = require 'jquery'
  Backbone = require 'backbone'

  ipc      = require 'cs!utils/ipc'
  size     = require 'cs!utils/size'

  template     = require 'html!tabs/preview'

  Preview = Backbone.View.extend

    initialize: ->
      # Append the template
      @$el.html template
      @$el.find('.tab-content').css 'height': '100%'
      @$el.find('div.panel-body').css 'height': '100%'

      @$cloudconfig = @$el.find '#cloud-config > pre > code'
      @$vagrantfile = @$el.find '#Vagrantfile > pre > code'
      Backbone.on 'application:ready', () =>
        @listenTo @model, 'change', (attr) =>
          @render()

    render: ->
      url = @model.get('etcd').get 'url'
      ipc.send 'cloudconfig:generate', null, url, true, (value) =>
        ipc.send 'highlight', value, (html) =>
          @$cloudconfig.html html
      ipc.send 'vagrantfile:generate', @model.toJSON(), null, true, (value) =>
        ipc.send 'highlight', value, (html) =>
          @$vagrantfile.html html

  Preview
