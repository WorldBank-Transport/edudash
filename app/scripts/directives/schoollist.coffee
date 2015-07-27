'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:schoolList
 # @description
 # # schoolList
###
angular.module 'edudashApp'
  .directive 'schoolList', ->
    restrict: 'E'
    templateUrl: 'views/schoollist.html'
    scope:
      listTitle: '@listTitle'
      listType: '@type'
      schools: '=schools'
      click: '=click'
      hover: '=hover'
      unHover: '=unHover'
      property: '@property'
      max: '=max'
      min: '=min'
      sufix: '@sufix'
