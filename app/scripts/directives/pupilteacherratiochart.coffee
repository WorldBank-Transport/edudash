'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:ratePassChart
 # @description
 # # ratePassChart
###
angular.module 'edudashAppDir'
.directive 'pupilTeacherRatioChart', [
    '$log'
    ($log) ->
      restrict: 'E'
      templateUrl: 'views/pupilteacherratiochart.html'
      scope: {
        selectedSchool: '=datasource'
        max: '@max'
        min: '@min'
      }
      link: (scope, element, attrs) ->
        scope.getTimes = (n) ->
          new Array(n)

  ]