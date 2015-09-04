'use strict'

###*
 # @ngdoc service
 # @name edudashApp.WorldBankApi
 # @description
 # # WorldBankApi
 # Service in the edudashApp.
###
angular.module('edudashAppSrv').service 'colorSrv', ->

  color: (brace) ->
    switch brace
      when 'GOOD' then '#80c671'
      when 'MEDIUM' then '#e9c941'
      when 'POOR' then '#f56053'
      when 'UNKNOWN' then '#aaa'
      else throw new Error "Unknown bracket: '#{brace}'"

  arrow: (brace) ->
    switch brace
      when 'GOOD' then 'images/arrowgreen.png'
      when 'MEDIUM' then 'images/arrowyellow.png'
      when 'POOR' then 'images/arrowred.png'
      when 'UNKNOWN' then undefined
      else  throw new Error "Unknown bracket: '#{brace}'"

  pinOff: (colour) ->
    style =
      color: '#fff'
      fillOpacity: 1
      opacity: 0.75
      weight: 3
    if colour?
      style.fillColor = colour
    style

  pinOn: ->
    color: '#05a2dc'
    opacity: 1
    weight: 6

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
    color: '#05a2dc'
    fillOpacity: 0.9
    opacity: 1
    weight: 6

  polygonSelect: ->
    color: '#000'
    fill: false
    opacity: 1
    weight: 7
