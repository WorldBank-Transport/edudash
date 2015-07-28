'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:DashboardsCtrl
 # @description
 # # DashboardsCtrl
 # Controller of the edudashApp
###
angular.module('edudashAppCtrl').controller 'DashboardCtrl', [
    '$scope', '$window', '$routeParams', '$anchorScroll', '$http', 'leafletData',
    '_', '$q', 'WorldBankApi', 'layersSrv', 'chartSrv', '$log','$location','$translate',
    '$timeout', 'MetricsSrv', 'colorSrv', 'OpenDataApi'

    ($scope, $window, $routeParams, $anchorScroll, $http, leafletData,
    _, $q, WorldBankApi, layersSrv, chartSrv, $log, $location, $translate,
    $timeout, MetricsSrv, colorSrv, OpenDataApi) ->

        # other state
        layers = {}
        currentLayer = null
        schoolCodeMap = {}

        #### Template / Controller API via $scope ####

        # app state
        angular.extend $scope,
          year: null  # set after init
          years: null
          yearAggregates: null
          viewMode: null  # set after init
          visMode: 'passrate'
          schoolType: $routeParams.type
          hovered: null
          lastHovered: null
          selected: null
          allSchools: $q -> null
          filteredSchools: $q -> null
          pins: $q -> null
          rankBy: null  # performance or improvement for primary
          rankedBy: []
          moreThan40: null  # students, for secondary schools

        # state transitioners
        angular.extend $scope,
          setYear: (newYear) -> $scope.year = newYear
          setViewMode: (newMode) -> $scope.viewMode = newMode
          setVisMode: (newMode) -> $scope.visMode = newMode
          setSchoolType: (newType) -> $location.path "/dashboard/#{newType}/"
          hover: (code) -> (findSchool code).then ((s) -> $scope.hovered = s), $log.error
          keepHovered: -> $scope.hovered = $scope.lastHovered
          unHover: -> $scope.hovered = null
          select: (code) -> (findSchool code).then ((s) -> $scope.selected = s), $log.error
          search: (q) -> search q

        # view util functions
        angular.extend $scope,
          Math: Math


        # State Listeners

        $scope.$watchGroup ['year', 'schoolType', 'rankBy', 'moreThan40'],
          ([year, schoolType, rankBy, moreThan40]) -> unless year == null
            $scope.allSchools = OpenDataApi.getSchools
                year: year
                schoolType: schoolType
                subtype: rankBy
                moreThan40: moreThan40
              .catch (err) -> $log.error err

            # leaving this as is for now, since we don't have this at school level
            MetricsSrv.getPupilTeacherRatio({level: $scope.schoolType}).then (data) ->
              $scope.pupilTeacherRatio = data.rate

        $scope.$watchGroup ['schoolType', 'rankBy', 'moreThan40'],
          ([schoolType, rankBy, moreThan40]) ->
            OpenDataApi.getYearAggregates schoolType, rankBy, moreThan40
              .then (years) ->
                $scope.yearAggregates = _(years).reduce ((agg, y) ->
                  agg[y.YEAR_OF_RESULT] =
                    PASS_RATE: y.average_pass_rate
                  agg
                ), {}

        $scope.$watch 'allSchools', (all) -> all.then (schools) ->
          _(schools).each (school) -> schoolCodeMap[school.CODE] = school
          rankSchools switch $scope.rankBy
              when 'performance' then ['RANK']
              when 'improvement' then ['CHANGE_PREVIOUS_YEAR', true]
              when null then ['CHANGE_PREVIOUS_YEAR', true]  # secondary
              else throw new Error "invalid rankBy: '#{$scope.rankBy}'"
            .then (r) -> $scope.rankedBy = r

        $scope.$watchGroup ['allSchools'], ([allSchools]) ->
          $scope.filteredSchools = $q (resolve, reject) ->
            allSchools.then resolve, reject

        $scope.$watch 'filteredSchools', (schools, oldSchools) ->
          layerId = "schools-#{$scope.year}-#{$scope.schoolType}-#{$scope.moreThan40}"
          mapped = $q (resolve, reject) ->
            map = (data) ->
              resolve data.map (s) -> [ s.LATITUDE, s.LONGITUDE, s.CODE ]
            schools.then map, reject
          schools.then (schools) ->
            $scope.pins = layersSrv.addFastCircles layerId, mapId,
              getData: () -> mapped
              options:
                className: 'school-location'
                radius: 8
                onEachFeature: processPin

        $scope.$watch 'pins', (blah, oldPins) ->
          oldPins.then (pins) ->
            if pins != null
              leafletData.getMap(mapId).then (map) ->
                if pins?
                  map.removeLayer pins

        $scope.$watchGroup ['pins', 'visMode'], ([pinsP]) ->
          pinsP.then (pins) -> pins.eachVisibleLayer colorPin

        $scope.$watch 'viewMode', (newMode, oldMode) ->
          if newMode not in ['schools', 'national', 'regional']
            console.error 'changed to invalid view mode:', newMode
            return
          # unless newMode == oldMode  # doesnt work for initial render
          leafletData.getMap(mapId).then (map) ->
            unless currentLayer == null
              map.removeLayer currentLayer
              currentLayer = null

        $scope.$watch 'hovered', (thing, oldThing) ->
          if thing != null
            $scope.lastHovered = thing
            if $scope.viewMode == 'schools'
              getSchoolPin(thing.CODE).then (pin) ->
                pin.bringToFront()
                pin.setStyle
                  color: '#05a2dc'
                  weight: 5
                  opacity: 1
                  fillOpacity: 1
            #   when 'regional' then weight: 5, opacity: 1

          if oldThing != null
            if $scope.viewMode == 'schools'
              getSchoolPin(oldThing.CODE).then (pin) ->
                pin.setStyle
                  color: '#fff'
                  weight: 2
                  opacity: 0.5
                  fillOpacity: 0.6
              # when 'regional' then weight: 0, opacity: 0.6

        $scope.$watch 'selected', (school) ->
          if school != null
            if $scope.viewMode == 'schools'
              setSchool school

        $scope.$on 'filtersToggle', (event, opts) ->
          $scope.filtersHeight = opts.height

        setSchool = (school) ->
          latlng = [school.LATITUDE, school.LONGITUDE]
          markSchool latlng
          leafletData.getMap(mapId).then (map) ->
            map.setView latlng, (Math.max 9, map.getZoom())

          unless school.ranks?
            $q.all
                region: (rank school, 'REGION')
                district: (rank school, 'DISTRICT')
              .then (ranks) -> school.ranks = ranks

          unless school.yearAggregates?
            OpenDataApi.getSchoolAggregates $scope.schoolType, $scope.rankBy, school.CODE
              .then (data) ->
                school.yearAggregates = _(data).reduce ((agg, year) ->
                  agg[year.YEAR_OF_RESULT] =
                    PASS_RATE: year.PASS_RATE
                  agg
                ), {}

        findSchool = (code) ->
          $q (resolve, reject) ->
            findIt = (schools) ->
              if schoolCodeMap[code]?
                resolve schoolCodeMap[code]
              else
                reject "Could not find school by code '#{code}'"
            $scope.allSchools.then findIt, reject

        getSchoolPin = (code) ->
          $q (resolve, reject) ->
            $scope.pins.then ((pins) -> resolve pins.getLayer code), reject

        # get the (rank, total) of a school, filtered by its region or district
        rank = (school, rank_by) ->
          if rank_by not in ['REGION', 'DISTRICT']
            throw new Error "invalid rank_by: '#{rank_by}'"
          $q (resolve, reject) ->
            rankSchool = (schools) ->
              if school[rank_by] == undefined
                return resolve [undefined, undefined]
              ranked = schools
                .filter (s) -> s[rank_by] == school[rank_by]
                .sort (a, b) -> a.rank - b.rank
              resolve
                rank: (ranked.indexOf school)
                total: ranked.length

            $scope.allSchools.then rankSchool, reject

        rankSchools = ([rank_by, desc]) ->
          rb = rank_by
          if rb not in ['CHANGE_PREVIOUS_YEAR', 'RANK']
            throw new Error "invalid rank_by: '#{rb}'"
          $q (resolve, reject) ->
            getRanked = (schools) -> resolve _.unique(schools
              .filter (s) -> s[rb]?
              .sort (a, b) -> if desc then b[rb] - a[rb] else a[rb] - b[rb]
            ).slice 0, 20
            $scope.allSchools.then getRanked, reject


        # widget local state (maybe should move to other directives)
        $scope.searchText = "dar"
        $scope.schoolsChoices = []

        # controller constants
        mapId = 'map'

        # other global-ish stuff
        schoolMarker = null

        if $routeParams.type isnt 'primary' and $routeParams.type isnt 'secondary'
          $timeout -> $location.path '/'

        # INIT
        leafletData.getMap(mapId).then (map) ->
          # initialize the map view
          map.setView [-7.199, 34.1894], 6
          # add the basemap
          layersSrv.addTileLayer 'gray', mapId, '//{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
          # set up the initial view
          $scope.setViewMode 'schools'
          if $scope.schoolType == 'primary'
            $scope.rankBy = 'performance'
          $scope.setYear 2014  # hard-coded default to speed up page-load
          OpenDataApi.getYears $scope.schoolType, $scope.rankBy
            .then (years) -> $scope.years = _(years).map (y) -> y.YEAR_OF_RESULT


        processPin = (code, layer) ->
          colorPin code, layer
          layer.on 'mouseover', -> $scope.$apply ->
            $scope.hover code
          layer.on 'mouseout', -> $scope.$apply ->
            $scope.unHover()
          layer.on 'click', -> $scope.$apply ->
            $scope.select code

        mapLayerCreators =
          regional: ->
            getData = -> $q (resolve, reject) ->
              WorldBankApi.getDistricts $scope.schoolType
                .success (data) ->
                  resolve
                    type: 'FeatureCollection'
                    features: data.rows.map (district) ->
                      type: 'Feature'
                      geometry: JSON.parse district.geojson
                      properties: angular.extend district, geojson: null
                .error reject
            options =
              onEachFeature: (feature, layer) -> attachLayerEvents layer
            layersSrv.addGeojsonLayer "regions-#{$scope.schoolType}", mapId,
              getData: getData
              options: options


        colorPin = (code, l) -> findSchool(code).then (school) ->
          v = switch
            when $scope.visMode == 'passrate' then school.PASS_RATE
            when $scope.visMode == 'ptratio' then school.pt_ratio
          l.setStyle colorSrv.pinStyle v, $scope.visMode

        groupByDistrict = (rows) ->
          districts = {}
          for row in rows
            unless districts[row.district]
              districts[row.district] = {pt_ratio: [], pass_2014: []}
            for prop in ['pt_ratio', 'pass_2014']
              districts[row.district][prop].push(row[prop])
          districts

        average = (nums) -> (nums.reduce (a, b) -> a + b) / nums.length

        colorRegions = ->
          if $scope.viewMode != 'regional'
            console.error 'colorRegions should only be called when viewMode is "regional"'
            return
          WorldBankApi.getSchools($scope.schoolType).success (data) ->
            byRegion = groupByDistrict data.rows
            _(currentLayer.getLayers()).each (l) ->
              regionData = byRegion[l.feature.properties.NAME]
              if not regionData
                v = null
              else if $scope.visMode == 'passrate'
                v = average(regionData.pass_2014)
              else
                v = average(regionData.pt_ratio)
              l.setStyle colorSrv.areaStyle v, $scope.visMode

        markSchool = (latlng) ->
          unless schoolMarker?
            icon = layersSrv.awesomeIcon markerColor: 'blue', icon: 'map-marker'
            schoolMarker = layersSrv.marker 'school-marker', mapId,
              latlng: latlng
              options: icon: icon

          schoolMarker.then (marker) ->
            marker.setLatLng latlng

        search = (query) ->
          if query?
            OpenDataApi.search $scope.schoolType, $scope.rankBy, query, $scope.year
              .then (data) -> $q.all _(data).map (s) -> findSchool s.CODE
                .then (schools) ->
                  $scope.searchText = query
                  $scope.searchChoices = _.unique schools


        # todo: figure out if these are needed
        $scope.getTimes = (n) ->
            new Array(n)

        $scope.anchorScroll = () ->
            $anchorScroll()

]
