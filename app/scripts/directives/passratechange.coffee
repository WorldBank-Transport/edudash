'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:passRateChange
 # @description
 # # passRateChange
###
angular.module 'edudashAppDir'
  .directive 'passRateChange', ['bracketsSrv', (bracketsSrv)->
    restrict: 'EA'
    templateUrl: 'views/ratepasschange.html'
    scope:
      data: '=datasource'
      range: '@'
      max: '=max'
      min: '=min'
      since: '=since'
    link: (scope, element, attrs) ->
      scope.getStyle = (value) ->
        switch value
          when bracketsSrv.getBracket(value, 'CHANGE_PREVIOUS_YEAR') == 'POOR' then 'text-red'
          when bracketsSrv.getBracket(value, 'CHANGE_PREVIOUS_YEAR') == 'MEDIUM' then 'text-yellow'
          when bracketsSrv.getBracket(value, 'CHANGE_PREVIOUS_YEAR') == 'GOOD' then 'text-green'
      scope.$watch 'data', (newValue, oldValue) ->
        if newValue
          updateChart(newValue)
      updateChart = (data) ->
        scope.sign = switch
          when data > 0 then '+ '
          when data == 0 then '= '
          else ''
  ]