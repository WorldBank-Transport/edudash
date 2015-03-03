'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:BrnCtrl
 # @description
 # # BrnCtrl
 # Controller of the edudashApp
###
angular.module('edudashApp')
  .controller 'BrnCtrl', ($scope) ->
    $scope.awesomeThings = [
      'HTML5 Boilerplate'
      'AngularJS'
      'Karma'
    ]
