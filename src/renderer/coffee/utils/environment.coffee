define (require, exports, module) ->

  # Return the id componet of the URI query string
  #
  # @return [String] the id
  _id = ->
    regex = new RegExp "[\\\?&]id=([^&#]*)"
    results = regex.exec document.location.search
    if results?
      decodeURIComponent results[1].replace /\+/g, " "
    else
      'Unknown'

  # Return the path componet of the URI query string
  #
  # @return [String] the environment path
  _path = ->
    regex = /[\\?&]path=([^&#]*)/
    results = regex.exec document.location.search
    if results?
      decodeURIComponent results[1].replace /\+/g, " "
    else
      'Unknown'

  # Return the materialized id and path as attributes
  {path: _path(), id: _id()}
