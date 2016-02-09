'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:ShareCtrl
 # @description
 # # ShareCtrl
 # Controller of the edudashApp
###
angular.module('edudashAppCtrl')
  .controller 'ShareCtrl', ($location, $routeParams, $scope, shareSrv) ->
    shareSrv.get($routeParams.shareId).then (url) ->
      $location.path url