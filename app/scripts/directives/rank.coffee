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
      rank: '=datasource'
      title: '@title'
      place: '@place'
