define (require, exports, module) ->

  Model = require 'model'

  Folder = Model.extend

    idAttribute: 'name'

    defaults:
      mount:   null
      name:    null
      nfs:     true
      options: 'nolock,vers=3,udp'

  Folder
