define (require, exports, module) ->

  Model = require 'model'

  Etcd = Model.extend

    defaults:
      url: null

  Etcd
