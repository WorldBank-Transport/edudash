'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:AboutCtrl
 # @description
 # # AboutCtrl
 # Controller of the edudashApp
###
angular.module('edudashAppCtrl')
  .controller 'AboutCtrl', ($scope) ->
    $scope.awesomeThings = [
      'HTML5 Boilerplate'
      'AngularJS'
      'Karma'
    ]
