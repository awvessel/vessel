define (require, exports, module) ->

  Model = require 'model'
  SSHKey = require 'cs!models/config/sshkey.coffee'

  SSH = Model.extend

    defaults:
      key:       SSHKey

  SSH
