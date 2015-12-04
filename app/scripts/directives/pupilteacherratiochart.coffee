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
        value: '=datasource'
        present: '='
      }
      link: (scope, element, attrs) ->
        scope.getTimes = (n) ->
          if scope.value? then new Array(Math.round(n))
        scope.getClass = (index, value) ->
          sex = if index % 2 == 0 then 'boy' else 'girl'
          color = switch
            when bracketsSrv.getBracket(value, 'PUPIL_TEACHER_RATIO') == 'POOR' then 'red'
            when bracketsSrv.getBracket(value, 'PUPIL_TEACHER_RATIO') == 'MEDIUM' then 'yellow'
            when bracketsSrv.getBracket(value, 'PUPIL_TEACHER_RATIO') == 'GOOD' then 'green'
          "#{sex}-#{color}"
