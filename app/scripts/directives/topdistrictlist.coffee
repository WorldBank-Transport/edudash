'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:topDistrictList
 # @description
 # # topDistrictList
###
angular.module 'edudashAppDir'
  .directive 'topDistrictList', ->
    restrict: 'E'
    templateUrl: 'views/topdistrictlist.html'
    transclude: true
    scope:
      districtListTile: '@'
      districtListTileEmoticon: '@'
      tdlData: '=data'
      setMapView: '=click'
    link: (scope, element, attrs) ->
      scope.districtListTile = attrs.title
      scope.districtListTileEmoticon = attrs.emoticon
      scope.type = attrs.data