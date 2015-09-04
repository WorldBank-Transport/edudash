'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:ratePassChart
 # @description
 # # ratePassChart
###
angular.module 'edudashAppDir'
.directive 'pupilTeacherRatioChart', ($log, bracketsSrv) ->
      restrict: 'E'
      templateUrl: 'views/pupilteacherratiochart.html'
      scope: {
        selectedSchool: '=datasource'
      }
      link: (scope, element, attrs) ->
        scope.getTimes = (n) ->
          if scope.selectedSchool? and scope.selectedSchool['PUPIL_TEACHER_RATIO']? then new Array(parseInt(n)) else 0
        scope.getClass = (index, value) ->
          sex = if index % 2 == 0 then 'boy' else 'girl'
          color = switch
            when bracketsSrv.getBracket(value, 'PUPIL_TEACHER_RATIO') == 'POOR' then 'red'
            when bracketsSrv.getBracket(value, 'PUPIL_TEACHER_RATIO') == 'MEDIUM' then 'yellow'
            when bracketsSrv.getBracket(value, 'PUPIL_TEACHER_RATIO') == 'GOOD' then 'green'
          "#{sex}-#{color}"
