'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:SpeakoutCtrl
 # @description
 # # SpeakoutCtrl
 # Controller of the edudashApp
###
angular.module('edudashApp')
  .controller 'SpeakoutCtrl', ($scope) ->
    $scope.awesomeThings = [
      'HTML5 Boilerplate'
      'AngularJS'
      'Karma'
    ]
