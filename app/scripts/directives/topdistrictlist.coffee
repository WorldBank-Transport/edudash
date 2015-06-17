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
      districtListTile: '@title'
      districtListTileEmoticon: '@emoticon'
      type: '@data'
      tdlData: '=data'
      setMapView: '=click'
    link: (scope, element, attrs) ->
