'use strict'

###*
 # @ngdoc service
 # @name edudashApp.layers
 # @description
 # # Map layers service
 # Provides an injectable API for controlling the map's appearance
###


angular.module('edudashAppSrv').factory 'layersSrv', [
  'leafletData', 'L', '$q',
  (leafletData, L, $q) ->

    layers = {}

    addTileLayer: (id, url, mapId) ->
      unless layers[id]?
        layers[id] = $q (resolve, reject) ->
          leafletData.getMap(mapId).then (map) ->
            layer = L.tileLayer url
            layer.addTo map
            resolve
              show: -> map.addLayer layer
              hide: -> map.removeLayer layer
              raw: layer
      layers[id]

    addGeojsonLayer: (id, dataPromise, options, mapId) ->
      unless layers[id]?
        layers[id] = $q (resolve, reject) ->
          leafletData.getMap(mapId).then (map) ->
            dataPromise.then (geojsonData) ->
              layer = L.geoJson geojsonData, options
              resolve
                show: -> map.addLayer layer
                hide: -> map.removeLayer layer
                raw: layer
      layers[id]

    marker: (id, latlng, options, mapId) ->
      unless layers[id]?
        layers[id] = $q (resolve, reject) ->
          leafletData.getMap(mapId).then (map) ->
            layer = L.marker latlng, options
            resolve
              show: () -> map.addLayer layer
              hide: () -> map.removeLayer layer
              setLatLng: layer.setLatLng
              raw: layer
      layers[id]

    awesomeIcon: (options) -> L.AwesomeMarkers.icon options
]
