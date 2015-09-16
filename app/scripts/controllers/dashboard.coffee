'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:DashboardsCtrl
 # @description
 # # DashboardsCtrl
 # Controller of the edudashApp
###
angular.module('edudashAppCtrl').controller 'DashboardCtrl', (
  $location, $log, $q, $routeParams, $scope, $timeout,
  _, api, bracketsSrv, colorSrv, layersSrv, leafletData, loadingSrv,
  utils, watchComputeSrv ) ->

        if $routeParams.type isnt 'primary' and $routeParams.type isnt 'secondary'
          $timeout -> $location.path '/'

        # app state
        angular.extend $scope,
          year: null  # set after init
          years: null
          yearAggregates: null
          visMetric: null
          viewMode: null  # set after init
          visMode: 'passrate'
          schoolType: $routeParams.type
          polyType: null
          hovered: null
          lastHovered: null
          allSchools: null
          filteredSchools: null
          pins: null
          selectedSchoolCode: null
          selectedSchool: null
          selectedSchoolLayer: null
          selectedPolyId: null
          selectedPoly: null
          selectedPolyLayer: null
          rankBy: null  # performance or improvement for primary
          moreThan40: null  # students, for secondary schools
          polygons: null
          detailedPolys: null
          polyLayer: null
          range:
            passrate:
              min: 0
              max: 100
            ptratio:
              min: 0
              max: 100
            gpa:
              min: 0
              max: 5
          ptratioComputedMax: 100
          gpaComputedMax: 5

        # state transitioners
        angular.extend $scope,
          setYear: (newYear) -> $scope.year = newYear
          setViewMode: (newMode) -> $scope.viewMode = newMode
          setVisMode: (newMode) -> $scope.visMode = newMode
          setPolyType: (polyType) -> $scope.polyType = polyType
          togglePolygons: (polyType) -> togglePolygons polyType
          hover: (id) -> hoverThing id
          keepHovered: -> $scope.hovered = $scope.lastHovered
          unHover: -> $scope.hovered = null
          selectSchool: (code) -> $scope.selectedSchoolCode = code
          selectPoly: (id) -> $scope.selectedPolyId = id
          search: (q) -> search q
          hasBadge: (b, st, v) -> bracketsSrv.hasBadge b, st, v
          getBracket: (v, m) -> bracketsSrv.getBracket v, (m or $scope.visMetric)
          getColor: (v, m) -> colorSrv.color $scope.getBracket v, m
          getArrow: (v, m) -> colorSrv.arrow $scope.getBracket v, m
          resetView: -> resetView()

        # view util functions
        angular.extend $scope,
          Math: Math

        # controller constants
        mapId = 'map'

        watchCompute = watchComputeSrv $scope
        watchToLayer = layersSrv.scopeToLayer $scope, mapId

        watchCompute 'visMetric',
          dependencies: ['visMode']
          computer: ([visMode]) ->
            bracketsSrv.getVisMetric visMode

        watchCompute 'allSchools',
          dependencies: ['viewMode', 'year', 'schoolType', 'moreThan40', 'rankBy']
          computer: ([viewMode, year, rest...]) ->
            if year? then api.getSchools year, rest...
            else
              $q.when []

        watchCompute 'ptratioComputedMax',
          dependencies: ['allSchools']
          waitForPromise: true
          computer: ([allSchools]) -> utils.max allSchools, 'PUPIL_TEACHER_RATIO', 10

        watchCompute 'gpaComputedMax',
          dependencies: ['allSchools']
          waitForPromise: true
          computer: ([allSchools]) -> utils.max allSchools, 'AVG_GPA', 5

        watchCompute 'polygons',
          dependencies: ['viewMode', 'polyType']
          computer: ([viewMode, polyType]) ->
            unless viewMode == 'polygons'
              null
            else
              switch polyType
                when 'regions' then api.getRegions()
                when 'districts' then api.getDistricts()
                else (
                  $log.warn "unknown polyType '#{polyType}'"
                  null
                )

        watchCompute 'detailedPolys',
          dependencies: ['polygons', 'allSchools', 'polyType', 'schoolType']
          waitForPromise: true
          computer: ([polygons, allSchools, polyType, schoolType], [oldPolys, oldSchools]) ->
            $q (resolve, reject) ->
              unless polygons? and allSchools? and (polygons != oldPolys or allSchools != oldSchools)
                resolve null
              else
                $q.all
                    polys: polygons
                    schools: allSchools
                  .then ({polys, schools}) ->
                    detailsByPoly = getDetailsByPoly schools, polyType, schoolType
                    resolve polys.map (poly) ->
                      # TODO: warn about polys mismatch
                      properties = angular.extend detailsByPoly[poly.id] or {},
                        NAME: poly.id
                      angular.extend poly, properties: properties

                  .catch reject

        # When we get per-school pupil-teacher ratio data, we can compute this client-side
        watchCompute 'pupilTeacherRatio',
          dependencies: ['allSchools']
          waitForPromise: true
          computer: ([allSchools]) ->
            $q (resolve, reject) ->
              if allSchools?
                allSchools.then (data) ->
                  total = _(data).reduce ((memo, school) ->
                    memo + school.PUPIL_TEACHER_RATIO
                  ), 0
                  resolve if isNaN(total) then null else total/data.length
              else
                resolve null

        watchCompute 'yearAggregates',
          dependencies: ['schoolType', 'rankBy', 'moreThan40'],
          waitForPromise: true,
          computer: ([schoolType, rankBy, moreThan40]) -> $q (resolve, reject) ->
            api.getYearAggregates schoolType, rankBy, moreThan40
              .then (years) ->
                resolve _(years).reduce ((agg, y) ->
                  agg[y.YEAR_OF_RESULT] =
                    PASS_RATE: y.average_pass_rate
                    color: colorSrv.color bracketsSrv.getBracket y.average_pass_rate, 'PASS_RATE'
                  agg
                ), {}
              .catch reject

        watchCompute 'schoolCodeMap',
          dependencies: ['viewMode', 'allSchools']
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

        watchCompute 'polyIdMap',
          dependencies: ['detailedPolys']
          computer: ([polygons]) -> $q (resolve, reject) ->
            unless polygons?
              resolve {}
            else
              resolve polygons.reduce ((map, polygon) ->
                map[polygon.id] = polygon
                map
              ), {}

        watchCompute 'rankedSchools',
          dependencies: ['viewMode', 'schoolType', 'allSchools']
          computer: ([viewMode, schoolType, allSchools]) ->
            # check viewMode to ensure we don't sort schools for polygon views
            unless viewMode == 'schools' and allSchools? and schoolType?
              null
            else
              performance: utils.rankAll allSchools,
                bracketsSrv.getSortMetric schoolType, 'performance'
              improvement: utils.rankAll allSchools,
                bracketsSrv.getSortMetric schoolType, 'improvement'

        watchCompute 'filteredSchools',
          dependencies: ['viewMode', 'allSchools', 'range.passrate.min',
                         'range.passrate.max', 'range.ptratio.min', 'range.ptratio.max', 'range.gpa.min', 'range.gpa.max']
          computer: ([viewMode, allSchools, prMin, prMax, ptMin, ptMax, gpaMin, gpaMax]) ->
            unless viewMode == 'schools' and allSchools?
              null
            else
              $q (resolve, reject) -> allSchools.then ((schools) ->
                filtered = schools
                  .filter utils.rangeFilter 'PASS_RATE', prMin, prMax
                  .filter utils.rangeFilter 'PUPIL_TEACHER_RATIO', ptMin, ptMax
                if $scope.schoolType is 'secondary'
                  filtered = filtered.filter utils.rangeFilter 'AVG_GPA', gpaMin, gpaMax
                resolve filtered
              ), reject

        watchCompute 'pins',
          dependencies: ['filteredSchools']
          waitForPromise: true
          computer: ([schoolsP]) ->
            $q (resolve, reject) ->
              unless schoolsP?
                resolve null
              else
                schoolsP.then ((schools) ->
                  resolve layersSrv.getFastCircles
                    getData: -> $q (res, rej) ->
                      map = (data) -> if data?
                        res data.map (s) -> [ s.LATITUDE, s.LONGITUDE, s.CODE ]
                      schoolsP.then map, rej
                    options:
                      className: 'school-location'
                      radius: 8
                      onEachFeature: processPin
                ), reject

        watchCompute 'polyLayer',
          dependencies: ['detailedPolys']
          waitForPromise: true
          computer: ([polys]) -> $q (resolve) ->
            unless polys?
              resolve null
            else
              resolve layersSrv.getGeojsonLayer
                getData: -> $q.when
                  type: 'FeatureCollection'
                  features: polys
                options: onEachFeature: processPoly

        watchCompute 'lastHovered',
          dependencies: ['hovered']
          computer: ([thing], [oldThing]) -> thing or oldThing

        watchCompute 'selectedSchool',
          dependencies: ['schoolCodeMap', 'selectedSchoolCode']
          waitForPromise: true
          computer: ([map, code]) ->
            $q.when if code? then (utils.lookup map, code) else null

        watchCompute 'selectedPoly',
          dependencies: ['polyIdMap', 'selectedPolyId']
          waitForPromise: true
          computer: ([map, id], [..., oldId]) ->
            if id?  # something is selected, get it
              if id != oldId  # A new polygon is selected
                utils.lookup map, id
              else
                # So, we're only here because polyIdMap updated,
                # which happens when we switch regions -> districts
                # or districts -> schools.
                # But the id hasn't changed, so we don't want to
                # make a new selection.
                # ... we want to keep the old polygon selected
                $q.when $scope.selectedPoly
            else
              # nothing is selected, so really reset now
              $q.when null

        watchCompute 'selectedSchoolLayer',
          dependencies: ['selectedSchool']
          computer: ([school]) -> if school?
            layersSrv.marker
              latlng: [school.LATITUDE, school.LONGITUDE]
              options: icon: layersSrv.awesomeIcon
                markerColor: 'blue'
                icon: 'map-marker'

        watchCompute 'selectedPolyLayer',
          dependencies: ['selectedPoly']
          computer: ([poly]) -> if poly?
            layersSrv.getGeojsonLayer
              getData: -> $q.when poly
              options: onEachFeature: (feature, layer) ->
                colorPoly feature, layer
                layer.setStyle colorSrv.polygonSelect()

        # add and remove computed layers from the map
        watchToLayer 'pins'
        watchToLayer 'polyLayer'
        watchToLayer 'selectedSchoolLayer'
        watchToLayer 'selectedPolyLayer'

        # side-effect: show spinner on the map when schools are loading
        $scope.$watch 'allSchools', (schoolsP) -> if schoolsP?
          loadingSrv.containerLoad schoolsP, document.getElementById mapId

        # side-effect: re-select a school after the year changes
        $scope.$watch 'allSchools', (schoolsP) -> if schoolsP?
          schoolsP.then (schools) ->
            if $scope.selectedSchool? and $scope.viewMode == 'schools'
              $scope.selectedCodeYear =  # TODO: fix issue with 'selectedSchool' watchCompute and remove this assignment
                code: $scope.selectedSchool.CODE
                year: $scope.year
              $scope.selectSchool $scope.selectedSchool.CODE

        # TODO: fix issue with 'selected' watchCompute and remove this entire $watch
        $scope.$watch 'selectedCodeYear', (selectedCodeYear) -> if selectedCodeYear?
          (utils.lookup $scope.schoolCodeMap, selectedCodeYear.code).then (school) ->
            $scope.selectedSchool = school

        # side-effect: show spinner on the map for polygons load
        $scope.$watch 'polygons', (polysP) -> if polysP?
          loadingSrv.containerLoad polysP, document.getElementById mapId

        # side-effect: load full school data when the school is selected
        $scope.$watch 'selectedSchool', (school) -> if school? and $scope.viewMode == 'schools'

          # Add rankings to the school object
          criteria = bracketsSrv.getRank $scope.schoolType
          $q.all
              national: (rank school, 'NATIONAL', criteria)
              region: (rank school, 'REGION', criteria)
              district: (rank school, 'DISTRICT', criteria)
            .then (ranks) ->
              school.ranks = ranks

          # Add any badges
          $q.all
              top100: bracketsSrv.hasBadge 'top-100', $scope.schoolType, school, $scope.allSchools
              mostImproved: bracketsSrv.hasBadge 'most-improved', $scope.schoolType, school, $scope.allSchools
            .then (badges) ->
              school.badges = badges

          # Add passrate over time data to the school object
          api.getSchoolAggregates $scope.schoolType, $scope.rankBy, school.CODE
            .then (data) ->
              school.yearAggregates =
                values: _(data).reduce ((agg, year) ->
                  agg[year.YEAR_OF_RESULT] =
                    PASS_RATE: year.PASS_RATE
                    color: colorSrv.color bracketsSrv.getBracket year.PASS_RATE, 'PASS_RATE'
                  agg
                ), {}
                years: $scope.years
              thisYear = school.yearAggregates.values[$scope.year]
              lastYear = school.yearAggregates.values[$scope.year - 1]
              if lastYear?
                school.CHANGE_PREVIOUS_YEAR_PASSRATE = thisYear.PASS_RATE - lastYear.PASS_RATE
              # else undefined

        # side-effect: ensure that a selectedPolyLayer is always in front, if exists
        $scope.$watch 'polyLayer', -> if $scope.selectedPolyLayer?
          $scope.selectedPolyLayer.then (l) -> l.bringToFront()

        # side-effect: Zoom to selected pin
        $scope.$watch 'selectedSchoolLayer', (newL) -> if newL?
          $q.all
              map: leafletData.getMap mapId
              layer: newL
            .then ({map, layer}) ->
              map.setView layer.getLatLng(), (Math.max 9, map.getZoom())

        # side-effect: Zoom to selected polygon
        $scope.$watch 'selectedPolyLayer', (newL) -> if newL?
          $q.all
              map: leafletData.getMap mapId
              layer: newL
            .then ({map, layer}) ->
              map.fitBounds layer.getBounds()

        # side-effect: Transition view mode when polygon is selected
        $scope.$watch 'selectedPolyLayer', (newL) -> if newL?
          if $scope.polyType == 'regions'
            $scope.setPolyType 'districts'
          else if $scope.polyType == 'districts'
            $scope.setViewMode 'schools'
            $scope.setPolyType null

        # side-effect: zoom to bounds if nothing selected
        $scope.$watch 'polyLayer', (polyLayer) -> if polyLayer?
          unless $scope.selectedPolyId?
            leafletData.getMap mapId
              .then (map) -> map.fitBounds polyLayer.getBounds()

        # side-effects only
        $scope.$watchGroup ['pins', 'visMode'], ([pins]) -> if pins?
          pins.eachVisibleLayer colorPin

        # side-effects only
        $scope.$watchGroup ['polyLayer', 'polyIdMap', 'visMode'],
          ([polyLayer, polyIdMap]) ->
            if polyLayer? and polyIdMap?
              polyLayer.eachLayer (layer) ->
                utils.lookup(polyIdMap, layer.feature.id).then (feature) ->
                  if feature?
                    colorPoly feature, layer

        # side-effects only
        $scope.$watch 'hovered', (thing, oldThing) ->
          if thing != null
            switch $scope.viewMode
              when 'schools' then getSchoolPin(thing.CODE).then (pin) ->
                pin.bringToFront()
                pin.setStyle colorSrv.pinOn()
              when 'polygons' then getPolyLayer(thing.id).then (layer) ->
                layer.bringToFront()
                layer.setStyle colorSrv.polygonOn()
                if $scope.selectedPolyLayer?  # never go in front of a selected layer
                  $scope.selectedPolyLayer.then (l) -> l.bringToFront()
                rankPoly thing

          if oldThing != null
            switch $scope.viewMode
              when 'schools' then getSchoolPin(oldThing.CODE).then (pin) ->
                pin.setStyle colorSrv.pinOff()
              when 'polygons' then getPolyLayer(oldThing.id).then (layer) ->
                layer.setStyle colorSrv.polygonOff()

        # hack to adjust flyout bottom spacing to not overlap filters when present
        $scope.$on 'filtersToggle', (event, opts) ->
          $scope.filtersHeight = opts.height

        # widget local state (maybe should move to other directives)
        $scope.searchText = "dar"
        $scope.schoolsChoices = []

        # INIT
        leafletData.getMap(mapId).then (map) ->
          # add the basemap
          layersSrv.getTileLayer
              url: '//{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
            .then (layer) -> layer.addTo map
          resetView()
          # set up the initial view
          $scope.setViewMode 'schools'
          if $scope.schoolType == 'primary'
            $scope.rankBy = 'performance'
          $scope.setYear 2014  # hard-coded default to speed up page-load
          api.getYears $scope.schoolType, $scope.rankBy
            .then (years) -> $scope.years = _(years).map (y) -> y.YEAR_OF_RESULT
          # fix the map's container awareness (it gets it wrong)
          $timeout (-> map.invalidateSize()), 1

        # side-effects: de-select any selected school, zoom out to see everything
        resetView = ->
          $scope.selectSchool null
          $scope.setPolyType null
          $scope.selectPoly null
          $scope.setViewMode 'schools'
          leafletData.getMap(mapId).then (map) ->
            map.fitBounds [[-.8, 29.3], [-11.8, 40.8]]

        # View transition logic for clicking on the top tabs
        togglePolygons = (polyType) ->
          # in every case, deselect any schools and polygons
          $scope.selectSchool null
          $scope.selectPoly null
          if polyType == $scope.polyType  # un-toggle
            $scope.setPolyType null
            $scope.setViewMode 'schools'
          else if $scope.viewMode == 'schools'  # clicked one of the tabs
            $scope.setViewMode 'polygons'
            $scope.setPolyType polyType
          else  # poly -> poly by clicking tab, eg., districts to regions
            $scope.setPolyType polyType

        hoverThing = (id) ->
          if $scope.viewMode == 'schools'
            utils.lookup $scope.schoolCodeMap, id
              .then (s) -> $scope.hovered = s
              .catch $log.error
          else if $scope.viewMode == 'polygons'
            utils.lookup $scope.polyIdMap, id
              .then (r) -> $scope.hovered = r
              .catch $log.error

        # side-effect: mutates poly (gross, but...)
        rankPoly = (poly) ->
          p = poly.properties
          ps = $scope.detailedPolys.map (p) -> p.properties
          poly.properties.ranks = NATIONAL: utils.rank p, ps, 'PASS_RATE'
          if $scope.polyType == 'districts'
            poly.properties.ranks.REGIONAL = utils.rank p, ps, 'PASS_RATE', 'REGION'

        getSchoolPin = (code) -> $q (resolve, reject) ->
          layer = $scope.pins.getLayer code
          if layer?
            resolve layer
          else
            reject "No pin found for school code #{code}"

        getPolyLayer = (id) -> $q (resolve, reject) ->
          unless $scope.polyLayer?
            reject 'No polygon layers to find from'
          else
            layer = null
            $scope.polyLayer.eachLayer (l) ->
              if l.feature.id == id
                if layer?
                  $log.warn "Multiple layers found for id #{id}"
                layer = l
            unless layer?
              reject "No polygon layer found for '#{id}'"
            else
              resolve layer

        # get the (rank, total) of a school, filtered by its region or district or national
        rank = (school, rank_by, [ob, desc]) ->
          grouper = switch rank_by
            when 'REGION', 'DISTRICT' then rank_by
            when 'NATIONAL' then null
            else throw new Error "invalid rank_by: '#{rank_by}'"
          $q (resolve, reject) ->
            rankSchool = (schools) ->
              try
                resolve utils.rank school, schools, ob, grouper, if desc then 'DESC' else 'ASC'
              catch err
                reject err
            $scope.allSchools.then rankSchool, reject

        processPin = (code, layer) ->
          colorPin code, layer
          layer.on 'mouseover', -> $scope.$apply ->
            $scope.hover code
          layer.on 'mouseout', -> $scope.$apply ->
            $scope.unHover()
          layer.on 'click', -> $scope.$apply ->
            $scope.selectSchool code

        processPoly = (feature, layer) ->
          colorPoly feature, layer
          layer.on 'mouseover', -> $scope.$apply ->
            $scope.hover feature.id
          layer.on 'mouseout', -> $scope.$apply ->
            $scope.unHover()
          layer.on 'click', -> $scope.$apply ->
            $scope.selectPoly feature.id


        colorPin = (code, layer) ->
          utils.lookup($scope.schoolCodeMap, code).then (school) ->
            val = school[$scope.visMetric]
            layer.setStyle colorSrv.pinOff $scope.getColor val

        colorPoly = (feature, layer) ->
          val = feature.properties[$scope.visMetric]
          layer.setStyle colorSrv.polygonOff $scope.getColor val

        getDetailsByPoly = (schools, polyType, schoolType) ->
          detailsByPoly = {}
          schoolsByPoly = groupBy schools, polyGroupProp polyType
          for id, regSchools of schoolsByPoly
            byOwner = groupBy regSchools, 'OWNERSHIP'
            detailsByPoly[id] =
              CHANGE_PREVIOUS_YEAR: averageProp regSchools, 'CHANGE_PREVIOUS_YEAR'  # TODO: confirm
              PASS_RATE: averageProp regSchools, 'PASS_RATE'
              GOVT_SCHOOLS: byOwner.GOVERNMENT?.length
              NON_GOVT_SCHOOLS: byOwner['NON GOVERNMENT']?.length
              UNKNOWN_SCHOOLS: regSchools.length - byOwner.GOVERNMENT?.length - byOwner['NON GOVERNMENT']?.length

            # get the region for any district via school data
            if polyType == 'districts'
              [[region, blah], extras...] = ([r, s] for r, s of groupBy schoolsByPoly[id], 'REGION')
                .map ([region, schools]) -> [region, schools.length]
                .sort ([ra, sa], [rb, sb]) -> sb - sa
              if extras? > 1
                $log.warn "District has schools with different regions: #{id}"
              detailsByPoly[id].REGION = region

            angular.extend detailsByPoly[id],
              if schoolType == 'primary'
                AVG_MARK: averageProp regSchools, 'AVG_MARK'
              else if schoolType == 'secondary'
                AVG_GPA: averageProp regSchools, 'AVG_GPA'
                CHANGE_PREVIOUS_YEAR_GPA: averageProp regSchools, 'CHANGE_PREVIOUS_YEAR_GPA'
              else
                throw new Error 'Expected "primary" or "secondary" for schoolType'
          detailsByPoly

        polyGroupProp = (polyType) ->
          switch polyType
            when 'regions' then 'REGION'
            when 'districts' then 'DISTRICT'
            else throw new Error "cannot group polygons by unknown polyType '#{polyType}'"

        groupBy = (rows, prop) ->
          grouped = {}
          for row in rows
            unless grouped[row[prop]]?
              grouped[row[prop]] = []
            grouped[row[prop]].push row
          grouped

        average = (nums) -> (nums.reduce (a, b) -> a + b) / nums.length

        averageProp = (rows, prop) -> average _(rows).map (r) -> r[prop]

        search = (query) ->
          if query?
            api.search $scope.schoolType, $scope.rankBy, query, $scope.year
              .then (data) -> $q.all _(data).map (s) -> utils.lookup $scope.schoolCodeMap, s.CODE
                .then (schools) ->
                  $scope.searchText = query
                  $scope.searchChoices = _.unique schools
