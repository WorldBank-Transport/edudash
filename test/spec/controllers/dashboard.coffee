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
      getYears: -> $q.when {}
      getSchools: -> $q.when []
    $provide.factory 'staticApi', ($q) ->
      getRegions: -> $q.when objects: tz_Regions:
        [{id: 'A', properties: {name: 'A'}}]
      getDistricts: -> $q.when objects: tz_districts:
        [{id: 'Z', properties: {name: 'Z'}}]
    $provide.factory 'topojson', ->
      feature: (blah, d) -> features: d
    $provide.factory 'loadingSrv', ->
      containerLoad: ->
    $provide.factory 'L', ->
      tileLayer: -> addTo: ->
      geoJson: ->
        bringToFront: ->
        eachLayer: ->
        getBounds: ->
      fastCircles: ->
    $provide.factory 'leafletData', ($q) ->
      getMap: -> $q.when
        addLayer: ->
        fitBounds: ->
        removeLayer: ->
    null  # explicitly return nothing because angular is awful

  # inject the controller and get its scope
  $scope = null
  beforeEach inject ($rootScope, $controller) ->
    $scope = $rootScope.$new()
    $controller 'DashboardCtrl', $scope: $scope

  describe 'polyToggle', ->
    it 'should switch from schools to regions', ->
      $scope.setViewMode 'schools'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'schools'
      $scope.togglePolygons 'regions'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'polygons'
      expect($scope.polyType).toEqual 'regions'

    it 'should switch from schools to districts', ->
      $scope.setViewMode 'schools'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'schools'
      $scope.togglePolygons 'districts'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'polygons'
      expect($scope.polyType).toEqual 'districts'

    it 'should switch regions/districts', ->
      $scope.setViewMode 'schools'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'schools'
      $scope.togglePolygons 'regions'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'polygons'
      expect($scope.polyType).toEqual 'regions'
      $scope.togglePolygons 'districts'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'polygons'
      expect($scope.polyType).toEqual 'districts'
      $scope.togglePolygons 'regions'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'polygons'
      expect($scope.polyType).toEqual 'regions'

    it 'should toggle off regions to schools', ->
      $scope.setViewMode 'schools'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'schools'
      $scope.togglePolygons 'regions'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'polygons'
      expect($scope.polyType).toEqual 'regions'
      $scope.togglePolygons 'regions'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'schools'

    it 'should toggle off districts to schools', ->
      $scope.setViewMode 'schools'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'schools'
      $scope.togglePolygons 'districts'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'polygons'
      expect($scope.polyType).toEqual 'districts'
      $scope.togglePolygons 'districts'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'schools'

    it 'should deselect a selected school when switching to a polygon view', ->
      $scope.selectedSchoolCode = 'Z'
      $scope.togglePolygons 'regions'
      $scope.$apply()
      expect($scope.selectedSchoolCode).toBe null

      $scope.selectedSchoolCode = 'Z'
      $scope.togglePolygons 'districts'
      $scope.$apply()
      expect($scope.selectedSchoolCode).toBe null

    it 'should clear a selected polygon when toggling off', ->
      $scope.$apply()
      $scope.togglePolygons 'regions'
      $scope.$apply()
      $scope.selectedPolyId = 'A'
      $scope.togglePolygons 'regions'
      $scope.$apply()
      expect($scope.selectedPolyId).toBe null

  describe 'selectPoly', ->
    it 'should transition region polyType to district', ->
      $scope.$apply()
      $scope.togglePolygons 'regions'
      $scope.$apply()
      $scope.selectPoly 'A'
      $scope.$apply()
      expect($scope.polyType).toEqual 'districts'

    it 'should transition district polyType to schools', ->
      $scope.$apply()
      $scope.togglePolygons 'districts'
      $scope.$apply()
      $scope.selectPoly 'Z'
      $scope.$apply()
      expect($scope.viewMode).toBe 'schools'

    it 'should maintain the selected region poly when it is selected', ->
      $scope.$apply()
      $scope.togglePolygons 'regions'
      $scope.$apply()
      $scope.selectPoly 'A'
      $scope.$apply()
      expect($scope.selectedPolyId).toEqual 'A'
      expect($scope.selectedPoly).not.toBe null

    it 'should maintain the selected district poly when it is selected', ->
      $scope.$apply()
      $scope.togglePolygons 'districts'
      $scope.$apply()
      $scope.selectPoly 'Z'
      $scope.$apply()
      expect($scope.selectedPolyId).toEqual 'Z'
      expect($scope.selectedPoly).not.toBe null

    it 'should reset polyType when selecting a district to transition to schools', ->
      $scope.$apply()
      $scope.togglePolygons 'districts'
      $scope.$apply()
      $scope.selectPoly 'Z'
      $scope.$apply()
      expect($scope.polyType).toBe null

    it 'should clear the selected district from schools view when selecting districts again', ->
      $scope.$apply()
      $scope.togglePolygons 'districts'
      $scope.$apply()
      $scope.selectPoly 'Z'
      $scope.$apply()
      $scope.togglePolygons 'districts'
      $scope.$apply()
      expect($scope.viewMode).toEqual 'polygons'
      expect($scope.polyType).toEqual 'districts'
