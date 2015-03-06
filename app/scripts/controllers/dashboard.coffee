'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:DashboardsCtrl
 # @description
 # # DashboardsCtrl
 # Controller of the edudashApp
###
angular.module('edudashApp').controller 'DashboardCtrl', [
    '$scope', '$window', '$routeParams', '$http', 'cartodb', 'L', '_'
 
    ($scope, $window, $routeParams, $http, cartodb, L, _) ->
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
        
        $scope.searchText = "dar"
        
        apiRoot = 'http://wbank.cartodb.com/api/v2/sql'
        apiKey = 'ad10ae57cef93e98482aabcf021a738a028c168b'
        bestSchoolsSql = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard ORDER BY rank_2014 ASC LIMIT 100"
        worstSchoolsSql = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard ORDER BY rank_2014 DESC LIMIT 100"
        mostImprovedSchoolsSql = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard WHERE change_13_14 IS NOT NULL ORDER BY change_13_14 DESC LIMIT 100"
        leastImprovedSchoolsSql = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard ORDER BY change_13_14 ASC LIMIT 100"
        # schoolsSql = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard ORDER BY rank_2014"

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
        $scope.activeItem = null
        $scope.schoolsChoices = []
        $scope.selectedSchool = {}
        schoolMarker = null

        cartodb.createVis("map", mapLayers[$scope.schoolType], mapOptions).done (vis, lyrs) ->
          # layer 0 is the base layer, layer 1 is cartodb layer
          # setInteraction is disabled by default
            layers = lyrs
            layers[1].setInteraction(true)
            layers[1].on 'featureOver', (e, pos, latlng, data) ->
                cartodb.log.log(data)
            # you can get the native map to woOrk with it
            map = vis.getNativeMap()

        $http.get(apiRoot, {params: { q: bestSchoolsSql, api_key: apiKey }}).success (data) ->
            $scope.bestSchools = data.rows

        $http.get(apiRoot, {params: { q: worstSchoolsSql, api_key: apiKey }}).success (data) ->
            $scope.worstSchools = data.rows

        $http.get(apiRoot, {params: { q: mostImprovedSchoolsSql, api_key: apiKey }}).success (data) ->
            $scope.mostImprovedSchools = data.rows

        $http.get(apiRoot, {params: { q: leastImprovedSchoolsSql, api_key: apiKey }}).success (data) ->
            $scope.leastImprovedSchools = data.rows

        # $http.get(apiRoot, {params: { q: schoolsSql, api_key: apiKey }}).success (data) ->
        #    $scope.schools = data.rows
        #    $scope.bestSchools = _.first($scope.schools, 100)
        #    $scope.worstSchools = _.last($scope.schools, 100).reverse()
        #    $scope.mostImprovedSchools = _.first(_.sortBy($scope.schools, 'change_13_14'), 100)
        #   $scope.leastImprovedSchools = _.first(_.sortBy($scope.schools, 'change_13_14'), 100)

        $scope.showLayer = (tag) ->
            if tag?
                $scope.activeMap = tag
                for i in [0, 1, 2, 3]
                    if i == tag
                        layers[1].getSubLayer(i).show()
                    else
                        layers[1].getSubLayer(i).hide()

        $scope.getSchoolsChoices = (query) ->
            if query?
                $scope.searchText = query
                searchSQL = "SELECT * FROM wbank.tz_#{ $scope.schoolType }_cleaned_dashboard WHERE " +
                    "(name ilike '%#{ $scope.searchText }%' OR code ilike '%#{ $scope.searchText }%') LIMIT 10"
                $http.get(apiRoot, {params: { q: searchSQL, api_key: apiKey }}).success (data) ->
                    $scope.schoolsChoices = data.rows

        markSchool = (latlng) ->
            # markerIcon = L.icon
            #    iconUrl: 'images/marker2.png'
            markerIcon = L.AwesomeMarkers.icon
                markerColor: 'blue'
                icon: 'map-marker'
            unless schoolMarker?
                schoolMarker = L.marker(latlng, {icon: markerIcon}).addTo(map)
            else
                schoolMarker.setLatLng(latlng, {icon: markerIcon})

        $scope.setSchool = (item, model) ->
            $scope.selectedSchool = item
            $scope.activeMap = 0
            $scope.showLayer(0)
            latlng = L.latLng($scope.selectedSchool.latitude, $scope.selectedSchool.longitude);
            markSchool latlng
            map.setView latlng, 9
            if item.pass_2014 < 10 && item.pass_2014 > 0
                $scope.selectedSchool.pass_by_10 = 1
            else
                $scope.selectedSchool.pass_by_10 = Math.round item.pass_2014/10
                # $scope.selectedSchool.pass_by_10 = parseInt item.pass_2014/10
            $scope.selectedSchool.fail_by_10 = 10 - $scope.selectedSchool.pass_by_10

            # TODO: cleaner way?
            # Ensure the parent div has been fully rendered
            setTimeout( (() -> drawPassOverTime(item)), 1000)

        getDimensions = (selector) ->
          pn = d3.select(selector).node().parentNode
          h = d3.select(selector).style('height').replace('px', '')
          w = d3.select(selector).style('width').replace('px', '')
          {h: h, w: w}

        drawPassOverTime = (item) ->
          selector = "#widget #passOverTime"

          # TODO hardcoded date
          years = _.range(2012,2015)
          values = years.map((x) -> item["pass_" + x])
          data = _.zip(years, values).map( (x) -> {"key": x[0], "val": x[1]})

          dim = getDimensions(selector)
          h = 150
          w = dim.w
          margin =
            top: 20
            right: 20
            bottom: 20
            left: 20

          width = w - margin.left - margin.right
          height = h - margin.top - margin.bottom

          x = d3.scale.linear()
            .range([0, width])
            .domain([years[0], years[years.length-1]])

          y = d3.scale.linear()
            .range([height, 0])
            .domain([0, 100])

          xAxis = d3.svg.axis()
            .scale(x)
            .orient("bottom")
            .tickValues(years)
            .tickFormat(d3.format("0000"))

          # TODO: smooth transition instead of re-draw
          $(selector + " svg").remove()

          # create the svg if it does not already exist
          svg = d3.select(selector + " svg");

          if !svg[0][0]
            svg = d3.select(selector).append("svg")
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
            # transform within the margins
              .append("g")
              .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

            svg.append("g")
              .attr("class", "x axis")
              .attr("transform", "translate(0," + height + ")")
              .call(xAxis)

          else
            svg = svg.select('g')

          line = d3.svg.line()
            .x((d) -> x(d.key))
            .y((d)-> y(d.val))

          svg.append("path")
            .datum(data)
            .attr("class", "line")
            .attr("d", line)

          node = svg.append("g").selectAll("g")
            .data(data)
            .enter()
            .append("g")

          findColorClass = (x) ->
            if x < 35
              "circle-poor"
            else if 35 <= x < 50
              "circle-medium"
            else
              "circle-good"

          radius = 15
          node.append("circle")
            .attr("class", (d) -> "dot " + findColorClass(d.val))
            .attr("cx", (d) -> x(d.key))
            .attr("cy", (d) -> y(d.val))
            .attr("r", radius)

          node.append("text")
            .attr("class", "dotlabel")
            .attr("x", (d) -> x(d.key) - radius/1.5)
            .attr("y", (d) -> y(d.val) + radius/4)
            .text((d) -> d.val + "%")

        $scope.getTimes = (n) ->
            new Array(n)
]
