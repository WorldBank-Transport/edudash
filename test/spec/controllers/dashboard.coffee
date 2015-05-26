'use strict'

describe 'Controller: DashboardCtrl', ->

  # load the app and mock out dashboard controller's dependencies
  beforeEach module ['edudashAppCtrl', 'edudashAppSrv', () ->
    cartodb:
      createLayer: -> addTo: -> done: -> null
    L:
      map: -> null

  # inject the controller and get its scope
  $scope = null
  beforeEach inject ($rootScope, $controller) ->
    $scope = $rootScope.$new()
    $controller('DashboardCtrl', {$scope: $scope})

#  it 'should define `activeMap` on $scope', ->
#    expect($scope.activeMap?).toBe(true)
  ]