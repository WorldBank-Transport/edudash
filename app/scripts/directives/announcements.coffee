angular.module('edudashApp').directive 'announcements', ->
  restrict: 'E',
  templateUrl: 'views/announcements.html',
  controller: ['$scope', 'announceService', ($scope, announceService) ->
    announceService (message) -> $scope.message = message
  ]
