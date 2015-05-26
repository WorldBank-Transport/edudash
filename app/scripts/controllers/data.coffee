'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:DataCtrl
 # @description
 # # DataCtrl
 # Controller of the edudashApp
###
angular.module('edudashAppCtrl')
  .controller 'DataCtrl', ($scope) ->
    $scope.awesomeThings = [
      'HTML5 Boilerplate'
      'AngularJS'
      'Karma'
    ]
