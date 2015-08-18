'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:ratePassChart
 # @description
 # # ratePassChart
###
angular.module 'edudashAppDir'
.directive 'ratePassChart', [
    '$log'
    ($log) ->
      restrict: 'E'
      templateUrl: 'views/ratepasschart.html'
      scope:
        max: '@max'
        min: '@min'
        selectedSchool: '=datasource'
        selectedYear: '@selectedyear'
      link: (scope, element, attrs) ->
        scope.getTimes = (n) ->
          if n? then new Array(parseInt(n)) else Array(0)
        scope.getClass = (index, value, max, min) ->
          sex = if index % 2 == 0 then 'boy' else 'girl'
          color = switch
            when value <= min then 'red'
            when value >= max then 'green'
            else 'yellow'
          "#{sex}-pass-#{color}"

  ]