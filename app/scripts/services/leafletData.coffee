'use strict'


angular.module('edudashApp').factory 'leafletData', ['$q', ($q) ->
  maps = {}

  ensureInit = (id) ->
    if not maps[id]?
      maps[id] = defer: $q.defer()

  this.setMap = (map, id) ->
    ensureInit id
    if maps[id].isSet
      throw new Error 'Map already set for id', id
    maps[id].isSet = true
    maps[id].defer.resolve map

  this.getMap = (id) ->
    ensureInit id
    maps[id].defer.promise

  this.unsetMap = (id) ->
    delete maps[id]

  this
]