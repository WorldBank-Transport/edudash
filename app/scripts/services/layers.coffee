'use strict'

###*
 # @ngdoc service
 # @name edudashApp.layers
 # @description
 # # Map layers service
 # Provides an injectable API for controlling the map's appearance
###


angular.module('edudashApp').factory 'layersSrv', [
  'leafletData', 'cartodb', 'L', '$q',
  (leafletData, cartodb, L, $q) ->

    layers = {}

    cartodbLayers = {}

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

    addCartodbLayer: (id, url, subLayer, mapId) ->
      unless cartodbLayers[mapId]?
        cartodbLayers[mapId] = {}

      unless layers[id]?
        layers[id] = $q (resolve, reject) ->

          leafletData.getMap(mapId).then (map) ->
            unless cartodbLayers[mapId][url]?
              cartodbLayers[mapId][url] = $q (resolve, reject) ->
                cartodb.createLayer map, url, layerIndex: 1
                  .addTo map
                  .done (layer) ->
                    layer.setInteraction true
                    resolve layer  # cartodbLayers inner resolve

            layerPromise = cartodbLayers[mapId][url]

            resolve  # layers outer resolve
              show: () -> layerPromise.then (layer) ->
                layer.addTo map
                layer.getSubLayer(subLayer).show()
              hide: () -> layerPromise.then (layer) ->
                layer.getSubLayer(subLayer).hide()
              raw: layerPromise

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
]
