'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:schoolList
 # @description
 # # schoolList
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
      bracketer: '@'
      missing: '@'
    link: (scope, el, attrs) ->
      el.addClass 'stat'
      scope.getBracket = bracketsSrv.getBracket
