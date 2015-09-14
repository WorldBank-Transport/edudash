'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:educationSelector
 # @description
 # # educationSelector
###
angular.module 'edudashApp'
  .directive 'educationSelector', ($routeParams, $location, $log) ->
    restrict: 'EA'
    templateUrl: 'views/educationselector.html'
    link: (scope, element, attrs) ->
      scope.setSchoolType = (newType) ->
        $location.path "/dashboard/#{newType}/"
      scope.$routeParams = $routeParams
