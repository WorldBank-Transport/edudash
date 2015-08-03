'use strict'

describe 'watchComputeSrv', ->

  # load the service's module
  beforeEach module 'edudashAppSrv'

  # grab the service
  watchComputeSrv = null
  beforeEach inject (_watchComputeSrv_) ->
    watchComputeSrv = _watchComputeSrv_

  # grab the $q service
  $q = null
  beforeEach inject (_$q_) ->
    $q = _$q_

  # get a $scope
  $scope = null
  beforeEach inject ($rootScope) ->
    $scope = $rootScope.$new()


  it 'should require instantiation with a $scope', ->
    expect -> watchComputeSrv()
      .toThrow new Error 'First parameter must be a $scope'
    expect -> watchComputeSrv 1
      .toThrow new Error 'First parameter must be a $scope'
    expect -> watchComputeSrv {}
      .toThrow new Error 'First parameter must be a $scope'

  it 'should validate arguments', ->
    expect -> (watchComputeSrv $scope)()
      .toThrow new Error 'First parameter must be a string'
    expect -> (watchComputeSrv $scope) {}
      .toThrow new Error 'First parameter must be a string'
    expect -> (watchComputeSrv $scope) 'z'
      .toThrow new Error 'opts must be an object'
    expect -> (watchComputeSrv $scope) 'z', {}
      .toThrow new Error 'opts.dependencies must be an array of strings'
    expect -> (watchComputeSrv $scope) 'z', dependencies: []
      .toThrow new Error 'opts.computer must be a function'
    expect -> (watchComputeSrv $scope) 'z',
        dependencies: []
        computer: -> 1
        filter: 'not a function'
      .toThrow new Error 'opts.filter must be a function'

  it 'should get an initial value from computer() with no dependencies', ->
    (watchComputeSrv $scope) 'a',
      dependencies: []
      computer: -> 1
    $scope.$digest()
    expect($scope.a).toBe 1

  it 'should compute and assign values from watches', ->
    (watchComputeSrv $scope) 'b',
      dependencies: ['a']
      computer: ([a]) -> a * 2
    $scope.a = 2
    $scope.$digest()
    expect($scope.b).toBe 4
    $scope.a = 3
    $scope.$digest()
    expect($scope.b).toBe 6

  it 'should pass new and old values to computer', ->
    (watchComputeSrv $scope) 'b',
      dependencies: ['a']
      computer: ([a], [oldA]) -> a - oldA
    $scope.a = 1
    $scope.$digest()
    $scope.a = 3
    $scope.$digest()
    expect($scope.b).toBe 2

  it 'should work with multiple dependencies', ->
    (watchComputeSrv $scope) 'c',
      dependencies: ['a', 'b']
      computer: ([a, b]) -> a * b
    $scope.a = 2
    $scope.b = 3
    $scope.$digest()
    expect($scope.c).toBe 6

  it 'should wait for and unwrap promises when waitForPromise: true', ->
    def = $q.defer()
    (watchComputeSrv $scope) 'a',
      dependencies: []
      waitForPromise: true
      computer: -> def.promise
    $scope.$digest()
    expect($scope.a?).toBe false
    def.resolve 1
    $scope.$digest()
    expect($scope.a).toBe 1

  it 'should throw when waitForPromise and compute returns undefined', ->
    (watchComputeSrv $scope) 'a',
      dependencies: []
      waitForPromise: true
      computer: ->  # undefined
    expect -> $scope.$digest()
      .toThrow new Error 'waitForPromise requires that opts.computer returns a Promise'

  it 'should throw when waitForPromise and compute doesn\'t return a promise', ->
    (watchComputeSrv $scope) 'a',
      dependencies: []
      waitForPromise: true
      computer: -> 'a raw value (a string) intead of a promise'
    expect -> $scope.$digest()
      .toThrow new Error 'waitForPromise requires that opts.computer returns a Promise'

  it 'should throw when waitForPromise and the promise fails', ->
    (watchComputeSrv $scope) 'a',
      dependencies: []
      waitForPromise: true
      computer: -> $q (r, reject) -> reject 1
    expect -> $scope.$digest()
      .toThrow 1

  it 'should filter computes if a filter callback is provided', ->
    (watchComputeSrv $scope) 'a',
      dependencies: []
      filter: -> false
      computer: -> 1
    $scope.$digest()
    expect($scope.a?).toBe false

    (watchComputeSrv $scope) 'b',
      dependencies: []
      filter: -> true
      computer: -> 1
    $scope.$digest()
    expect($scope.b).toBe 1
