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

    addCartodbLayer: (id, url, subLayer, mapId) ->

      if not cartodbLayers[mapId]?
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
]
