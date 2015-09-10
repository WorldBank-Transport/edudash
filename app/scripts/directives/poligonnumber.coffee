'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:poligonNumber
 # @description
 # # poligonNumber
###
angular.module 'edudashApp'
  .directive 'poligonNumber', ->
    restrict: 'EA'
    templateUrl: 'views/poligon-number.html'
    scope:
      name: '@'
      value: '='
      image: '@'
    link: (scope, element, attrs) ->

