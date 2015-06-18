'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:mapFlyoutSchool
 # @description
 # # mapFlyoutSchool
###
angular.module 'edudashApp'
  .directive 'mapFlyoutSchool', ->
    restrict: 'EA'
    templateUrl: 'views/mapflyoutschool.html'
    link: (scope, element, attrs) ->