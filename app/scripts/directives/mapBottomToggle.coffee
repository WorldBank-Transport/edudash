'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.mapBottomToggle
 # @description
 # # Map bottom toggle
 # Controls at the bottom of the map
 #
 # The classes are manipulated directly, instead of via ng-class directives, so that
 # we can compute the on-screen dimensions to propagate via an event
###
angular.module('edudashAppDir').directive 'mapBottomToggle', ->
  restrict: 'E'
  scope:
    title: '@'
    emitkey: '@'
  templateUrl: 'views/mapBottomToggle.html'
  transclude: true
  link: (scope, element, attrs) ->
    element.addClass 'closed'
    scope.toggle = ->
      element.toggleClass 'closed'
      if scope.emitkey?
        scope.$emit scope.emitkey, height: element.height() + 1
