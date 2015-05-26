'use strict'

###*
 # @ngdoc service
 # @name edudashApp.cartodb
 # @description
 # # cartodb
 # Factory in the edudashApp.
###
angular.module('edudashAppSrv')
    .factory 'cartodb', ->
        window.cartodb
