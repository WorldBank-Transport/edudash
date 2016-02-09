'use strict'

###*
 # @ngdoc overview
 # @name edudashAppCtrl
 # @description
 # # edudashAppCtrl
 #
 # Main module of the application.
###
angular
  .module('edudashAppCtrl', [
    'ngAnimate',
    'ngAria',
    'ngCookies',
    'ngMessages',
    'ngResource',
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'ui.select',
    'ui-rangeSlider'
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
      .when '/share/:shareId',
        templateUrl: 'views/main.html'
        controller: 'ShareCtrl'
      .when '/dashboard/:type/morethan40/:morethan40',
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

