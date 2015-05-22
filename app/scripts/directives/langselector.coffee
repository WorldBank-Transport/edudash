'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:langSelector
 # @description
 # # langSelector
###
angular.module('i18nEdudashApp', [
  'ngCookies',
  'ngMessages',
  'ngResource',
  'pascalprecht.translate'])

  .directive('langSelector', [
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
  ])
  .config ($translateProvider) ->
    $translateProvider.useStaticFilesLoader(
      prefix: 'scripts/i18n/locale_'
      suffix: '.json'
    )
    $translateProvider.preferredLanguage('en');
    $translateProvider.useSanitizeValueStrategy('escaped');

