'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:schoolList
 # @description
 # # schoolList
###
angular.module 'edudashApp'
  .directive 'schoolList', (loadingSrv, bracketsSrv) ->
    restrict: 'E'
    templateUrl: 'views/schoollist.html'
    scope:
      listTitle: '@listTitle'
      listType: '@type'
      dataset: '=dataset'
      click: '=click'
      hover: '=hover'
      unHover: '=unHover'
      property: '@property'
      limit: '=limit'
      sufix: '@sufix'
    link: (scope, el, attrs) ->
      scope.schools = null
      scope.$watch 'dataset', (p) ->
        if p?
          p.then (schools) -> scope.schools = schools.slice 0, scope.limit
          loadingSrv.containerLoad p, el[0]
        else
          scope.schools = null

      scope.getStyle = (val, prop) ->
        switch bracketsSrv.getBracket val, prop
          when 'GOOD' then 'passrategreen'
          when 'MEDIUM' then 'passrateyellow'
          when 'POOR' then 'passratered'
          when 'UNKNOWN' then '#aaa'
          else throw new Error "Unknown bracket: '#{brace}'"
