'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:flyoutNumbver
 # @description
 # # Mark up numbers for flyouts
###
angular.module 'edudashApp'
  .directive 'flyoutNumber', (bracketsSrv, $log) ->
    restrict: 'E'
    templateUrl: 'views/flyout-number.html'
    scope:
      name: '@'
      value: '='
      present: '='
      suffix: '@'
      suffixclass: '@'
      bracketer: '@'
    link: (scope, el, attrs) ->
      el.addClass 'stat'
      scope.getBracket = bracketsSrv.getBracket
