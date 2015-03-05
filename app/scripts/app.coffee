'use strict'

###*
 # @ngdoc overview
 # @name edudashApp
 # @description
 # # edudashApp
 #
 # Main module of the application.
###
angular
  .module('edudashApp', [
    'ngAnimate',
    'ngAria',
    'ngCookies',
    'ngMessages',
    'ngResource',
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'ui.select'
  ])
  .config ($routeProvider, uiSelectConfig) ->
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
      .when '/about',
        templateUrl: 'views/about.html'
        controller: 'AboutCtrl'
      .when '/dashboard/:type',
        templateUrl: 'views/dashboard.html'
        controller: 'DashboardCtrl'
      .when '/data',
        templateUrl: 'views/data.html'
        controller: 'DataCtrl'
      .when '/speakout',
        templateUrl: 'views/speakout.html'
        controller: 'SpeakoutCtrl'
      .when '/brn',
        templateUrl: 'views/brn.html'
        controller: 'BrnCtrl'
      .otherwise
        redirectTo: '/'
    uiSelectConfig.theme = 'bootstrap';

