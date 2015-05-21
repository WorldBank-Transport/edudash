'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:langSelector
 # @description
 # # langSelector
###
angular.module 'edudashApp'
  .directive 'langSelector', [
    "$log", "$translate"
    ($log, $translate) ->
      restrict: 'E'
      templateUrl: 'views/langselector.html'
      link: (scope, element, attrs) ->
        scope.langList = [
          {
            lang: 'en'
            label: 'English'
          }
          {
            lang: 'es-ar'
            label: 'Español'
          }
          {
            lang: 'sw-tz'
            label: 'Kiswahili'
          }
        ]
        scope.changeLanguage = (key) ->
          $log.debug 'lang selected: ' + key
          $translate.use(key)
  ]