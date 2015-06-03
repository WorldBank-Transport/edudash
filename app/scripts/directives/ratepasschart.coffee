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
      link: (scope, element, attrs) ->
        max = attrs.max
        min = attrs.min
        update = () ->
          if scope.selectedSchool? then element.show() else element.hide()
          pass = scope.selectedSchool.pass_by_10
          if pass >= max
            src = 'images/passrate_student_green.png'
            textClass = 'text-gree'
          else if pass >= min and pass < max
            src = 'images/passrate_student_yellow.png';
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