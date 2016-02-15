'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:topDistrictList
 # @description
 # # topDistrictList
###
angular.module 'edudashAppDir'
  .directive 'topDistrictList', (loadingSrv, bracketsSrv) ->
    restrict: 'E'
    templateUrl: 'views/topdistrictlist.html'
    scope:
      districtListTile: '@title'
      districtListTileEmoticon: '@emoticon'
      order: '@order'
      type: '@type'
      data: '=data'
      selectPoly: '=selectPoly'
      hover: '=hover'
      unHover: '=unHover'
    link: (scope, element, attrs) ->
      debugger
      scope.$watch 'data', (p) ->
        if p?
          p.then (polygons) ->
            if(polygons[scope.order]?)
              scope.polygons = polygons[scope.order]
          loadingSrv.containerLoad p, element[0]
        else
          scope.polygons = null
