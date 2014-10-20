define (require, exports, module) ->

  Model      = require 'model'

  Containers = require 'cs!collections/config/containers'
  Docker     = require 'cs!models/config/docker'
  Etcd       = require 'cs!models/config/etcd'
  Vagrant    = require 'cs!models/config/vagrant'

  Config = Model.extend

    defaults:
      containers: Containers
      docker: Docker
      etcd: Etcd
      password: null
      vagrant: Vagrant

  Config
