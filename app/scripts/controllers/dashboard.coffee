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
          years: []
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


         # State Listeners

        $scope.$watchGroup ['year', 'schoolType', 'rankBy', 'moreThan40'],
          ([year, schoolType, rankBy, moreThan40]) ->
            unless year == null
              $scope.allSchools = OpenDataApi.getSchools
                  year: year
                  schoolType: schoolType
                  subtype: rankBy
                  moreThan40: moreThan40
                .catch (err) -> $log.error err

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


        setSchool = (school) ->
          latlng = [school.LATITUDE, school.LONGITUDE]
          markSchool latlng
          leafletData.getMap(mapId).then (map) ->
            setMapView latlng, (Math.max 9, map.getZoom())
          rank(school, 'REGION').then $log.log


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
              resolve [(ranked.indexOf school), ranked.length]

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
              max: 100
          },
          minValue: 0,
          maxValue: 100
        };

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


          # leaving this as is for now, since we don't have this at school level
          MetricsSrv.getPupilTeacherRatio({level: $scope.schoolType}).then (data) ->
            $scope.pupilTeacherRatio = data.rate

          # legacy query for passrate by year
          OpenDataApi.getGlobalChange($scope.schoolType, $scope.rankBy, $scope.moreThan40, $scope.year).success (data) ->
            records = data.result.records
            $scope.passRateChange = if(records.length == 2) then parseInt(records[1].avg - records[0].avg) else 0

          # legacy passrate guage datasource
          OpenDataApi.getGlobalPassrate($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
            $scope.passrate = parseFloat data.result.records[0].avg


        processPin = (code, layer) ->
          colorPin code, layer
          layer.on 'mouseover', -> $scope.$apply ->
            $scope.hover code
          layer.on 'mouseout', -> $scope.$apply ->
            $scope.unHover()
          layer.on 'click', -> $scope.$apply ->
            $scope.select code

        mapLayerCreators =
          schools: ->
            getData = -> $q (resolve, reject) ->
              WorldBankApi.getSchools $scope.schoolType, $scope.moreThan40
                .success (data) ->
                  resolve data.rows.map (school) -> [
                    school.LATITUDE,
                    school.LONGITUDE,
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

        setMapView = (latlng, zoom, view) ->
            if view?
                $scope.setViewMode view
            unless zoom?
                zoom = 9
            leafletData.getMap(mapId).then (map) ->
                map.setView latlng, zoom

#         # updateMap = () ->
#           if $scope.viewMode != 'district'
#             # Include schools with no pt_ratio are also shown when the pt limits in extremeties
#             if $scope.ptRange.min == ptMin and $scope.ptRange.max == ptMax
#                 WorldBankApi.updateLayers(layers, $scope.schoolType, $scope.passRange)
#             else
# <<<<<<< HEAD
#                 WorldBankApi.updateLayersPt(layers, $scope.schoolType, $scope.passRange, $scope.ptRange)

#         $scope.updateMap = _.debounce(updateMap, 500)

#         $scope.$on 'filtersToggle', (event, opts) ->
#           $scope.filtersHeight = opts.height

#         $scope.setSchool = $log.log

        $scope.search = (query) ->
          if query?
            OpenDataApi.search $scope.schoolType, $scope.rankBy, query, $scope.year
              .then (data) -> $q.all _(data).map (s) -> findSchool s.CODE
                .then (schools) ->
                  $scope.searchText = query
                  $scope.searchChoices = _.unique schools

#         # $scope.$watch 'passRange', ((newVal, oldVal) ->
#         #     unless _.isEqual(newVal, oldVal)
#         #         $scope.updateMap()
#         #     return
#         # ), true

#         # $scope.$watch 'ptRange', ((newVal, oldVal) ->
#         #     unless _.isEqual(newVal, oldVal)
#         #         $scope.updateMap()
#         #     return
#         # ), true

#         # $scope.getTimes = (n) ->
#         #     new Array(n)

#         # $scope.anchorScroll = () ->
#         #     $anchorScroll()

#         # WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'avg_pass_rate', order: 'DESC'}).then (result) ->
#         #   $scope.bpdistrics = result.data.rows
#         # WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'avg_pass_rate', order: 'ASC'}).then (result) ->
#         #   $scope.wpdistrics = result.data.rows
#         # WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'change', order: 'DESC'}).then (result) ->
#         #   $scope.midistrics = result.data.rows
#         # WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'change', order: 'ASC'}).then (result) ->
#         #   $scope.lidistrics = result.data.rows


#         # updateDashboard = () ->
#         #   OpenDataApi.getBestSchool($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#         #     $scope.bestSchools = data.result.records

#         #   OpenDataApi.getWorstSchool($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#         #     $scope.worstSchools = data.result.records

#         #   OpenDataApi.mostImprovedSchools($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#         #     $scope.mostImprovedSchools = data.result.records

#         #   OpenDataApi.leastImprovedSchools($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#         #     $scope.leastImprovedSchools = data.result.records

#         #   OpenDataApi.getGlobalPassrate($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#         #     $scope.passrate = parseFloat data.result.records[0].avg

#         #   OpenDataApi.getPassOverTime($scope.schoolType, $scope.rankBest, $scope.moreThan40).success (data) ->
#         #     parseList = data.result.records.map (x) -> {key: x.YEAR_OF_RESULT, val: parseInt(x.avg)}
#         #     $scope.globalpassratetime = parseList

#         # $scope.$watch '[rankBest, moreThan40, selectedYear]', updateDashboard
#         # $scope.rankBest = 'performance' if (!$scope.rankBest? and $scope.schoolType is 'primary')
# =======
#                 $scope.selectedSchool.pass_by_10 = Math.round item.pass_2014/10
#             $scope.selectedSchool.fail_by_10 = 10 - $scope.selectedSchool.pass_by_10
#             OpenDataApi.getSchoolPassOverTime($scope.schoolType, $scope.rankBest, item.CODE).success (data) ->
#               parseList = chartSrv.parsePassRateTime data, $scope.years
#               $scope.passratetime = parseList

#             # TODO: cleaner way?
#             # Ensure the parent div has been fully rendered
#             setTimeout( () ->
#               if $scope.viewMode == 'schools'
#                 chartSrv.drawNationalRanking item, $scope.worstSchools[0].RANK
#             , 400)

#         $scope.getTimes = (n) ->
#             new Array(n)

#         $scope.anchorScroll = () ->
#             $anchorScroll()

#         WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'avg_pass_rate', order: 'DESC'}).then (result) ->
#           $scope.bpdistrics = result.data.rows
#         WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'avg_pass_rate', order: 'ASC'}).then (result) ->
#           $scope.wpdistrics = result.data.rows
#         WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'change', order: 'DESC'}).then (result) ->
#           $scope.midistrics = result.data.rows
#         WorldBankApi.getTopDistricts({educationLevel: $scope.schoolType, metric: 'change', order: 'ASC'}).then (result) ->
#           $scope.lidistrics = result.data.rows
#         MetricsSrv.getPupilTeacherRatio({level: $scope.schoolType}).then (data) ->
#           $scope.pupilTeacherRatio = data.rate

#         updateDashboard = () ->
#           OpenDataApi.getBestSchool($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#             $scope.bestSchools = data.result.records

#           OpenDataApi.getWorstSchool($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#             $scope.worstSchools = data.result.records

#           OpenDataApi.mostImprovedSchools($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#             $scope.mostImprovedSchools = data.result.records

#           OpenDataApi.leastImprovedSchools($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#             $scope.leastImprovedSchools = data.result.records

#           OpenDataApi.getGlobalPassrate($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#             $scope.passrate = parseFloat data.result.records[0].avg

#           OpenDataApi.getGlobalChange($scope.schoolType, $scope.rankBest, $scope.moreThan40, $scope.selectedYear).success (data) ->
#             records = data.result.records
#             $scope.passRateChange = if(records.length == 2) then parseInt(records[1].avg - records[0].avg) else 0

#           OpenDataApi.getPassOverTime($scope.schoolType, $scope.rankBest, $scope.moreThan40).success (data) ->
#             $scope.globalpassratetime = chartSrv.parsePassRateTime data, $scope.years

#         $scope.$watch '[rankBest, moreThan40, selectedYear]', updateDashboard
#         $scope.rankBest = 'performance' if (!$scope.rankBest? and $scope.schoolType is 'primary')
#         OpenDataApi.getYears($scope.schoolType, $scope.rankBest).success (data) ->
#           parseList = data.result.records.map (x) -> parseInt(x.YEAR_OF_RESULT)
#           $scope.years = parseList
#         $scope.selectYear = (y) ->
#           $scope.selectedYear = y
# >>>>>>> edudash-2.0
]
