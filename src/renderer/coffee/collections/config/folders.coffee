define (require, exports, module) ->

  Backbone = require 'backbone'
  Folder   = require 'cs!models/config/folder'

  Folders = Backbone.Collection.extend

    model: Folder

  Folders
