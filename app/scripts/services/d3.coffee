'use strict'

###*
 # @ngdoc service
 # @name edudashApp.d3
 # @description
 # # d3
 # Factory in the edudashApp.
###
angular.module('edudashAppSrv')
  .factory 'd3', ($window) -> $window.d3 or {}
