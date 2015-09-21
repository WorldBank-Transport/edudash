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
    #
    # Note that the semantics of the `computer` parameters are different from
    # angular's $scope.$watchGroup listener parameters in order to encourage
    # the use of pure functions:
    #
    # - newValues contains the current values from $scope, as in $watchGroup
    # - oldValues contains the previous newValues, contrary to $watchGroup,
    #   which has the previous value for each member independently
    # - The third scope parameter is absent to encourage a pure `computer`.
    #   Declare all scope values needed for the computation in `dependencies`.
    #
    # @param {string} what The property of $scope to be updated
    # @param {object} opts
    # @param {string[]} opts.dependencies Properties of $scope that trigger a recompute
    # @param {function} opts.computer Computes the new value
    # @param {boolean} [opts.waitForPromise] Update $scope only after the value resolves
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
      if opts.waitForPromise?
        unless typeof opts.waitForPromise == 'boolean'
          throw new Error 'opts.waitForPromise must be a boolean'
      if what in opts.dependencies
        throw new Error 'Name to compute cannot be a dependency'

      oldVals = (null for d in opts.dependencies)

      watchCount = 0  # keep track of which watch we're processing

      setResult = (n) -> (result) ->
        if n == watchCount  # this is the latest
          $scope[what] = result
        # else: an old promise resolved that has been superceded

      $scope.$watchGroup opts.dependencies, (newVals, ngOld, scope) ->
        watchCount += 1
        # compute the new value. Discard's angular's `oldVals`; see jsDoc above
        result = opts.computer newVals, oldVals, scope
        oldVals = newVals.slice()

        if opts.waitForPromise == true
          unless result? and typeof result.then == 'function'
            throw new Error "watchCompute #{what}: waitForPromise requires that opts.computer returns a Promise"
          result.then (setResult watchCount), (err) -> throw err
        else
          (setResult watchCount) result
