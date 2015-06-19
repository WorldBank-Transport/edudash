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

    makeLayer = (createLayer) -> (id, mapId, layerArgs) ->
      unless layers[id]?
        layers[id] = $q (resolve, reject) ->
          leafletData.getMap(mapId).then (map) ->
            $q.when createLayer layerArgs
              .then (layer) ->
                layer.addTo map
                resolve layer
      else
        $q.all
          map: leafletData.getMap mapId
          layer: layers[id]
        .then (p) ->
          unless p.map.hasLayer p.layer
            # hack around bad leaflet layers init bug
            # Without this, adding a geoJson layer with paths, then removing it,
            # and then adding it to a different map (eg. load Primary Schools,
            # go to Secondary Schools, then go back to Primary Schools) makes
            # leaflet explode because it does not reinitialize the child layers
            # because leaflet is awful.
            (resetChildren = (parent) ->
              if parent.eachLayer?
                parent.eachLayer (child) ->
                  delete child._container
                  resetChildren child
            ) p.layer
            p.map.addLayer p.layer
      layers[id]

    addTileLayer: makeLayer (url) -> L.tileLayer url

    addGeojsonLayer: makeLayer (args) ->
      args.getData().then (geoData) ->
        L.geoJson geoData, args.options or {}

    marker: makeLayer (args) ->
      L.marker args.latlng, args.options

    awesomeIcon: (options) -> L.AwesomeMarkers.icon options
]
