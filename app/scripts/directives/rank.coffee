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
    link: (scope, element, attrs) ->
#      scope.$watch attrs.datasource, (newValue, oldValue) ->
#        if newValue
#          update(newValue)
#      update = (data) ->
#        scope.sign = switch
#          when data > 0 then '+ '
#          when data == 0 then '= '
#          else ''
#        scope.since = 2012
