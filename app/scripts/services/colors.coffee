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
      when 'GOOD' then '#49ab30'
      when 'MEDIUM' then '#ffd328'
      when 'POOR' then '#ee5e52'
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
      fillOpacity: 0.96
      opacity: 0.95
      weight: 1
    if colour?
      style.fillColor = colour
    style

  pinOn: ->
    opacity: 1
    weight: 2

  polygonOff: (colour) ->
    style =
      color: '#ffffff'
      fillOpacity: 0.84
      opacity: 0.6
      weight: 2
    if colour?
      style.fillColor = colour
    style

  polygonOn: ->
    color: '#ffffff'
    fillOpacity: 0.9
    opacity: 1
    weight: 6

  polygonSelect: ->
    color: '#ffffff'
    fill: false
    opacity: 1
    weight: 7
