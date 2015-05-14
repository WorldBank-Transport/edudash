angular.module('edudashApp').controller 'announcements', [
  '$scope',
  ($scope) ->
    $scope.message = 'hello'
]
angular.module('edudashApp').directive 'announcements', ->
  restrict: 'E',
  templateUrl: 'views/announcements.html'
