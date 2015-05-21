'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.map
 # @description
 # # Announcements bar
 # showing the latest news/updates
###
angular.module('edudashApp').directive 'map', [
  'WorldBankApi', 'L', 'cartodb'
  (WorldBankApi, L, cartodb) ->
    restrict: 'A'
    template: 'hello'

    scope:
      map: '='
      layers: '='
      schoolType: '='
      showLayer: '='

    link: (scope, element, attrs) ->
      scope.map = L.map element[0],
        center: [-7.199, 34.1894],
        zoom: 6

      # add the basemap layer 0
      cartodb.createLayer scope.map, WorldBankApi.getLayer(scope.schoolType), layerIndex: 0
        .addTo scope.map
        .done (basemap) -> scope.layers[0] = basemap

      # add the layer 1 for schoold
      cartodb.createLayer scope.map, WorldBankApi.getLayer(scope.schoolType), layerIndex: 1
        .addTo scope.map
        .done (layer) ->
          scope.layers[1] = layer
          scope.layers[1].setInteraction(true)
          scope.layers[1].on 'featureClick', (e, pos, latlng, data) ->
            if scope.activeMap == 3
              scope.setMapView(pos, 9, 0)
            else
              WorldBankApi.getSchooldByCartoDb(scope.schoolType , data.cartodb_id).success (data) ->
                scope.setSchool data.rows[0]
          scope.layers[1].on 'mouseover', () ->
            $('.leaflet-container').css('cursor', 'pointer')
          scope.layers[1].on 'mouseout', () ->
            $('.leaflet-container').css('cursor', '-webkit-grab')
            $('.leaflet-container').css('cursor', '-moz-grab')
          scope.showLayer 0
]
