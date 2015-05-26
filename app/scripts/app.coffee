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
    'i18nEdudashApp',
    'edudashAppCtrl',
    'edudashAppSrv',
    'edudashAppDir',
    'edudashAppFil'
  ])

