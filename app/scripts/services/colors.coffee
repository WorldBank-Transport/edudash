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

    colors:
      unknown: '#aaa'
      poor: '#f56053'
      medium: '#e9c941'
      good: '#38a21c'

    categorize: (val, mode, schoolType) ->
      switch
        when mode == 'passrate' then switch schoolType
          when 'primary' then switch
            when val == null then 'unknown'
            when val < 40 then 'poor'
            when val < 60 then 'medium'
            else 'good'
          when 'secondary' then switch
            when val == null then 'unknown'
            when val > 4.2 then 'poor'
            when val > 3 then 'medium'
            else 'good'
        when mode == 'ptratio' then switch
          when val == null then 'unknown'
          when val < 35 then 'good'
          when val > 50 then 'poor'
          else 'medium'

    colorize: (val, mode, type) ->
      this.colors[this.categorize val, mode, type]

    pinStyle: (val, mode, schoolType) ->
      color: '#fff'
      fillOpacity: 0.75
      fillColor: this.colorize val, mode, schoolType

    areaStyle: (val, mode, schoolType) ->
      weight: 2
      color: '#fff'
      fillColor: this.colorize val, mode, schoolType
      fillOpacity: 0.75
