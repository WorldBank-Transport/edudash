'use strict'

###*
 # @ngdoc service
 # @name edudashApp.WorldBankApi
 # @description
 # # WorldBankApi
 # Service in the edudashApp.
###
angular.module('edudashAppSrv').service 'bracketsSrv', ->

  bracket =
    GOOD: _: 'GOOD'
    MEDIUM: _: 'MEDIUM'
    POOR: _: 'POOR'
    UNKNOWN: _: 'UNKNOWN'

  bracket: bracket


  colour: (brace) ->
    switch brace
      when bracket.GOOD then '#38a21c'
      when bracket.MEDIUM then '#e9c941'
      when bracket.POOR then '#f56053'
      when bracket.UNKNOWN then '#aaa'
      else throw new Error "Unknown bracket: '#{brace}'"


  getBracket: (val, metric) ->
    unless typeof val == 'number'
      throw new Error "val must be a number. Got: '#{val}' which is '#{typeof val}'"
    if isNaN val
      bracket.UNKNOWN
    else
      switch metric

        when 'AVG_MARK' then switch
          when 0 <= val < 40 then bracket.POOR
          when 40 <= val <= 60 then bracket.MEDIUM
          when 60 < val <= 100 then bracket.GOOD
          else bracket.UNKNOWN

        when 'AVG_GPA' then switch
          when 1 <= val <= 3 then bracket.POOR
          when 3 < val <= 4.2 then bracket.MEDIUM
          when 4.2 < val <= 5 then bracket.GOOD  # what's the upper limit?
          else bracket.UNKNOWN

        when 'CHANGE_PREVIOUS_YEAR', 'CHANGE_PREVIOUS_YEAR_GPA' then switch
          when val < 0 then bracket.POOR
          when val == 0 then bracket.MEDIUM
          when val > 0 then bracket.GOOD
          # `when`s are exhaustive: tested typeof === number and !isNaN

        else throw new Error "Unknown metric: '#{metric}'"


  getMetric: (schoolType, criteria) ->
    unless schoolType in ['primary', 'secondary']
      throw new Error "Unknown school type '#{schoolType}'"
    unless criteria in ['performance', 'improvement']
      throw new Error "Unknown criteria '#{criteria}'"
    switch schoolType
      when 'primary' then switch criteria
        when 'performance' then 'AVG_MARK'
        when 'improvement' then 'CHANGE_PREVIOUS_YEAR'
      when 'secondary' then switch criteria
        when 'performance' then 'AVG_GPA'
        when 'improvement' then 'CHANGE_PREVIOUS_YEAR_GPA'
