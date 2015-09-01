'use strict'

###*
 # @ngdoc service
 # @name edudashApp.layers
 # @description
 # # Map layers service
 # Provides an injectable API for controlling the map's appearance
###


angular.module('edudashAppSrv').factory 'layersSrv',
  (leafletData, L, $q) ->

    makeLayer = (create) -> (layerArgs) -> $q.when create layerArgs

    scopeToLayer: ($scope, mapId) ->
      (name) ->
        $scope.$watch name, (layer, oldLayer) ->
          leafletData.getMap(mapId).then (map) ->
            if oldLayer?
              $q.when(oldLayer).then (layer) ->
                map.removeLayer layer
            if layer?
              $q.when(layer).then (layer) ->
                map.addLayer layer

    getTileLayer: makeLayer (args) -> L.tileLayer args.url, args

    getGeojsonLayer: makeLayer (args) ->
      $q (resolve) -> args.getData().then (geoData) ->
        resolve L.geoJson geoData, args.options or {}

    getFastCircles: makeLayer (args) ->
      $q (resolve) -> args.getData().then (data) ->
        resolve L.fastCircles data, args.options

    marker: makeLayer (args) -> L.marker args.latlng, args.options

    awesomeIcon: (options) -> L.AwesomeMarkers.icon options
