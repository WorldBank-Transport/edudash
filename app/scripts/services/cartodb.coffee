'use strict'

###*
 # @ngdoc service
 # @name edudashApp.cartodb
 # @description
 # # cartodb
 # Factory in the edudashApp.
###
angular.module('edudashApp')
    .factory 'cartodb', ->
        window.cartodb
