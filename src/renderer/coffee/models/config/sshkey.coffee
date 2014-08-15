define (require, exports, module) ->

  Model = require 'model'

  SSHKey = Model.extend

    defaults:
      private: null
      public: null

  SSHKey
