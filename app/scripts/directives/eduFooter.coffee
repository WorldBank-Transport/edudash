'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.eduFooter
 # @description
 # # Footer
 # logo and nav
###
angular.module('edudashAppDir').directive 'eduFooter', ->
  restrict: 'E',
  templateUrl: 'views/eduFooter.html',
