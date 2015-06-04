'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.mapBottomToggle
 # @description
 # # Map bottom toggle
 # Controls at the bottom of the map
###
angular.module('edudashAppDir').directive 'mapBottomToggle', ->
  restrict: 'E',
  scope: {},
  templateUrl: 'views/mapBottomToggle.html',
  transclude: true,
  link: (scope, element, attrs) ->
    scope.closed = true
    scope.toggle = ->
      scope.closed = !scope.closed
