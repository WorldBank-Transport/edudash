'use strict'

###*
 # @ngdoc service
 # @name edudashApp.WorldBankApi
 # @description
 # # WorldBankApi
 # Service in the edudashApp.
###
angular.module 'edudashAppSrv'
  .service 'colorSrv', ->

    pinOff: (colour) ->
      style =
        color: '#fff'
        fillOpacity: 0.75
        opacity: 0.6
        weight: 2
      if colour?
        style.fillColor = colour
      style

    pinOn: ->
      color: '#05a2dc'
      fillOpacity: 1
      opacity: 1
      weight: 5

    polygonOff: (colour) ->
      style =
        color: '#fff'
        fillOpacity: 0.75
        opacity: 0.6
        weight: 2
      if colour?
        style.fillColor = colour
      style

    polygonOn: ->
      weight: 6
      opacity: 1
      fillOpacity: 0.9
