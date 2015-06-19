'use strict'

describe 'leafletMap service: L', ->
  beforeEach module 'leafletMap'
  L = null
  beforeEach inject (_L_) ->
    L = _L_
  # there is not a meaningful way to test leaflet, at least until we drop cartodb


describe 'leafletMap Service: leafletData', ->

  # load the service's module
  beforeEach module 'leafletMap'

  mapMock = null
  leafletData = null
  $timeout = null
  beforeEach inject (_leafletData_, _$timeout_) ->
    mapMock = {}
    leafletData = _leafletData_
    $timeout = _$timeout_

  it 'returns a promise for any map ID', ->
    mapPromise = leafletData.getMap 'bogus'
    expect(typeof mapPromise.then).toBe 'function'

  it 'resolves a map once it is set', ->
    mapPromise = leafletData.getMap 'testMap'
    leafletData.setMap mapMock, 'testMap'  # note: setMap is an internal API
    mapPromise.then (map) -> expect(map).toBe mapMock
    $timeout.flush()  # ensure the promise callback is run


describe 'leafletMap directive: leafletMap', ->
  mapMock = null

  # load the app and mock out leaflet
  beforeEach module 'leafletMap',
    L:
      map: -> mapMock

  leafletData = null
  $compile = null
  $rootScope = null
  $timeout = null
  scope = null
  beforeEach inject (_leafletData_, _$compile_, _$rootScope_, _$timeout_) ->
    mapMock =  # singleton to test for
      eachLayer: -> null
      remove: () -> null
    leafletData = _leafletData_
    $compile = _$compile_
    $rootScope = _$rootScope_
    $timeout = _$timeout_
    scope = $rootScope.$new()

  afterEach inject ($rootScope) ->
    $rootScope.$apply()

  it 'registers its leaflet instance with leafletData', ->
    ($compile '<div leaflet-map id="testMap">hello</div>') scope
    leafletData.getMap('testMap').then (map) ->
      expect(map).toBe mapMock

  it 'should unset the map when it is destroyed', ->
    element = ($compile '<div leaflet-map id="testMap">hello</div>') scope
    scope.$destroy()
    scope.$digest()

    leafletData.getMap('testMap').then (map) ->
      expect(map).toBe 'no!', 'this code should be unreachable'
