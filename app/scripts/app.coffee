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
    'ui.select',
    'ui-rangeSlider',
    'pascalprecht.translate'
  ])
  .config ($routeProvider, uiSelectConfig, $translateProvider) ->
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
      .when '/showdata',
        templateUrl: 'views/showdata.html'
        controller: 'ShowdataCtrl'
      .otherwise
        redirectTo: '/'
    uiSelectConfig.theme = 'bootstrap';

    $translateProvider.translations('en', {
      'TITLE': 'Hello',
      'FOO': 'This is a paragraph',
      'dashboard.title': 'Education Dashboard'
      'menu.home': 'Home'
      'menu.dashboard': 'Dashboards'
      'menu.primary': 'Primary'
      'menu.secondary': 'Secondary'
      'menu.data': 'Data'
      'menu.speakout': 'Speak out'
      'menu.showdata': 'Show Data'
      'tab.school': 'School'
      'tab.best-worst-performance': 'Best & Worst Perfomance'
      'tab.best-worst': 'Best & Worst'
      'tab.best-worst-improvements': 'Best & Worst Improvements'
      'tab.improvements': 'Improvements'
      'tab.districts': 'Districts'
      'map.filter': 'Map filters'
      'map.legend': 'Legend'
      'passrate-perc':'Passrate (%):'
      'chart.dial-title': 'Change since 2012'
      'chart.details': 'Click for details'
      'chart.pupil-teacher-ration': 'Pupil-teacher ratio'
      'chart.average-pass-rate': 'Average pass rate'
      'school.selector-tooltip': 'Search school by name or code'
      'school.center-code': 'center code'
      'school.district': 'district'
      'chart.top.best-performing': 'Best performing districts'
      'chart.top.worst-performing': 'Worst performing districts'
      'chart.top.most-improved': 'Most improved districts'
      'chart.top.least-improved': 'Least improved districts'
      'chart.top.most-improved-schools': 'Most improved schools'
      'chart.top.least-improved-schools': 'Least improved schools'
      'chart.top.best-performing-schools': 'Best performing schools'
      'chart.top.worst-performing-schools': 'Worst performing schools'
      'map.tooltip': 'Explore the map and click on a school to get started.'
      'chart.title.change-since-2013': 'change since 2013'
      'chart.title.national-raking': 'national ranking'
      'chart.title.pupil-teacher-ratio': 'pupil teacher ratio'
      'chart.title.passrate-over-time': 'pass rates over time'
      'chart.title.passrate-2014': '2014 pass rate'
      'distric': 'District'
      'region': 'Region'

    });

    $translateProvider.translations('es-ar', {
      'TITLE': 'Hola',
      'FOO': 'Esto es un parrafo',
      'dashboard.title': 'Tablero de comando de Educacion'
      'menu.home': 'Inicio'
      'menu.dashboard': 'Tablero de comando'
      'menu.primary': 'Primaria'
      'menu.secondary': 'Secundaria'
      'menu.data': 'Datos'
      'menu.speakout': 'Comentarios'
      'menu.showdata': 'Mostrar datos'
      'tab.school': 'Escuela'
      'tab.best-worst-performance': 'Mejor y Peor Desempeño'
      'tab.best-worst': 'Mejor y Peor'
      'tab.best-worst-improvements': 'Mejor y Peores Mejoras'
      'tab.improvements': 'Mejoras'
      'tab.districts': 'Districtos'
    });

    $translateProvider.preferredLanguage('en');

