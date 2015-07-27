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

        #### Template / Controller API via $scope ####

        # app state
        angular.extend $scope,
          year: null  # set after init
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
          rankedByChange: []
          moreThan40: null  # students, for secondary schools

        # state transitioners
        angular.extend $scope,
          setYear: (newYear) -> $scope.year = newYear
          setViewMode: (newMode) -> $scope.viewMode = newMode
          setVisMode: (newMode) -> $scope.visMode = newMode
          setSchoolType: (newType) -> $location.path "/dashboard/#{newType}/"
          hover: (id) -> (findSchool id).then ((s) -> $scope.hovered = s), $log.error
          keepHovered: -> $scope.hovered = $scope.lastHovered
          unHover: -> $scope.hovered = null
          select: (id) -> (findSchool id).then ((s) -> $scope.selected = s), $log.error
          rankSchools: (a) -> rankSchools a


        # State Listeners

        $scope.$watchGroup ['year', 'schoolType', 'moreThan40'],
          ([year, schoolType, moreThan40]) ->
            unless year == null
              $scope.allSchools = OpenDataApi.getSchools year, schoolType, moreThan40
                .catch (err) -> $log.error err

        $scope.$watch 'allSchools', (all) -> all.then (schools) ->
          rankSchools('change').then (r) -> $scope.rankedByChange = r

        $scope.$watchGroup ['allSchools'], ([allSchools]) ->
          $scope.filteredSchools = $q (resolve, reject) ->
            allSchools.then resolve, reject

        $scope.$watch 'filteredSchools', (schools, oldSchools) ->
          layerId = "schools-#{$scope.schoolType}-#{$scope.moreThan40}"
          mapped = $q (resolve, reject) ->
            map = (data) ->
              resolve data.map (s) -> [ s.latitude, s.longitude, s.id ]
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
              getSchoolPin(thing.id).then (pin) ->
                pin.bringToFront()
                pin.setStyle
                  color: '#05a2dc'
                  weight: 5
                  opacity: 1
                  fillOpacity: 1
            #   when 'regional' then weight: 5, opacity: 1

          if oldThing != null
            if $scope.viewMode == 'schools'
              getSchoolPin(oldThing.id).then (pin) ->
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


        setSchool = (school) ->
          latlng = [school.latitude, school.longitude]
          markSchool latlng
          leafletData.getMap(mapId).then (map) ->
            setMapView latlng, (Math.max 9, map.getZoom())
          rank(school, 'region').then $log.log


        findSchool = (id) ->
          $q (resolve, reject) ->
            findIt = (schools) ->
              matches = schools.filter (s) -> s.id == id
              if matches.length == 0
                reject "Could not find school by id '#{id}'"
              else
                if matches.length > 1
                  $log.warn "Found #{matches.length} schools for id '#{id}', using first"
                  $log.log matches
                resolve matches[0]
            $scope.allSchools.then findIt, reject

        getSchoolPin = (id) ->
          $q (resolve, reject) ->
            $scope.pins.then ((pins) -> resolve pins.getLayer id), reject

        # get the (rank, total) of a school, filtered by its region or district
        rank = (school, rank_by) ->
          if rank_by not in ['region', 'district']
            throw new Error "invalid rank_by: '#{rank_by}'"
          $q (resolve, reject) ->
            rankSchool = (schools) ->
              if school[rank_by] == undefined
                return resolve [undefined, undefined]
              ranked = schools
                .filter (s) -> s[rank_by] == school[rank_by]
                .sort (a, b) -> a.rank - b.rank
              resolve [(ranked.indexOf school), ranked.length]

            $scope.allSchools.then rankSchool, reject

        rankSchools = (rank_by) ->
          if rank_by not in ['change']
            throw new Error "invalid rank_by: '#{rank_by}'"
          $q (resolve, reject) ->
            getRanked = (schools) -> resolve _.unique(schools
              .filter (s) -> s[rank_by]?
              .sort (a, b) -> a[rank_by] - b[rank_by]
            ).slice 0, 20
            $scope.allSchools.then getRanked, reject


        # widget local state (maybe should move to other directives)
        $scope.searchText = "dar"
        $scope.schoolsChoices = []

        # controller constants
        mapId = 'map'

        # other global-ish stuff
        schoolMarker = null

        ptMin = 0
        ptMax = 150
        $scope.passRange =
            min: 0
            max: 100
        $scope.ptRange =
            min: ptMin
            max: ptMax
        $scope.filterPassRate = {
          range: {
              min: 0,
              max: 100
          },
          minValue: 0,
          maxValue: 100
        };
        $scope.filterPupilRatio = {
          range: {
              min: 0,
              max: 10
          },
          minValue: 0,
          maxValue: 10
        };
        if $routeParams.type isnt 'primary' and $routeParams.type isnt 'secondary'
          $timeout -> $location.path '/'

        leafletData.getMap(mapId).then (map) ->
          # initialize the map view
          map.setView [-7.199, 34.1894], 6
          # add the basemap
          layersSrv.addTileLayer 'gray', mapId, '//{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
          # set up the initial view
          $scope.setViewMode 'schools'
          $scope.setYear 2014


        processPin = (id, layer) ->
          colorPin id, layer
          layer.on 'mouseover', -> $scope.$apply ->
            $scope.hover id
          layer.on 'mouseout', -> $scope.$apply ->
            $scope.unHover()
          layer.on 'click', -> $scope.$apply ->
            $scope.select id

        mapLayerCreators =
          schools: ->
            getData = -> $q (resolve, reject) ->
              WorldBankApi.getSchools $scope.schoolType, $scope.moreThan40
                .success (data) ->
                  resolve data.rows.map (school) -> [
                    school.latitude,
                    school.longitude,
                    school,
                  ]
                .error reject
            options =
              className: 'school-location'
              radius: 8
              onEachFeature: (data, layer) ->
                layer.feature = data
                colorPin layer
                attachLayerEvents layer
            layersSrv.addFastCircles "schools-#{$scope.schoolType}", mapId,
              getData: getData
              options: options

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


        colorPin = (id, l) -> findSchool(id).then (school) ->
          v = switch
            when $scope.visMode == 'passrate' then school.passrate
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
              regionData = byRegion[l.feature.properties.name]
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

        setMapView = (latlng, zoom, view) ->
            if view?
                $scope.setViewMode view
            unless zoom?
                zoom = 9
            leafletData.getMap(mapId).then (map) ->
                map.setView latlng, zoom

        updateMap = () ->
          if $scope.viewMode != 'district'
            # Include schools with no pt_ratio are also shown when the pt limits in extremeties
            if $scope.ptRange.min == ptMin and $scope.ptRange.max == ptMax
                WorldBankApi.updateLayers(layers, $scope.schoolType, $scope.passRange)
            else
                WorldBankApi.updateLayersPt(layers, $scope.schoolType, $scope.passRange, $scope.ptRange)

        $scope.updateMap = _.debounce(updateMap, 500)

        $scope.$on 'filtersToggle', (event, opts) ->
          $scope.filtersHeight = opts.height

        $scope.setSchool = $log.log

        $scope.search = (query) ->
          if query?
            OpenDataApi.search $scope.schoolType, $scope.rankBy, query, $scope.year
              .then (data) -> $q.all _(data).map (s) -> findSchool s.id
                .then (schools) ->
                  $scope.searchText = query
                  $scope.searchChoices = _.unique schools

        $scope.$watch 'passRange', ((newVal, oldVal) ->
            unless _.isEqual(newVal, oldVal)
                $scope.updateMap()
            return
        ), true

        $scope.$watch 'ptRange', ((newVal, oldVal) ->
            unless _.isEqual(newVal, oldVal)
                $scope.updateMap()
            return
        ), true

        $scope.getTimes = (n) ->
            new Array(n)

        $scope.anchorScroll = () ->
            $anchorScroll()

        WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'avg_pass_rate', order: 'DESC'}).then (result) ->
          $scope.bpdistrics = result.data.rows
        WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'avg_pass_rate', order: 'ASC'}).then (result) ->
          $scope.wpdistrics = result.data.rows
        WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'change', order: 'DESC'}).then (result) ->
          $scope.midistrics = result.data.rows
        WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'change', order: 'ASC'}).then (result) ->
          $scope.lidistrics = result.data.rows
        MetricsSrv.getPupilTeacherRatio({level: $scope.schoolType}).then (data) ->
          $scope.pupilTeacherRatio = data.rate

        updateDashboard = () ->
          OpenDataApi.getBestSchool($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
            $scope.bestSchools = data.result.records

          OpenDataApi.getWorstSchool($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
            $scope.worstSchools = data.result.records

          OpenDataApi.mostImprovedSchools($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
            $scope.mostImprovedSchools = data.result.records

          OpenDataApi.leastImprovedSchools($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
            $scope.leastImprovedSchools = data.result.records

          OpenDataApi.getGlobalPassrate($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
            $scope.passrate = parseFloat data.result.records[0].avg

          OpenDataApi.getGlobalChange($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
            records = data.result.records
            $scope.passRateChange = if(records.length == 2) then parseInt(records[1].avg - records[0].avg) else 0

          OpenDataApi.getPassOverTime($scope.schoolType, $scope.rankBest, $scope.moreThan40).success (data) ->
            parseList = data.result.records.map (x) -> {key: x.YEAR_OF_RESULT, val: parseInt(x.avg)}
            $scope.globalpassratetime = parseList

        $scope.$watch '[rankBest, moreThan40, selectedYear]', updateDashboard
        $scope.rankBest = 'performance' if (!$scope.rankBest? and $scope.schoolType is 'primary')
]
