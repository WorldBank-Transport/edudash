'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:DashboardsCtrl
 # @description
 # # DashboardsCtrl
 # Controller of the edudashApp
###
angular.module('edudashAppCtrl').controller 'DashboardCtrl', [
    '$scope', '$window', '$routeParams', '$anchorScroll', '$http', 'leafletData', '_', '$q', 'WorldBankApi', 'layersSrv', 'chartSrv', '$log','$location','$translate',
    '$timeout', 'MetricsSrv'
    

    ($scope, $window, $routeParams, $anchorScroll, $http, leafletData, _, $q, WorldBankApi, layersSrv, chartSrv, $log, $location, $translate, $timeout, MetricsSrv) ->
        primary = 'primary'
        secondary = 'secondary'
        title =
          primary: 'Primary School Dashboard'
          secondary: 'Secondary School Dashboard'

        $scope.schoolType = $routeParams.type
        $scope.title = title[$routeParams.type]

        if $routeParams.type isnt primary and $routeParams.type isnt secondary
          $timeout (-> 
              $location.path '/' 
              return;
              ) 
        
       
        $scope.searchText = "dar"

        layers = {}

        $scope.activeMap = 'schools'
        $scope.activeItem = null
        $scope.schoolsChoices = []
        $scope.selectedSchool = ''
        schoolMarker = null
        $scope.openMapFilter = false
        $scope.openSchoolLegend = false
        ptMin = 0
        ptMax = 150
        $scope.passRange =
            min: 0
            max: 100
        $scope.ptRange =
            min: ptMin
            max: ptMax


        mapId = 'map'

        cartodbLayers = [  # ordered to align with the cartoDB subLayer index
          'schools',
          'performance',
          'improvement',
          'districts',
        ]


        leafletData.getMap(mapId).then (map) ->
          # initialize the map view
          map.setView [-7.199, 34.1894], 6

          # add the basemap
          layersSrv.addTileLayer 'gray', '//{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', mapId

          # add the cartodb layers
          cartoURL = WorldBankApi.getLayer $scope.schoolType
          cartodbLayers.forEach (id, i) ->
            layers[id] = layersSrv.addCartodbLayer id, cartoURL, i, mapId
            layers[id].then (layer) -> layer.raw.then (rawLayer) ->
              rawLayer.on 'featureClick', (e, pos, latlng, data) ->
                if $scope.activeMap == 'districts'
                  $scope.setMapView pos, 9, 'schools'
                else
                  WorldBankApi.getSchooldByCartoDb $scope.schoolType, data.cartodb_id
                    .success (data) ->
                      $scope.setSchool data.rows[0]

          # set up the initial view
          $scope.showLayer 'schools'


        WorldBankApi.getBestSchool($scope.schoolType).success (data) ->
            $scope.bestSchools = data.rows

        WorldBankApi.getWorstSchool($scope.schoolType).success (data) ->
            $scope.worstSchools = data.rows

        WorldBankApi.mostImprovedSchools($scope.schoolType).success (data) ->
            $scope.mostImprovedSchools = data.rows

        WorldBankApi.leastImprovedSchools($scope.schoolType).success (data) ->
            $scope.leastImprovedSchools = data.rows

        $scope.showLayer = (view) ->
          $scope.activeMap = view
          cartodbLayers.forEach (id) ->
            if id == view
              layers[id].then (layer) -> layer.show()
            else
              layers[id].then (layer) -> layer.hide()

        $scope.toggleMapFilter = () ->
            $scope.openMapFilter = !$scope.openMapFilter

        $scope.toggleSchoolLegend = () ->
            $scope.openSchoolLegend = !$scope.openSchoolLegend

        updateMap = () ->
          if $scope.activeMap != 'districts'
            # Include schools with no pt_ratio are also shown when the pt limits in extremeties
            if $scope.ptRange.min == ptMin and $scope.ptRange.max == ptMax
                WorldBankApi.updateLayers(layers, $scope.schoolType, $scope.passRange)
            else
                WorldBankApi.updateLayersPt(layers, $scope.schoolType, $scope.passRange, $scope.ptRange)

        $scope.updateMap = _.debounce(updateMap, 500)

        $scope.getSchoolsChoices = (query) ->
            if query?
              WorldBankApi.getSchoolsChoices($scope.schoolType, query).success (data) ->
                $scope.searchText = query
                $scope.schoolsChoices = data.rows

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

        markSchool = (latlng) ->
          unless schoolMarker?
            icon = layersSrv.awesomeIcon markerColor: 'blue', icon: 'map-marker'
            schoolMarker = layersSrv.marker 'school-marker', latlng, {icon: icon}, mapId

          schoolMarker.then (marker) ->
            marker.raw.setLatLng latlng
            marker.show()

        $scope.setMapView = (latlng, zoom, view) ->
            if view?
                $scope.activeMap = view
                $scope.showLayer(view)
            unless zoom?
                zoom = 9
            leafletData.getMap(mapId).then (map) ->
                map.setView latlng, zoom

        $scope.setSchool = (item, model, showAllSchools) ->
            $scope.selectedSchool = item
            unless showAllSchools? and showAllSchools == false
                $scope.activeMap = 'schools'
                $scope.showLayer('schools')
            # Silence invalid/null coordinates
            leafletData.getMap(mapId).then (map) ->
              try
                  if map.getZoom() < 9
                     zoom = 9
                  else
                      zoom = map.getZoom()
                  latlng = [$scope.selectedSchool.latitude, $scope.selectedSchool.longitude];
                  markSchool latlng
                  map.setView latlng, zoom
              catch e
                  console.log e
            if item.pass_2014 < 10 && item.pass_2014 > 0
                $scope.selectedSchool.pass_by_10 = 1
            else
                $scope.selectedSchool.pass_by_10 = Math.round item.pass_2014/10
            $scope.selectedSchool.fail_by_10 = 10 - $scope.selectedSchool.pass_by_10

            # TODO: cleaner way?
            # Ensure the parent div has been fully rendered
            setTimeout( () ->
              if $scope.activeMap == 'schools'
                console.log chartSrv
                chartSrv.drawNationalRanking item, $scope.schoolType, $scope.worstSchools[0].rank_2014
                $scope.passratetime = chartSrv.drawPassOverTime item

            , 400)

        $scope.getTimes = (n) ->
            new Array(n)

        $scope.anchorScroll = () ->
            $anchorScroll()

        # TODO get this data from a service
        if $scope.schoolType is secondary
          $scope.bpdistrics = [
            {location: [-3.4331517184, 36.6737179684], name: 'Arusha Municipal', rate: 88}
            {location: [-3.3663947031, 37.4195272817], name: 'Moshi Municipal', rate: 85}
            {location: [-2.7369939879, 31.2561260741], name: 'Biharamulo', rate: 83}
            {location: [-6.7262543392, 39.1409173665], name: 'Kinondoni', rate: 81}
          ]
          $scope.wpdistrics = [
            {location: [-8.8089448541, 32.4249572752], name: 'Momba', rate: 30}
            {location: [-8.5151689606, 31.526046175], name: 'Kalambo', rate: 35}
            {location: [-4.385454233, 33.0116723459], name: 'Nzega', rate: 35}
            {location: [-4.3178931578, 37.0915398416], name: 'Simanjiro', rate: 37}
            {location: [-4.5246418813, 35.2997811577], name: 'Hanang', rate: 40}
          ]
          $scope.midistrics = [
            {location: [-10.9539928285, 37.283801768], name: 'Tunduru', rate: 31}
            {location: [-11.027686889, 38.409135053], name: 'Nanyumbu', rate: 27}
            {location: [-1.9956045687, 33.0136140625], name: 'Ukerewe', rate: 23}
            {location: [-5.2234611886, 36.7583348837], name: 'Kiteto', rate: 21}
            {location: [-6.0371763509, 33.0949829143], name: 'Sikonge', rate: 21}
          ]
          $scope.lidistrics = [
            {location: [-5.8562823817,39.3055393524], name: 'Kaskazini A', rate: -16}
            {location: [-5.3782568911,39.7056630242], name: 'Mkoani', rate: -15}
            {location: [-11.1633258866,34.8725674647], name: 'Nyasa', rate: -14}
            {location: [-5.0968020918,39.7660922987], name: 'Wete', rate: -10}
            {location: [-5.2476201852,39.7699560598], name: 'Chake Chake', rate: -10}
          ]
        else
          $scope.bpdistrics = [
            {name: 'Arusha Municipal', rate: 92, location: [-3.3434370928, 36.6866081666]}
            {name: 'Moshi Municipal', rate: 90,location: [-3.3456197671, 37.3408697955]}
            {name: 'Biharamulo', rate: 88, location: [-2.7369939879, 31.2561260741]}
            {name: 'Mpanda Urban', rate: 88, location: [-6.4080885938, 30.9894323986]}
            {name: 'Kinondoni', rate: 86, location: [-6.7262543392, 39.1409173665]}
          ]
          $scope.wpdistrics = [
            {name: 'Gairo', rate: 25, location: [-6.2032375409,37.0067288437]}
            {name: 'Mkalama', rate: 25, location: [-4.1976105604,34.7147749689]}
            {name: 'Nzega', rate: 27, location: [-4.385454233,33.0116723459]}
            {name: 'Kalambo', rate: 30,location: [-8.5151689606,31.5260461757]}
            {name: 'Momba', rate: 30, location: [-8.8089448541,32.4249572752]}
          ]
          $scope.midistrics = [
            {name: 'Tunduru', rate: 35, location: [-10.9539928285,37.283801768]}
            {name: 'Nanyumbu', rate: 26, location: [-11.027686889,38.409135053]}
            {name: 'Mpanda Urban', rate: 25, location: [-6.4080885938,30.9894323986]}
            {name: 'Ukerewe', rate: 24, location: [-1.9956045687,33.0136140625]}
            {name: 'Mpanda', rate: 23, location: [-6.0300901028,30.56419613]}
          ]
          $scope.lidistrics = [
            {name: 'Pangani', rate: -9, location: [-5.5920471331,38.8164028284]}
            {name: 'Shinyanga Municipal', rate: -7, location: [-3.6233536528,33.4445364936]}
            {name: 'Mkinga', rate: -6, location: [-4.7459693661, 38.9243345442]}
            {name: 'Kigoma Municipal', rate: -6, location: [-4.8895048727, 29.6652013888]}
            {name: 'Kibaha', rate: -5, location: [-6.8174266213, 38.5509159068]}
          ]
        MetricsSrv.getPupilTeacherRatio({level: $scope.schoolType}).then (data) ->
          $scope.pupilTeacherRatio = data.rate
        $scope.passrate = 58
        $scope.passRateChange = 0
#        $scope.passratetime =
#            y: [25, 71, 45]
#            x: [2012, 2013, 2014]

]
