define (require, exports, module) ->

  borderHeight = ($el) ->
    _verticalHeight('border', $el)

  marginHeight = ($el) ->
    _verticalHeight('margin', $el)

  paddingHeight = ($el) ->
    _verticalHeight('padding', $el)

  _verticalHeight = (type, $el) ->
    bottom = parseInt $el.css("#{type}-bottom").replace 'px', ''
    top = parseInt $el.css("#{type}-top").replace 'px', ''
    bottom + top

  {
    borderHeight: borderHeight
    marginHeight: marginHeight
    paddingHeight: paddingHeight
  }
