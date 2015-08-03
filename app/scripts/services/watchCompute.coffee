'use strict'

###*
 # @ngdoc service
 # @name edudashApp.watchCompute
 # @description
 # # WatchCompute
 # Compute scope variables when other variables change
###
angular.module('edudashAppSrv').service 'watchComputeSrv', ->

  ###*
  # Get a computed watch factory for a $scope
  # @param {object} scope An angular $scope that everything attaches to
  ###
  ($scope) ->
    unless $scope? and typeof $scope.$watchGroup == 'function'
      throw new Error 'First parameter must be a $scope'

    ###*
    # Assigns computed values to the $scope when dependencies change
    # @param {string} what The property of $scope to be updated
    # @param {object} opts
    # @param {string[]} opts.dependencies Properties of $scope that trigger a recompute
    # @param {function} opts.computer Computes the new value
    # @param {boolean} [opts.waitForPromise] Update $scope only after the value resolves
    # @param {function} [opts.filter] Conditionally update $scope
    ###
    (what, opts) ->
      unless typeof what == 'string'
        throw new Error 'First parameter must be a string'
      unless opts?
        throw new Error 'opts must be an object'
      unless opts.dependencies instanceof Array
        throw new Error 'opts.dependencies must be an array of strings'
      unless typeof opts.computer == 'function'
        throw new Error 'opts.computer must be a function'

      setResult = (result) -> $scope[what] = result

      $scope.$watchGroup opts.dependencies, (current, old) ->
        if opts.filter?
          unless typeof opts.filter == 'function'
            throw new Error 'opts.filter must be a function'
          unless opts.filter current, old
            return
        result = opts.computer current, old
        if opts.waitForPromise == true
          unless result? and typeof result.then == 'function'
            throw new Error 'waitForPromise requires that opts.computer returns a Promise'
          result.then setResult, (err) -> throw err
        else
          setResult result
