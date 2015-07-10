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

    categorizers =
      passrate: [
        [((v) -> (v == null)), 'unknown']
        [((v) -> v < 40), 'poor']
        [((v) -> v < 60), 'medium']
        [(-> true), 'good']
      ]
      ptratio: [
        [((v) -> v == null), 'unknown']
        [((v) -> v < 35), 'good']
        [((v) -> v > 50), 'poor']
        [(-> true), 'medium']
      ]

    colors:
      unknown: '#aaa'
      poor: '#f56053'
      medium: '#e9c941'
      good: '#38a21c'

    categorize: (val, mode) ->
      category = undefined
      categorizers[mode].forEach (catPair) ->
        category = category or \
          if (catPair[0] val) then catPair[1] else undefined
      category

    colorize: (val, mode) ->
      this.colors[this.categorize val, mode]

    pinStyle: (val, mode) ->
      category = this.categorize val, mode
      colour = this.colorize val, mode
      if category == 'unknown'
        color: colour
        fillOpacity: 0
      else
        color: '#fff'
        fillOpacity: 0.75
        fillColor: colour

    areaStyle: (val, mode) ->
      weight: 2
      color: '#fff'
      fillColor: this.colorize val, mode
      fillOpacity: 0.75
