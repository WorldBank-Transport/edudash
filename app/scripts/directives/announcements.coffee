'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.announcements
 # @description
 # # Announcements bar
 # showing the latest news/updates
###
angular.module('edudashAppDir').directive 'announcements', ->
  restrict: 'E',
  templateUrl: 'views/announcements.html',
  controller: ['$scope', 'announcements', ($scope, announcements) ->
    announcements (message) -> $scope.message = message
  ]
