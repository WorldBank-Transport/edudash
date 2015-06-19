'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:yearSelector
 # @description
 # # yearSelector
###
angular.module 'edudashApp'
  .directive 'yearSelector', ->
    restrict: 'EA'
    templateUrl: 'views/yearselector.html'
    link: (scope, element, attrs) ->

