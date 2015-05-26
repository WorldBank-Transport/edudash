'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the edudashApp
###
angular.module('edudashAppCtrl')
  .controller 'MainCtrl', ($scope) ->
    $scope.awesomeThings = [
      'HTML5 Boilerplate'
      'AngularJS'
      'Karma'
    ]
