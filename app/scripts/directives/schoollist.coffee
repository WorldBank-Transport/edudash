'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:schoolList
 # @description
 # # schoolList
###
angular.module 'edudashApp'
  .directive 'schoolList', (loadingSrv) ->
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
      max: '=max'
      min: '=min'
      sufix: '@sufix'
    link: (scope, el, attrs) ->
      scope.schools = []
      scope.$watch 'dataset', (p) -> if p?
        p.then (schools) -> scope.schools = schools
        loadingSrv.containerLoad p, el[0]
