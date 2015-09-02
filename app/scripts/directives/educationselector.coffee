'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:educationSelector
 # @description
 # # educationSelector
###
angular.module 'edudashApp'
  .directive 'educationSelector', [
    '$routeParams', '$location'

    ($routeParams, $location) ->
      restrict: 'EA'
      templateUrl: 'views/educationselector.html'
      link: (scope, element, attrs) ->
        angular.extend scope,
          setSchoolType: (newType) ->
            scope.eduSel = newType
            $location.path "/dashboard/#{newType}/"
          eduSel: $routeParams.type

  ]

