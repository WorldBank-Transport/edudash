'use strict'

###*
 # @ngdoc service
 # @name edudashApp.OpenDataApi
 # @description
 # # OpenDataApi
 # Service in the edudashApp.
###
angular.module('edudashAppSrv').service 'staticApi', ($http, $q) ->
  getData = (url) ->
    $q (resolve, reject) -> ($http.get url).then ((resp) -> resolve resp.data), reject

  getRegions: -> getData '/layers/tz_regions.json'
