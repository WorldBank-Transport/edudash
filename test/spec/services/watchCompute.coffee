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
        waitForPromise: 'not a boolean'
      .toThrow new Error 'opts.waitForPromise must be a boolean'

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
      computer: ([a], [oldA]) -> [a, oldA]
    $scope.a = 1
    $scope.$digest()
    expect($scope.b).toEqual [1, null]
    $scope.a = 3
    $scope.$digest()
    expect($scope.b).toEqual [3, 1]

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
      .toThrow new Error 'watchCompute a: waitForPromise requires that opts.computer returns a Promise'

  it 'should throw when waitForPromise and compute doesn\'t return a promise', ->
    (watchComputeSrv $scope) 'a',
      dependencies: []
      waitForPromise: true
      computer: -> 'a raw value (a string) intead of a promise'
    expect -> $scope.$digest()
      .toThrow new Error 'watchCompute a: waitForPromise requires that opts.computer returns a Promise'

  it 'should throw when waitForPromise and the promise fails', ->
    (watchComputeSrv $scope) 'a',
      dependencies: []
      waitForPromise: true
      computer: -> $q (r, reject) -> reject 1
    expect -> $scope.$digest()
      .toThrow 1

  it 'should provide previous newVals as oldVals, not $watchGroup oldVals', ->
    (watchComputeSrv $scope) 'aChanged',
      dependencies: ['a', 'b']
      computer: ([newA], [oldA]) -> newA != oldA
    $scope.a = 1
    $scope.$digest()
    $scope.a = 2
    $scope.$digest()
    expect($scope.aChanged).toBe true
    $scope.b = 3
    $scope.$digest()
    expect($scope.aChanged).toBe false

  it 'waitForPromise should only reflect the last promise', ->
    (watchComputeSrv $scope) 'aUnwrapped',
      dependencies: ['a']
      waitForPromise: true
      computer: ([a]) -> a or $q.when null
    d1 = $q.defer()
    d2 = $q.defer()
    $scope.a = d1.promise
    $scope.$digest()
    $scope.a = d2.promise
    $scope.$digest()
    d2.resolve 1
    $scope.$digest()
    expect $scope.aUnwrapped
      .toBe 1
    d1.resolve 0
    $scope.$digest()
    expect $scope.aUnwrapped
      .toBe 1

  it 'should ensure it is not computing one of its dependencies', ->
    expect(->
      (watchComputeSrv $scope) 'z',
        dependencies: ['z']
        computer: ->
    ).toThrow new Error 'Name to compute cannot be a dependency'
