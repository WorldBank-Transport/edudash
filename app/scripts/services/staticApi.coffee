'use strict'

###*
 # @ngdoc service
 # @name edudashApp.OpenDataApi
 # @description
 # # OpenDataApi
 # Service in the edudashApp.
###
angular.module('edudashAppSrv').service 'staticApi', ($http, $q, topojson) ->
  getData = (url) ->
    $q (resolve, reject) -> ($http.get url).then ((resp) -> resolve resp.data), reject

  getRegions: ->
    getData '/layers/tz_regions.json'
      .then (topo) ->
        {features} = topojson.feature topo, topo.objects.tz_Regions
        $q.when features.map (feature) ->
          type: feature.type
          id: feature.properties.name.toUpperCase()
          geometry: feature.geometry

  getDistricts: ->
    getData '/layers/tz_districts.json'
      .then (topo) ->
        {features} = topojson.feature topo, topo.objects.tz_districts
        $q.when features.map (feature) ->
          type: feature.type
          id: feature.properties.name.toUpperCase()
          geometry: feature.geometry
