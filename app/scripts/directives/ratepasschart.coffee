'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:ratePassChart
 # @description
 # # ratePassChart
###
angular.module 'edudashAppDir'
.directive 'ratePassChart', ($log, bracketsSrv) ->
      restrict: 'E'
      templateUrl: 'views/ratepasschart.html'
      scope:
        passRate: '=datasource'
      link: (scope, element, attrs) ->
        scope.getTimes = (n) ->
          if n? and n == n then new Array(parseInt(n)) else Array(0)
        scope.getClass = (index, value) ->
          sex = if index % 2 == 0 then 'boy' else 'girl'
          color = switch
            when bracketsSrv.getBracket(value, 'PASS_RATE') == 'POOR' then 'red'
            when bracketsSrv.getBracket(value, 'PASS_RATE') == 'MEDIUM' then 'yellow'
            when bracketsSrv.getBracket(value, 'PASS_RATE') == 'GOOD' then 'green'
          "#{sex}-pass-#{color}"