'use strict'

###*
 # @ngdoc service
 # @name edudashApp.layers
 # @description
 # # Map layers service
 # Provides an injectable API for controlling the map's appearance
###


angular.module('edudashAppSrv').factory 'layersSrv',
  (leafletData, L, $q, utils) ->

    layers = {}

    makeLayer = ({create, update}) -> (id, mapId, layerArgs) ->
      unless layers[id]?
        layers[id] = $q (resolve, reject) ->
          leafletData.getMap(mapId).then (map) ->
            $q.when create layerArgs
              .then (layer) ->
                layer.addTo map
                resolve layer
      else
        $q.all
          map: leafletData.getMap mapId
          layer: layers[id]
        .then ({map, layer}) ->
          unless map.hasLayer layer
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
              # hack like above but for fast-circles
              if parent._group?
                resetChildren parent._group
            ) layer
            map.addLayer layer

          # let layers update themselves, possibly with updated data
          if update?
            $q.when update layer, layerArgs
              .then (newLayer) ->
                if newLayer? and newLayer != layer
                  layers[id] = $q.when newLayer
                  map.removeLayer layer
                  newLayer.addTo map

      layers[id]

    addTileLayer: makeLayer
      create: (args) -> L.tileLayer args.url, args

    addGeojsonLayer: makeLayer
      create: (args) -> args.getData().then (geoData) ->
        L.geoJson geoData, args.options or {}

    addFastCircles: makeLayer
      create: (args) -> args.getData().then (data) ->
        L.fastCircles data, args.options
      update: utils.debounce 250, (layer, args) ->
        args.getData().then (data) ->
          L.fastCircles data, args.options

    marker: makeLayer
      create: (args) -> L.marker args.latlng, args.options

    awesomeIcon: (options) -> L.AwesomeMarkers.icon options
