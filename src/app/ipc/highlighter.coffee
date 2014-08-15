hljs = require 'highlight.js'

Listener = require './base'


# Syntax highligher listener processes requests by highlighting them with hljs
#
class Highlighter extends Listener

  events:
    'highlight': 'highlight'

  highlight: (event, code, callback) ->
    event.sender.send callback, hljs.highlightAuto(code).value

if not instance?
  instance = new Highlighter

module.exports = instance
