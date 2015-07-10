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
          new Array(parseInt(n))

  ]