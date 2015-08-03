'use strict'

describe 'Controller: DashboardCtrl', ->

  beforeEach module 'leafletMap'
  beforeEach module 'edudashAppSrv'
  beforeEach module 'edudashAppCtrl'

  # work around angular translations issue
  beforeEach module 'edudashApp', ($provide, $translateProvider) ->
    $translateProvider.translations 'en', {}
    null  # returning a value breaks angular because angular is awful

  # inject the controller and get its scope
  $scope = null
  beforeEach inject ($rootScope, $controller) ->
    $scope = $rootScope.$new()
    $controller 'DashboardCtrl', $scope: $scope


  it 'should define `visMode` on $scope', ->
    expect($scope.visMode?).toBe true
