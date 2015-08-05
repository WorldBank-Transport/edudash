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
    '$timeout', 'MetricsSrv', 'colorSrv', 'OpenDataApi', 'loadingSrv', 'topojson',
    'staticApi', 'watchComputeSrv',

    ($scope, $window, $routeParams, $anchorScroll, $http, leafletData,
    _, $q, WorldBankApi, layersSrv, chartSrv, $log, $location, $translate,
    $timeout, MetricsSrv, colorSrv, OpenDataApi, loadingSrv, topojson,
    staticApi, watchComputeSrv) ->

        # other state
        layers = {}
        currentLayer = null

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
          allSchools: null
          filteredSchools: null
          pins: null
          rankBy: null  # performance or improvement for primary
          rankedBy: null
          moreThan40: null  # students, for secondary schools
          regions: null
          polygons: null
          filterPassRateP: # To be used in primary school view 
            range: {
              min: 0,
              max: 100
            },
            minValue: 0,
            maxValue: 100
           filterPassRateS: # To be used in secondary school view 
            range: {
              min: 0,
              max: 10
            },
            minValue: 0,
            maxValue: 10

        # state transitioners
        angular.extend $scope,
          setYear: (newYear) -> $scope.year = newYear
          setViewMode: (newMode) -> $scope.viewMode = newMode
          setVisMode: (newMode) -> $scope.visMode = newMode
          setSchoolType: (newType) -> $location.path "/dashboard/#{newType}/"
          hover: (id) -> hoverThing id
          keepHovered: -> $scope.hovered = $scope.lastHovered
          unHover: -> $scope.hovered = null
          select: (code) -> (findSchool code).then ((s) -> $scope.selected = s), $log.error
          search: (q) -> search q

        # view util functions
        angular.extend $scope,
          Math: Math


        watchCompute = watchComputeSrv $scope

        watchCompute 'allSchools',
          dependencies: ['viewMode', 'year', 'schoolType', 'rankBy', 'moreThan40']
          computer: ([viewMode, year, rest...]) ->
            if year? then loadSchools viewMode, year, rest...
            else
              null

        watchCompute 'regions',
          dependencies: ['viewMode']
          computer: ([viewMode]) ->
            if viewMode == 'regions' then loadRegions() else null

        watchCompute 'detailedRegions',
          dependencies: ['regions', 'allSchools']
          waitForPromise: true
          computer: ([regions, allSchools]) -> $q (resolve, reject) ->
            unless regions? and allSchools?
              resolve null
            else
              $q.all
                  regions: regions
                  schools: allSchools
                .then ({regions, schools}) ->
                  detailsByRegion = {}
                  schoolsByRegion = groupBy schools, 'REGION'
                  for region, schools of schoolsByRegion
                    detailsByRegion[region] =
                      # TODO: should these averages be weighted by number of pupils?
                      AVG_GPA: averageProp schools, 'AVG_GPA'
                      CHANGE_PREVIOUS_YEAR_GPA: averageProp schools, 'CHANGE_PREVIOUS_YEAR_GPA'
                      AVG_MARK: averageProp schools, 'AVG_MARK'
                      CHANGE_PREVIOUS_YEAR_MARK: 'CHANGE_PREVIOUS_YEAR_MARK'  # TODO: confirm
                      PASS_RATE: averageProp schools, 'PASS_RATE'
                  resolve regions.map (region) ->
                    # TODO: warn about regions mismatch
                    properties = angular.extend detailsByRegion[region.id] or {},
                      NAME: region.id
                    angular.extend region, properties: properties

                .catch reject

        # When we get per-school pupil-teacher ratio data, we can compute this client-side
        watchCompute 'pupilTeacherRatio',
          dependencies: ['year', 'schoolType']
          waitForPromise: true
          computer: ([year, schoolType]) ->
            $q (resolve, reject) ->
              if year?
                MetricsSrv.getPupilTeacherRatio(level: schoolType)
                  .then ((data) -> resolve data.rate), reject
              else
                resolve null

        watchCompute 'yearAggregates',
          dependencies: ['schoolType', 'rankBy', 'moreThan40'],
          waitForPromise: true,
          computer: ([schoolType, rankBy, moreThan40]) -> $q (resolve, reject) ->
            OpenDataApi.getYearAggregates schoolType, rankBy, moreThan40
              .then (years) ->
                resolve _(years).reduce ((agg, y) ->
                  agg[y.YEAR_OF_RESULT] =
                    PASS_RATE: y.average_pass_rate
                  agg
                ), {}
              .catch reject

        watchCompute 'schoolCodeMap',
          dependencies: ['viewMode', 'allSchools']
          waitForPromise: true  # unwraps the promise
          computer: ([viewMode, allSchools]) -> $q (resolve, reject) ->
            unless viewMode == 'schools' and allSchools?
              resolve null
            else
              allSchools
                .then (basics) ->
                  resolve _(basics).reduce ((byCode, s) ->
                    byCode[s.CODE] = s
                    byCode
                  ), {}
                .catch reject

        watchCompute 'regionIdMap',
          dependencies: ['detailedRegions']
          computer: ([regions]) ->
            unless regions?
              null
            else
              regions.reduce ((map, region) ->
                map[region.id] = region
                map
              ), {}

        watchCompute 'rankedBy',
          dependencies: ['viewMode', 'allSchools', 'rankBy', 'schoolCodeMap']
          computer: ([viewMode, allSchools, rankBy, map]) ->
            unless viewMode == 'schools' and allSchools? and map?
              null
            else
              $q (resolve, reject) ->
                allSchools.then ((schools) ->
                  resolve rankSchools schools, [getMetricField(), true]
                ), reject

        watchCompute 'filteredSchools',
          dependencies: ['viewMode', 'allSchools']
          computer: ([viewMode, allSchools]) ->
            unless viewMode == 'schools' and allSchools?
              null
            else
              $q (res, x) -> allSchools.then res, x

        watchCompute 'pins',
          dependencies: ['filteredSchools', 'year', 'schoolType', 'moreThan40']
          waitForPromise: true
          computer: ([schoolsP, year, schoolType, moreThan40], [oldSchoolsP]) ->
            $q (resolve, reject) ->
              # Only continue when we have a new promise for the schools.
              # year, schoolType. etc. are dependencies because we need them
              # for the layerId, but they can sometimes trigger before we have
              # an up-to-date promise for the schools themselves.
              unless schoolsP? and schoolsP != oldSchoolsP
                resolve null
              else
                layerId = "schools-#{year}-#{schoolType}-#{moreThan40}"
                schoolsP.then ((schools) ->
                  resolve layersSrv.addFastCircles layerId, mapId,
                    getData: -> $q (res, rej) ->
                      map = (data) -> if data?
                        res data.map (s) -> [ s.LATITUDE, s.LONGITUDE, s.CODE ]
                      schoolsP.then map, rej
                    options:
                      className: 'school-location'
                      radius: 8
                      onEachFeature: processPin
                ), reject

        watchCompute 'polygons',
          dependencies: ['detailedRegions']
          waitForPromise: true
          computer: ([regions]) -> $q (resolve, reject) ->
            unless regions?
              resolve null
            else
              resolve layersSrv.addGeojsonLayer 'regions', mapId,
                getData: -> $q.when
                  type: 'FeatureCollection'
                  features: regions
                options: onEachFeature: processPoly

        watchCompute 'lastHovered',
          dependencies: ['hovered']
          computer: ([thing], [oldThing]) -> thing or oldThing

        # side-effects only
        $scope.$watch 'allSchools', (schoolsP) -> if schoolsP?
          loadingSrv.containerLoad schoolsP, document.getElementById mapId
          schoolsP.then (schools) ->
            if $scope.selected?
              $scope.select $scope.selected.CODE

        # side-effects only
        $scope.$watch 'pins', (blah, oldPins) -> if oldPins?
          leafletData.getMap(mapId).then (map) -> map.removeLayer oldPins

        # side-effects only
        $scope.$watch 'schoolMarker', (blah, oldMarker) -> if oldMarker?
          oldMarker.then (marker) ->
              leafletData.getMap(mapId).then (map) -> map.removeLayer marker

        # side-effects only
        $scope.$watchGroup ['pins', 'visMode'], ([pins]) -> if pins?
          pins.eachVisibleLayer colorPin

        # side-effects only
        $scope.$watchGroup ['polygons', 'regionIdMap'],
          ([polygons, regionIdMap]) ->
            if polygons? and regionIdMap?
              polygons.eachLayer (layer) ->
                colorPoly regionIdMap[layer.feature.id], layer

        # side-effects only
        $scope.$watch 'viewMode', (newMode, oldMode) ->
          if newMode not in ['schools', 'national', 'regions']
            console.error 'changed to invalid view mode:', newMode
            return
          # unless newMode == oldMode  # doesnt work for initial render
          leafletData.getMap(mapId).then (map) ->
            unless currentLayer == null
              map.removeLayer currentLayer
              currentLayer = null

        # side-effects only
        $scope.$watch 'hovered', (thing, oldThing) ->
          if thing != null
            if $scope.viewMode == 'schools'
              getSchoolPin(thing.CODE).then (pin) ->
                pin.bringToFront()
                pin.setStyle
                  color: '#05a2dc'
                  weight: 5
                  opacity: 1
                  fillOpacity: 1
            else if $scope.viewMode == 'regions'
              getRegionLayer(thing.id).then (layer) ->
                layer.bringToFront()
                layer.setStyle
                  weight: 6
                  opacity: 1
                  fillOpacity: 0.9

          if oldThing != null
            if $scope.viewMode == 'schools'
              getSchoolPin(oldThing.CODE).then (pin) ->
                pin.setStyle
                  color: '#fff'
                  weight: 2
                  opacity: 0.5
                  fillOpacity: 0.6
            else if $scope.viewMode == 'regions'
              getRegionLayer(oldThing.id).then (layer) ->
                layer.setStyle
                  weight: 2
                  opacity: 0.6
                  fillOpacity: 0.75

        # side-effects only
        $scope.$watch 'selected', (school) ->
          if school != null
            if $scope.viewMode == 'schools'
              setSchool school

        $scope.$on 'filtersToggle', (event, opts) ->
          $scope.filtersHeight = opts.height

        loadSchools = (viewMode, year, schoolType, rankBy, moreThan40) ->
          OpenDataApi.getSchools
            year: year
            schoolType: schoolType
            subtype: rankBy
            moreThan40: moreThan40

        loadRegions = ->
          $q (resolve, reject) ->
            staticApi.getRegions()
              .then (topo) ->
                {features} = topojson.feature topo, topo.objects.tz_Regions
                resolve features.map (feature) ->
                  type: feature.type
                  id: feature.properties.name.toUpperCase()
                  geometry: feature.geometry
              .catch reject

        hoverThing = (id) ->
          if $scope.viewMode == 'schools'
            findSchool id
              .then (s) -> $scope.hovered = s
              .catch $log.error
          else if $scope.viewMode == 'regions'
            findRegion id
              .then (r) -> $scope.hovered = r
              .catch $log.error

        setSchool = (school) ->
          latlng = [school.LATITUDE, school.LONGITUDE]
          markSchool latlng
          leafletData.getMap(mapId).then (map) ->
            map.setView latlng, (Math.max 9, map.getZoom())
          rankField = getMetricField
          if school[rankField]?
            $scope.allSchools.then (schools) ->
              ranked = rankSchools schools, [rankField, false, true]
              nationalRank = ranked.indexOf school
              chartSrv.drawNationalRanking nationalRank+1, ranked.length
          unless school.ranks?
            $q.all
                region: (rank school, 'REGION')
                district: (rank school, 'DISTRICT')
              .then (ranks) ->
                school.ranks = ranks

          unless school.yearAggregates?
            OpenDataApi.getSchoolAggregates $scope.schoolType, $scope.rankBy, school.CODE
              .then (data) ->
                school.yearAggregates =
                  values: _(data).reduce ((agg, year) ->
                    agg[year.YEAR_OF_RESULT] =
                      PASS_RATE: year.PASS_RATE
                    agg
                  ), {}
                  years: $scope.years
                school.change = if school.yearAggregates.values[$scope.year-1]? then Math.round(school.yearAggregates.values[$scope.year].PASS_RATE - school.yearAggregates.values[$scope.year-1].PASS_RATE) else undefined

        findSchool = (code) ->
          $q (resolve, reject) ->
            if $scope.allSchools? and $scope.schoolCodeMap?
              findIt = (schools) ->
                if $scope.schoolCodeMap[code]?
                  resolve $scope.schoolCodeMap[code]
                else
                  reject "Could not find school by code '#{code}'"
              $scope.allSchools.then findIt, reject
            else
              reject 'No schools to find from'

        findRegion = (id) ->
          $q (resolve, reject) ->
            if $scope.regionIdMap?
              if $scope.regionIdMap[id]?
                resolve $scope.regionIdMap[id]
              else
                reject "Could not find region by id '#{id}'"
            else
              reject 'No regions to find from'

        getSchoolPin = (code) -> $q (resolve, reject) ->
          layer = $scope.pins.getLayer code
          if layer?
            resolve layer
          else
            reject "No pin found for school code #{code}"

        getRegionLayer = (id) -> $q (resolve, reject) ->
          unless $scope.polygons?
            reject 'No polygon layers to find from'
          else
            layer = null
            $scope.polygons.eachLayer (l) ->
              if l.feature.id == id
                if layer?
                  $log.warn "Multiple layers found for id #{id}"
                layer = l
            unless layer?
              reject "No region layer found for '#{id}'"
            else
              resolve layer

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
                .sort (a, b) -> a.rank - b.rank # TODO fix me, this should be base on the type of dashboard
              resolve
                rank: (ranked.indexOf school) + 1
                total: ranked.length

            $scope.allSchools.then rankSchool, reject

        rankSchools = (schools, [orderBy, desc, all]) ->
          ob = orderBy
          if ob not in ['CHANGE_PREVIOUS_YEAR',
                        'RANK',
                        'PASS_RATE',
                        'AVG_GPA',
                        'CHANGE_PREVIOUS_YEAR_GPA',
                        'AVG_MARK' ]
            throw new Error "invalid orderBy: '#{ob}'"
          list = _.unique(schools
            .filter (s) -> s[ob]?
            .sort (a, b) -> if desc then b[ob] - a[ob] else a[ob] - b[ob]
          )
          if all then list else list.slice 0, 20


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

        processPoly = (feature, layer) ->
          colorPoly feature, layer
          layer.on 'mouseover', -> $scope.$apply ->
            $scope.hover feature.id
          layer.on 'mouseout', -> $scope.$apply ->
            $scope.unHover()
          layer.on 'click', -> $scope.$apply ->
            $scope.select feature.id


        colorPin = (code, l) -> findSchool(code).then (school) ->
          v = switch
            when $scope.visMode == 'passrate' && $scope.schoolType == 'primary' then school.AVG_MARK
            when $scope.visMode == 'passrate' && $scope.schoolType == 'secondary' then school.AVG_GPA
            when $scope.visMode == 'ptratio' then school.PUPIL_TEACHER_RATIO
          l.setStyle colorSrv.pinStyle v, $scope.visMode, $scope.schoolType

        colorPoly = (feature, layer) ->
          v = feature.properties[getMetricField()]
          layer.setStyle colorSrv.areaStyle v, $scope.visMode, $scope.schoolType

        groupBy = (rows, prop) ->
          grouped = {}
          for row in rows
            unless grouped[row[prop]]?
              grouped[row[prop]] = []
            grouped[row[prop]].push row
          grouped

        average = (nums) -> (nums.reduce (a, b) -> a + b) / nums.length

        averageProp = (rows, prop) -> average _(rows).map (r) -> r[prop]

        markSchool = (latlng) ->
          unless $scope.schoolMarker?
            icon = layersSrv.awesomeIcon markerColor: 'blue', icon: 'map-marker'
            $scope.schoolMarker = layersSrv.marker 'school-marker', mapId,
              latlng: latlng
              options: icon: icon

          $scope.schoolMarker.then (marker) ->
            marker.setLatLng latlng

        search = (query) ->
          if query?
            OpenDataApi.search $scope.schoolType, $scope.rankBy, query, $scope.year
              .then (data) -> $q.all _(data).map (s) -> findSchool s.CODE
                .then (schools) ->
                  $scope.searchText = query
                  $scope.searchChoices = _.unique schools

        getMetricField = () ->
          switch
            when $scope.schoolType == 'secondary' && $scope.rankBy == 'performance' then 'AVG_GPA'
            when $scope.schoolType == 'secondary' && $scope.rankBy == 'improvement' then 'CHANGE_PREVIOUS_YEAR_GPA'
            when $scope.schoolType == 'primary' && $scope.rankBy == 'performance' then 'AVG_MARK'
            when $scope.schoolType == 'primary' && $scope.rankBy == 'improvement' then 'CHANGE_PREVIOUS_YEAR_MARK' # TODO to be confirm


        # todo: figure out if these are needed
        $scope.getTimes = (n) ->
            new Array(n)

        $scope.anchorScroll = () ->
            $anchorScroll()

]
