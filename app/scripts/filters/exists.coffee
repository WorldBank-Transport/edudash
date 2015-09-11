'use strict'

###*
 # @ngdoc filter
 # @name edudashApp.filter:exists
 # @function
 # @description
 # # exists
 # Filter in the edudashApp.
###
angular.module('edudashAppFil')
    .filter 'exists', ->
        (input) ->
            if input? and input.length? and input.length <= 0
                return false
            if typeof input == 'object'
                for prop, value of input
                    return true;
                return false
            if typeof input == 'number' && input == NaN
                return false
            if input? and input != ''
                return true
            return false
