define (require, exports, module) ->

  Backbone     = require 'backbone'
  i18n         = require 'i18n'

  strings      = require 'strings!vagrant'
  template     = require 'html!tabs/vagrant'


  Vagrant = Backbone.View.extend

    directives:
      providers:
        name:
          text: (el) ->
            "#{@name} URL"
        url:
          'data-id': (el) ->
            @name

    events:
      'change #vagrant-settings input':  'onInputChange'
      'change #vagrant-settings select': 'onSelectChange'
      'blur #synced-folder input':       'onSFInputBlur'

    initialize: ->
      @$el.html i18n.processStrings(strings, template)

      @$sfName = @$el.find '#sf-name'
      @$sfMount = @$el.find '#sf-mount'
      @$sfOptions = @$el.find '#sf-options'
      @$sfButton = @$el.find '#synced-folder button'

      @listenTo @model, 'change', (model) =>
        @render()

    render: ->
      @$el.render @model.toJSON(), @directives
      @$el.find('select').selectpicker()
      @$el.find('[data-bind="provider"]')
      .selectpicker('val', @model.get('provider'))

    onValueChange: ($el) ->
      id = $el.attr('data-id')
      name = $el.attr('data-bind')
      target = $el.attr('data-target')
      value = $el[0].value

      # If there is a data-target attribute, it's a model or collection
      if target? and @model.has target
        console.log "Setting #{target}.#{name}"
        targetObj = @model.get target
        targetObj.set name, value

      else if @model.has name
        @model.set name, value

    onInputChange: (e) ->
      @onValueChange $(e.currentTarget)

    onSelectChange: (e) ->
      @onValueChange $(e.currentTarget)

    onSFInputBlur: (e) ->
      if @$sfName.val() and @$sfMount.val()
        @$sfButton.removeClass 'disabled'
      else
        @$sfButton.addClass 'disabled'

  Vagrant
