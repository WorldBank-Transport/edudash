'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:DashboardsCtrl
 # @description
 # # DashboardsCtrl
 # Controller of the edudashApp
###
angular.module('edudashApp').controller 'DashboardCtrl', [
    '$scope', '$window', '$routeParams', '$http', 'cartodb'
 
    ($scope, $window, $routeParams, $http, cartodb) ->
        primary = 'primary'
        secondary = 'secondary'
        mapLayers =
            'primary': 'http://worldbank.cartodb.com/api/v2/viz/a031f6f0-c1d0-11e4-966d-0e4fddd5de28/viz.json'
            'secondary': 'http://worldbank.cartodb.com/api/v2/viz/0d9008a8-c1d2-11e4-9470-0e4fddd5de28/viz.json'
        if $routeParams.type == secondary
            $scope.schoolType = secondary
            $scope.title = 'Secondary School Dashboard'
        else if $routeParams.type == primary
            $scope.schoolType = primary
            $scope.title = 'Primary School Dashboard'
        else
            $window.location.href = '/'
        
        apiRoot = 'http://wbank.cartodb.com/api/v2/sql'
        apiKey = 'ad10ae57cef93e98482aabcf021a738a028c168b'
        bestSchoolsSql = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard ORDER BY rank_2014 ASC LIMIT 100"
        worstSchoolsSql = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard ORDER BY rank_2014 DESC LIMIT 100"
        mostImprovedSchoolsSql = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard WHERE change_13_14 IS NOT NULL ORDER BY change_13_14 DESC LIMIT 100"
        leastImprovedSchoolsSql = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard ORDER BY change_13_14 ASC LIMIT 100"

        map = null
        layers = null
        mapOptions =
            shareable: false
            title: false
            description: false
            search: false
            tiles_loader: true
            zoom: 6
            layer_selector: false
            cartodb_logo: false

        $scope.activeMap = 0

        cartodb.createVis("map", mapLayers[$scope.schoolType], mapOptions).done (vis, lyrs) ->
          # layer 0 is the base layer, layer 1 is cartodb layer
          # setInteraction is disabled by default
            layers = lyrs
            layers[1].setInteraction(true)
            layers[1].on 'featureOver', (e, pos, latlng, data) ->
                cartodb.log.log(data)
            # you can get the native map to work with it
            map = vis.getNativeMap()

        $http.get(apiRoot, {params: { q: bestSchoolsSql, api_key: apiKey }}).success (data) ->
            $scope.bestSchools = data.rows

        $http.get(apiRoot, {params: { q: worstSchoolsSql, api_key: apiKey }}).success (data) ->
            $scope.worstSchools = data.rows

        $http.get(apiRoot, {params: { q: mostImprovedSchoolsSql, api_key: apiKey }}).success (data) ->
            $scope.mostImprovedSchools = data.rows

        $http.get(apiRoot, {params: { q: leastImprovedSchoolsSql, api_key: apiKey }}).success (data) ->
            $scope.leastImprovedSchools = data.rows

        $scope.showLayer = (tag) ->
            if tag?
                $scope.activeMap = tag
                for i in [0, 1, 2, 3]
                    if i == tag
                        layers[1].getSubLayer(i).show()
                    else
                        layers[1].getSubLayer(i).hide()
]
