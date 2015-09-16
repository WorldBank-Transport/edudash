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
        selected: '=datasource'
      }
      link: (scope, element, attrs) ->
        scope.getTimes = (n) ->
          if scope.selected? and scope.selected['PUPIL_TEACHER_RATIO']? then new Array(n)
        scope.getClass = (index, value) ->
          sex = if index % 2 == 0 then 'boy' else 'girl'
          color = switch
            when bracketsSrv.getBracket(value, 'PUPIL_TEACHER_RATIO') == 'POOR' then 'red'
            when bracketsSrv.getBracket(value, 'PUPIL_TEACHER_RATIO') == 'MEDIUM' then 'yellow'
            when bracketsSrv.getBracket(value, 'PUPIL_TEACHER_RATIO') == 'GOOD' then 'green'
          "#{sex}-#{color}"
