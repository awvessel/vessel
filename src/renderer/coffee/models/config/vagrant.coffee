define (require, exports, module) ->

  Model     = require 'model'

  Folders   = require 'cs!collections/config/folders'
  Network   = require 'cs!models/config/network'
  Ports     = require 'cs!collections/config/ports'
  Providers = require 'cs!collections/config/providers'

  Vagrant = Model.extend

    defaults:
      box:            'vessel'
      cpu_count:      2
      gui:            false
      hostname:       'vessel'
      network:        Network
      provider:       null
      providers:      Providers
      ram:            2048
      synced_folders: Folders
      ports:          Ports

  Vagrant
