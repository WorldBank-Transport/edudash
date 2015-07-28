'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:rank
 # @description
 # # rank
###
angular.module 'edudashAppDir'
  .directive 'rank', ->
    restrict: 'EA'
    templateUrl: 'views/rank.html'
    scope:
      data: '=datasource'
      title: '@title'
