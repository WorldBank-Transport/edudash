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
    '$timeout', 'MetricsSrv', 'colorSrv', 'OpenDataApi', 'loadingSrv'

    ($scope, $window, $routeParams, $anchorScroll, $http, leafletData,
    _, $q, WorldBankApi, layersSrv, chartSrv, $log, $location, $translate,
    $timeout, MetricsSrv, colorSrv, OpenDataApi, loadingSrv) ->

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

        # state transitioners
        angular.extend $scope,
          setYear: (newYear) -> $scope.year = newYear
          setViewMode: (newMode) -> $scope.viewMode = newMode
          setVisMode: (newMode) -> $scope.visMode = newMode
          setSchoolType: (newType) -> $location.path "/dashboard/#{newType}/"
          hover: (code) ->  (findSchool code).then ((s) -> $scope.hovered = s), $log.error
          keepHovered: -> $scope.hovered = $scope.lastHovered
          unHover: -> $scope.hovered = null
          select: (code) -> (findSchool code).then ((s) -> $scope.selected = s), $log.error
          search: (q) -> search q

        # view util functions
        angular.extend $scope,
          Math: Math


        ###*
        # Assigns computed values to the $scope when dependencies change
        # @param {string} what The property of $scope to be updated
        # @param {object} opts
        # @param {string[]} opts.dependencies Properties of $scope that trigger a recompute
        # @param {function} opts.computer Computes the new value
        # @param {boolean} [opts.waitForPromise] Update $scope only after the value resolves
        # @param {function} [opts.filter] Conditionally update $scope
        ###
        $scope.compute = (what, opts) ->
          unless typeof what == 'string'
            throw new Error 'First parameter of $scope.compute must be a string'
          unless opts?
            throw new Error 'opts must be an object'
          unless opts.dependencies instanceof Array
            throw new Error 'opts.dependencies must be an array of strings'
          unless typeof opts.computer == 'function'
            throw new Error 'opts.computer must be a function'

          setResult = (result) => this[what] = result

          this.$watchGroup opts.dependencies, (current, old) ->
            if opts.filter?
              unless typeof opts.filter == 'function'
                throw new Error 'opts.filter must be a function'
              unless opts.filter current, old
                return
            result = opts.computer current, old
            if opts.waitForPromise == true
              unless result? and typeof result.then == 'function'
                throw new Error 'waitForPromise requires that opts.computer returns a Promise'
              result.then setResult, (err) -> throw err
            else
              setResult result

        $scope.$watchGroup ['viewMode', 'year', 'schoolType', 'rankBy', 'moreThan40'],
          ([viewMode, year, rest...], [oldViewMode]) -> if year?
            if viewMode == 'schools' then loadSchools viewMode, year, rest...
            else if oldViewMode == 'schools' then clearSchools()

        $scope.compute 'yearAggregates',
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

        # this watch only does side-effects. would be nice to eliminate
        $scope.$watch 'allSchools', (schoolsP) -> if schoolsP?
          loadingSrv.containerLoad schoolsP, document.getElementById mapId
          schoolsP.then (schools) ->
            if $scope.selected?
              $scope.select $scope.selected.CODE

        $scope.compute '_schoolDetails',
          dependencies: ['allSchools'],
          waitForPromise: true
          computer: ([allSchools]) ->
            unless allSchools?
              $q.when null
            else
              $q (resolve, reject) -> allSchools.then ->
                OpenDataApi.getSchoolDetails $scope
                  .then resolve, reject

        $scope.compute 'schoolCodeMap',
          dependencies: ['allSchools', '_schoolDetails']
          waitForPromise: true  # unwraps the promise
          computer: ([allSchools, details]) ->
            $q (resolve, reject) ->
              unless allSchools
                resolve null
              else
                allSchools
                  .then (basics) ->
                    map = _(basics).reduce ((byCode, s) ->
                      byCode[s.CODE] = s
                      byCode
                    ), {}
                    if details?
                      _(details).each (s) -> angular.extend map[s.CODE], s
                    else
                    resolve map
                  .catch reject

        $scope.compute 'rankedBy',
          dependencies: ['allSchools', 'rankBy', 'schoolCodeMap']
          computer: ([allSchools, rankBy, map]) -> if allSchools? and map?
            $q (resolve, reject) ->
              allSchools.then ((schools) ->
                resolve rankSchools schools, switch rankBy
                  when 'performance' then ['RANK']
                  when 'improvement' then ['CHANGE_PREVIOUS_YEAR', true]
                  when null then ['CHANGE_PREVIOUS_YEAR', true]  # secondary
                  else reject "invalid rankBy: '#{rankBy}'"
              ), reject

        $scope.compute 'filteredSchools',
          dependencies: ['allSchools']
          computer: ([allSchools]) -> if allSchools?
            $q (res, x) -> allSchools.then res, x

        $scope.compute 'pins',
          dependencies: ['filteredSchools', 'year', 'schoolType', 'moreThan40']
          waitForPromise: true
          computer: ([schoolsP, year, schoolType, moreThan40], [oldSchools]) ->
            $q (resolve, reject) ->
              unless schoolsP?
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

        $scope.compute 'lastHovered',
          dependencies: ['hovered']
          filter: ([thing]) -> thing?
          computer: ([thing]) -> thing

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
        $scope.$watch 'viewMode', (newMode, oldMode) ->
          if newMode not in ['schools', 'national', 'regional']
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

        loadSchools = (viewMode, year, schoolType, rankBy, moreThan40) ->
          $scope.allSchools = OpenDataApi.getSchools
              year: year
              schoolType: schoolType
              subtype: rankBy
              moreThan40: moreThan40
            .catch (err) -> $log.error err
          # leaving this as is for now, since we don't have this at school level
          MetricsSrv.getPupilTeacherRatio({level: schoolType}).then (data) ->
            $scope.pupilTeacherRatio = data.rate

        clearSchools = ->
          $scope.allSchools = null
          $scope.filteredSchools = null
          $scope.pins = null
          $scope.rankedBy = null
          $scope.schoolMarker = null

        setSchool = (school) ->
          latlng = [school.LATITUDE, school.LONGITUDE]
          markSchool latlng
          leafletData.getMap(mapId).then (map) ->
            map.setView latlng, (Math.max 9, map.getZoom())
          rankField = switch $scope.rankBy
            when 'performance' then 'RANK'
            when 'improvement' then 'CHANGE_PREVIOUS_YEAR'
            when null then 'CHANGE_PREVIOUS_YEAR'  # secondary TODO fix me
            else throw new Error "invalid rankBy: '#{$scope.rankBy}'"
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

        getSchoolPin = (code) -> $q (resolve, reject) ->
          layer = $scope.pins.getLayer code
          if layer?
            resolve layer
          else
            reject "No pin found for school code #{code}"

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
          if ob not in ['CHANGE_PREVIOUS_YEAR', 'RANK']
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


        # todo: figure out if these are needed
        $scope.getTimes = (n) ->
            new Array(n)

        $scope.anchorScroll = () ->
            $anchorScroll()

]
