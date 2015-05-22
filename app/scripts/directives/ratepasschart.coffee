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
            imageClass = 'passrategreen'
            textClass = 'text-gree'
          else if pass >= min and pass < max
            imageClass = 'passrateyellow';
            textClass = 'text-yellow'
          else
            imageClass = 'passratered';
            textClass = 'text-red'

          element.find('.passrate').attr('class', "passrate #{imageClass}")
          element.find('.passrategrey').attr('style', "height: #{40-4*pass}px")
          element.find('.percentNumber').attr('class', "percentNumber widgetnumber #{textClass}")

        scope.$watch 'selectedSchool', (newValue, oldValue) ->
          update()

        update()

  ]