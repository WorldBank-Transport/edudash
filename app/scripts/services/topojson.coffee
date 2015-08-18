'use strict'

###*
 # @ngdoc service
 # @name edudashApp.topojson
 # @description
 # # Topojson
 # Get a reference to the topojson tool
###
angular.module 'edudashAppSrv'
  .factory 'topojson', ($window) -> $window.topojson or {}
