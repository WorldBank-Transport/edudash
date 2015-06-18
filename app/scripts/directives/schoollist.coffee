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
      listTitleEmoticon: '@emoticon'
      type: '@data'
      listData: '=data'
      setSchool: '=click'
      property: '@property'
    link: (scope, element, attrs) ->
