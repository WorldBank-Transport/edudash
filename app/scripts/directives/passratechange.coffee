'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:passRateChange
 # @description
 # # passRateChange
###
angular.module 'edudashAppDir'
  .directive 'passRateChange', ->
    restrict: 'EA'
    templateUrl: 'views/ratepasschange.html'
    scope:
      data: '=datasource'
      range: '@'
      max: '=max'
      min: '=min'
    link: (scope, element, attrs) ->
      scope.$watch 'data', (newValue, oldValue) ->
        if newValue
          updateChart(newValue)
      updateChart = (data) ->
        scope.sign = switch
          when data > 0 then '+ '
          when data == 0 then '= '
          else ''
        scope.since = 2012