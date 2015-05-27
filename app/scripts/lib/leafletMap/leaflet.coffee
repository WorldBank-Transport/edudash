'use strict'

###*
 # @ngdoc service
 # @name edudashApp.L
 # @description
 # # L
 # Factory in the edudashApp.
###
angular.module('leafletMap')
    .factory 'L', ->
        window.L
