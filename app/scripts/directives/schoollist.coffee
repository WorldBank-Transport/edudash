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
      listTitle: '@title'
      listType: '@type'
      type: '@data'
      listData: '=data'
      setSchool: '=click'
      property: '@property'
      max: '@max'+0
      min: '@min'+0
      sufix: '@sufix'
    link: (scope, element, attrs) ->
