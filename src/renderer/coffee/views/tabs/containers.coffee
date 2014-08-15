define (require, exports, module) ->

  _            = require 'underscore'
  $            = require 'jquery'
  i18n         = require 'i18n'
  Backbone     = require 'backbone'
  Transparency = require 'transparency'

  strings      = require 'strings!containers'
  template     = require 'html!tabs/containers'

  Containers = Backbone.View.extend

    tooltipped: false

    events:
      'change select':             'onSelectChange'
      'click a[href="#checkbox"]': 'onContainerToggle'
      'click a[href="#clone"]':    'onCloneToggle'

    directives:

      enabled:
        disabled: () ->
          if @required
            true
          else
            false
        html: () ->
          if @required
            '<i class="fa fa-check-square-o text-muted disabled"></i>'
          else if @enabled
            '<i class="fa fa-check-square-o"></i>'
          else
            '<i class="fa fa-square-o"></i>'
        'data-value': (el) ->
          @enabled

      icon:
        class: (el) ->
          if @icon
            if @icon[0..1] is 'fa'
              "fa #{@icon}"
            else
              "ossicon ossicon-#{@icon}"
          else
            "fa fa-cube"
        html: (el) ->
          ''

      name:
        class: (el) ->
          if @required
            'text-muted'
        html: (el) ->
          if @required
            "#{@name} [#{strings['required']()}]"
          else
            @name

      repository:
        single:
          class: () ->
            if @url?
              if @branches.length isnt 1
                'hidden'
              else if not @enabled
                'text-muted'
            else
              'hidden'
          text: () ->
            if @url?
              @branch
        branches:
          'data-value': () ->
            @branch
          branch:
            text: () ->
              @value
            value: () ->
              @value
          class: () ->
            if @branches.length is 1
              'hidden'
        clone:
          class: () ->
            if @url?
              if @enabled
                'btn btn-success btn-xs'
              else
                'btn btn-muted btn-xs'
            else
              'hidden'
          'data-value': () ->
            @enabled
          'data-original-title': () ->
            if @url?
              if @enabled
                strings['disable-git-clone']()
              else
                strings['enable-git-clone']()

        'data-value': () ->
          @branch

      target:
        value: () ->
          @name

    initialize: ->
      # Append the template
      @$el.html i18n.processStrings strings, template

      # Keep track of the two areas where we render data to
      @$applications = $ '#s-applications'
      @$lowLevel = $ '#s-low-level'

      # Listen for a generic event to re-render to prevent delays
      @listenTo @collection, 'change', (model) =>
        @render()

    render: ->
      containers = @_getContainersForRendering()
      apps = (r for r in containers when r.category isnt 'Low-Level')
      lowLevel = (r for r in containers when r.category is 'Low-Level')

      @$applications.render apps, @directives
      @$lowLevel.render lowLevel, @directives

      # Toggle the git clone buttons based upon the state of the container
      $disable = @$el.find 'a[href="#checkbox"][data-value="false"]'
      $disabled = $disable.parents 'tr'
      $disabled.find('a[href="#clone"]').addClass 'hidden'

      # Remove the disabled attribute from clone enabled selects
      $enable = @$el.find 'a[href="#checkbox"][data-value="true"]'
      $enabled = $enable.parents 'tr'
      $cloneDisabled = $enabled.find 'a[href="#clone"][data-value="false"]'
      $cloneDisabled.parents('tr').find('select').attr 'disabled', 'disabled'
      $cloneEnabled = $enabled.find 'a[href="#clone"][data-value="true"]'
      $cloneEnabled.parents('tr').find('select').removeAttr 'disabled'

      # Render the select picker for visible select boxes
      $pickers = @$el.find('select.selectpicker')
      $pickers.selectpicker
        style: 'btn btn-default btn-xs'
        size: 5
      $pickers.selectpicker 'refresh'

      if not @tooltipped
        @$el.find('[data-toggle="tooltip"]').tooltip placement: 'left'
        @tooltipped = true

    # Toggle the enabled state of a repository clone
    onCloneToggle: (e) ->
      e.preventDefault()
      $target = $(e.currentTarget)
      Backbone.trigger 'container:repository:toggle'
      , @_container($target), $target.attr('data-value') is 'false'

    # Toggle the enabled state of a container when it's checked
    onContainerToggle: (e) ->
      e.preventDefault()
      $target = $(e.currentTarget)
      Backbone.trigger 'container:toggle'
      , @_container($target), $target.attr('data-value') is 'false'

    # Set the branch on the container model when the select dropdown changes
    onSelectChange: (e) ->
      $select = $ e.currentTarget
      branch = $select.siblings().find('button:first-child').attr 'title'
      container = @collection.findWhere
        name: @_container($select)
      container.set branch: branch

    # Return the name of the container for the specified anchor tag
    _container: ($a) ->
      $a.parents('tr').val()

    # Return a renderable list of Containers from the collection
    _getContainersForRendering: ->
      containers = []
      for obj, index in @collection.models
        container = _.clone obj.attributes
        for own key, value of container
          if key == 'repository'
            repo = _.clone value.attributes
            if repo?
              branches =  ['master'].concat _.without repo.branches, 'master'
              container[key] =
                enabled: repo.enabled
                url: repo.url
                name: repo.name
                branch: repo.branch
                branches: ({branch: b} for b in branches)
            else
              branch = null
              branches = []
              enabled = false
              name = null
              url = null
            break
        if container.visible is true
          containers.push container
      containers

    _showFilter: (id, el) ->
      $(el).children().length > 1

  Containers
