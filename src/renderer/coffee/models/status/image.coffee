define (require, exports, module) ->

  Model = require 'model'

  Image = Model.extend

    idAttribute: 'Id'

    defaults:
      Id: null
      Created: null
      ParentId: null
      RepoTags: []
      Size: null
      VirtualSize: null
