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
      }
      link: (scope, element, attrs) ->
        max = attrs.max
        min = attrs.min
        scope.getTimes = (n) ->
          new Array(n)
        update = () ->
          if scope.selectedSchool? and scope.selectedSchool['pt_ratio']? then element.show() else element.hide()
          ptRatio = scope.selectedSchool['pt_ratio']
          if ptRatio <= min
            src = 'images/passrate_student_yellow.png'
            textClass = 'text-green'
          else if ptRatio > min and ptRatio < max
            src = 'images/passrate_student_green.png';
            textClass = 'text-yellow'
          else
            src = 'images/passrate_student_red.png';
            textClass = 'text-red'

          element.find('.imageStudent').attr('src', src)
          element.find('.percentNumber').attr('class', "percentNumber widgetnumber #{textClass}")

        scope.$watch 'selectedSchool', (newValue, oldValue) ->
          update()

        update()

  ]