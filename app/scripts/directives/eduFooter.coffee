'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.eduFooter
 # @description
 # # Footer
 # Footer information
###
angular.module('edudashAppDir').directive 'eduFooter', ->
  restrict: 'E'
  templateUrl: 'views/eduFooter.html'
