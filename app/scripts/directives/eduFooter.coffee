'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.eduFooter
 # @description
 # # Footer
 # logo and nav
###
angular.module('edudashApp').directive 'eduFooter', ->
  restrict: 'E',
  templateUrl: 'views/eduFooter.html',
