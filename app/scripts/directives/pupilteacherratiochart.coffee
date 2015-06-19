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
        if scope.selectedSchool? and scope.selectedSchool['pt_ratio']? then element.show() else element.hide()
        scope.getTimes = (n) ->
          if scope.selectedSchool? and scope.selectedSchool['pt_ratio']? then new Array(n) else 0

  ]