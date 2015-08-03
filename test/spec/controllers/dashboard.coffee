'use strict'

describe 'Controller: DashboardCtrl', ->

  beforeEach module 'leafletMap'
  beforeEach module 'edudashAppSrv'
  beforeEach module 'edudashAppCtrl'

  # work around angular translations issue
  beforeEach module 'edudashApp', ($provide, $translateProvider) ->
    $translateProvider.translations 'en', {}
    $provide.factory 'OpenDataApi', ($q) ->
      getYearAggregates: -> $q.when {}
    null  # explicitly return nothing because angular is awful

  # inject the controller and get its scope
  $scope = null
  beforeEach inject ($rootScope, $controller) ->
    $scope = $rootScope.$new()
    $controller 'DashboardCtrl', $scope: $scope

  # grab the $q service
  $q = null
  beforeEach inject (_$q_) ->
    $q = _$q_

  # Reactive dependency-based computed values factory
  it 'should validate $scope.compute arguments', ->
    expect -> $scope.compute()
      .toThrow new Error 'First parameter of $scope.compute must be a string'
    expect -> $scope.compute {}
      .toThrow new Error 'First parameter of $scope.compute must be a string'
    expect -> $scope.compute 'z'
      .toThrow new Error 'opts must be an object'
    expect -> $scope.compute 'z', {}
      .toThrow new Error 'opts.dependencies must be an array of strings'
    expect -> $scope.compute 'z', dependencies: []
      .toThrow new Error 'opts.computer must be a function'

  it 'should get an initial value from computer() with no dependencies', ->
    $scope.compute 'a',
      dependencies: []
      computer: -> 1
    $scope.$digest()
    expect($scope.a).toBe 1

  it 'should compute and assign values from watches', ->
    $scope.compute 'b',
      dependencies: ['a']
      computer: ([a]) -> a * 2
    $scope.a = 2
    $scope.$digest()
    expect($scope.b).toBe 4
    $scope.a = 3
    $scope.$digest()
    expect($scope.b).toBe 6

  it 'should pass new and old values to computer', ->
    $scope.compute 'b',
      dependencies: ['a']
      computer: ([a], [oldA]) -> a - oldA
    $scope.a = 1
    $scope.$digest()
    $scope.a = 3
    $scope.$digest()
    expect($scope.b).toBe 2

  it 'should work with multiple dependencies', ->
    $scope.compute 'c',
      dependencies: ['a', 'b']
      computer: ([a, b]) -> a * b
    $scope.a = 2
    $scope.b = 3
    $scope.$digest()
    expect($scope.c).toBe 6

  it 'should wait for and unwrap promises when waitForPromise: true', ->
    def = $q.defer()
    $scope.compute 'a',
      dependencies: []
      waitForPromise: true
      computer: -> def.promise
    $scope.$digest()
    expect($scope.a?).toBe false
    def.resolve 1
    $scope.$digest()
    expect($scope.a).toBe 1

  it 'should throw when waitForPromise and compute returns undefined', ->
    $scope.compute 'a',
      dependencies: []
      waitForPromise: true
      computer: ->  # undefined
    expect -> $scope.$digest()
      .toThrow new Error 'waitForPromise requires that opts.computer returns a Promise'

  it 'should throw when waitForPromise and compute doesn\'t return a promise', ->
    $scope.compute 'a',
      dependencies: []
      waitForPromise: true
      computer: -> 'a raw value (a string) intead of a promise'
    expect -> $scope.$digest()
      .toThrow new Error 'waitForPromise requires that opts.computer returns a Promise'

  it 'should throw when waitForPromise and the promise fails', ->
    $scope.compute 'a',
      dependencies: []
      waitForPromise: true
      computer: -> $q (r, reject) -> reject 1
    expect -> $scope.$digest()
      .toThrow 1
