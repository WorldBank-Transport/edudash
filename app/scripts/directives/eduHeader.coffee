'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.eduHeader
 # @description
 # # Top Nav
 # the title and navigation links at the top
###
angular.module('edudashAppDir').directive 'eduHeader', ->
  restrict: 'E',
  templateUrl: 'views/eduHeader.html',
  link: (scope, element, attrs) ->
    setTimeout( () ->
      scope.showPointInfo=true
      scope.$digest()
    , 5000)
    setTimeout( () ->
      scope.showPointInfo=false
      scope.$digest()
    , 20000)
