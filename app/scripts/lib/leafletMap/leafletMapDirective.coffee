'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.map
 # @description
 # # Announcements bar
 # showing the latest news/updates
###
angular.module('leafletMap').directive 'leafletMap', [
  'leafletData', 'L', '$q',
  (leafletData, L, $q) ->
    _leafletMap = null  # empty ref shared by controller and link

    restrict: 'A'

    replace: true

    scope: {}  # isolate scope

    controller: ->
      _leafletMap = $q.defer()
      this.getMap = -> _leafletMap.promise

    link: (scope, element, attrs) ->
      map = L.map element[0]
      _leafletMap.resolve map

      leafletData.setMap map, attrs.id

      scope.$on '$destroy', ->
        map.eachLayer (layer) ->
          map.removeLayer layer
        map.eachLayer (l) -> map.removeLayer l
        map.remove()
        leafletData.unsetMap attrs.id
]
