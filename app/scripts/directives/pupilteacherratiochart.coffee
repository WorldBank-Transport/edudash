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
          if scope.selectedSchool? and scope.selectedSchool['PUPIL_TEACHER_RATIO']? then new Array(parseInt(n)) else 0
        scope.getClass = (index, value, max, min) ->
          sex = if index % 2 == 0 then 'boy' else 'girl'
          color = switch
            when parseInt(value) <= parseInt(min) then 'yellow'
            when parseInt(value) >= parseInt(max) then 'red'
            else 'green'
          "#{sex}-#{color}"

  ]