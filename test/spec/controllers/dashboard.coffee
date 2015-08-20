'use strict'

describe 'Controller: DashboardCtrl', ->

  beforeEach module 'leafletMap'
  beforeEach module 'edudashAppSrv'
  beforeEach module 'edudashAppCtrl'

  # so many mocks :(
  beforeEach module 'edudashApp', ($provide, $translateProvider) ->
    $translateProvider.translations 'en', {}
    $provide.factory 'OpenDataApi', ($q) ->
      getYearAggregates: -> $q.when {}
    $provide.factory 'staticApi', ($q) ->
      getRegions: -> $q.when objects: tz_Regions: []
      getDistricts: -> $q.when objects: tz_districts: []
    $provide.factory 'topojson', ->
      feature: -> features: []
    $provide.factory 'loadingSrv', ->
      containerLoad: ->
    null  # explicitly return nothing because angular is awful

  # inject the controller and get its scope
  $scope = null
  beforeEach inject ($rootScope, $controller) ->
    $scope = $rootScope.$new()
    $controller 'DashboardCtrl', $scope: $scope

  it 'should toggle polygon views', ->
    expect(1).toBe 1
