'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:passRateChange
 # @description
 # # passRateChange
###
angular.module 'edudashAppDir'
  .directive 'passRateChange', ->
    restrict: 'EA'
    templateUrl: 'views/ratepasschange.html'
    scope:
      data: '=datasource'
      range: '@'
    link: (scope, element, attrs) ->
      scope.sign = switch
        when scope.data > 0 then '+ '
        when scope.data == 0 then '= '
        else ''
      scope.range = attrs.range.split(',')
      scope.since = 2012