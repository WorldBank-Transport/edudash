'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:DashboardsCtrl
 # @description
 # # DashboardsCtrl
 # Controller of the edudashApp
###
angular.module('edudashApp').controller 'DashboardCtrl', [
    '$scope', '$window', '$routeParams', '$anchorScroll', '$http', 'cartodb', 'L', '_', '$q', 'WorldBankApi', "$log"

    ($scope, $window, $routeParams, $anchorScroll, $http, cartodb, L, _, $q, WorldBankApi, $log) ->
        primary = 'primary'
        secondary = 'secondary'
        title =
          primary: 'Primary School Dashboard'
          secondary: 'Secondary School Dashboard'

        $scope.schoolType = $routeParams.type
        $scope.title = title[$routeParams.type]
        if $routeParams.type isnt primary and $routeParams.type isnt secondary
          $window.location.href = '/'

        $scope.searchText = "dar"

        map = L.map 'map',
            center: [-7.199, 34.1894],
            zoom: 6
        layers = []

        $scope.activeMap = 0
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


        # add the basemap layer 0
        cartodb.createLayer map, WorldBankApi.getLayer($scope.schoolType), layerIndex: 0
            .addTo map
            .done (basemap) -> layers[0] = basemap
        # add the layer 1 for schoold
        cartodb.createLayer map, WorldBankApi.getLayer($scope.schoolType), layerIndex: 1
            .addTo map
            .done (layer) ->
                layers[1] = layer
                layers[1].setInteraction(true)
                layers[1].on 'featureClick', (e, pos, latlng, data) ->
                    if $scope.activeMap == 3
                        $scope.setMapView(pos, 9, 0)
                    else
                        WorldBankApi.getSchooldByCartoDb($scope.schoolType , data.cartodb_id).success (data) ->
                            $scope.setSchool data.rows[0]
                layers[1].on 'mouseover', () ->
                    $('.leaflet-container').css('cursor', 'pointer')
                layers[1].on 'mouseout', () ->
                    $('.leaflet-container').css('cursor', '-webkit-grab')
                    $('.leaflet-container').css('cursor', '-moz-grab')
                $scope.showLayer 0

        WorldBankApi.getBestSchool($scope.schoolType).success (data) ->
            $scope.bestSchools = data.rows

        WorldBankApi.getWorstSchool($scope.schoolType).success (data) ->
            $scope.worstSchools = data.rows

        WorldBankApi.mostImprovedSchools($scope.schoolType).success (data) ->
            $scope.mostImprovedSchools = data.rows

        WorldBankApi.leastImprovedSchools($scope.schoolType).success (data) ->
            $scope.leastImprovedSchools = data.rows

        $scope.showLayer = (tag) ->
          if tag?
            $scope.activeMap = tag
            [0..3].map (i) -> if i == tag then layers[1].getSubLayer(i).show() else layers[1].getSubLayer(i).hide()

        $scope.toggleMapFilter = () ->
            $scope.openMapFilter = !$scope.openMapFilter

        $scope.toggleSchoolLegend = () ->
            $scope.openSchoolLegend = !$scope.openSchoolLegend

        updateMap = () ->
          if $scope.activeMap != 3
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
            markerIcon = L.AwesomeMarkers.icon
                markerColor: 'blue'
                icon: 'map-marker'
            unless schoolMarker?
                schoolMarker = L.marker(latlng, {icon: markerIcon}).addTo(map)
            else
                schoolMarker.setLatLng(latlng, {icon: markerIcon})

        $scope.setMapView = (latlng, zoom, tab) ->
            if tab?
                $scope.$apply ()->
                    $scope.activeMap = tab
                $scope.showLayer(tab)
            unless zoom?
                zoom = 9
            map.setView latlng, zoom

        $scope.setSchool = (item, model, showAllSchools) ->
            $scope.selectedSchool = item
            unless showAllSchools? and showAllSchools == false
                $scope.activeMap = 0
                $scope.showLayer(0)
            # Silence invalid/null coordinates
            try
                if map.getZoom() < 9
                   zoom = 9
                else
                    zoom = map.getZoom()
                latlng = L.latLng($scope.selectedSchool.latitude, $scope.selectedSchool.longitude);
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
              if $scope.activeMap == 0
                drawNationalRanking(item)
                drawPassOverTime(item)
            , 400)

        getDimensions = (selector) ->
          pn = d3.select(selector).node().parentNode
          h = d3.select(selector).style('height').replace('px', '')
          w = d3.select(selector).style('width').replace('px', '')
          {h: h, w: w}

        drawNationalRanking = (item) ->
          selector = ".widget #nationalRanking"

          # TODO: assumes 2014
          nr = item.rank_2014

          # ranking of worst school nationally
          worst = $scope.worstSchools[0].rank_2014

          $q.all([
            WorldBankApi.getSchoolRegionRank($scope.schoolType, item.region, item.cartodb_id)
            WorldBankApi.getSchoolDistrictRank($scope.schoolType, item.region, item.district, item.cartodb_id)
          ]).then (data) ->
            rr = data[0].data.rows[0].pos
            dr = data[1].data.rows[0].pos

            dim = getDimensions(selector)
            h = 100
            w = (w = 400 if dim.w > 400) or dim.w

            margin =
              top: 20
              right: 25
              bottom: 20
              left: 40

            width = w - margin.left - margin.right
            height = h - margin.top - margin.bottom

            x = d3.scale.linear()
              .range([0, width])
              .domain([worst,1])

            y = d3.scale.linear()
              .range([0,height])
              .domain([0, 100])

            # TODO: smooth transition instead of re-draw
            $(selector + " svg").remove()

            svg = d3.select(selector).append("svg")
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
            # transform within the margins
              .append("g")
              .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

            n = 5
            section = width/n

            svg.append("line")
              .attr("x1", 0)
              .attr("y1", y(50))
              .attr("x2", section)
              .attr("y2", y(50))
              .attr("stroke-width", 4)
              .attr("stroke", "#ef4c54")

            svg.append("line")
              .attr("x1", section + 2)
              .attr("y1", y(50))
              .attr("x2", section * (n-1))
              .attr("y2", y(50))
              .attr("stroke-width", 4)
              .attr("stroke", "#989898")

            svg.append("line")
              .attr("x1", section * (n-1) + 2)
              .attr("y1", y(50))
              .attr("x2", width)
              .attr("y2", y(50))
              .attr("stroke-width", 4)
              .attr("stroke", "#80c651")

            svg.append("path")
              .attr("d", d3.svg.symbol().type("triangle-down"))
              .attr("fill": "#a1a1a1")
              .attr("transform",  "translate(" + x(nr) + "," + (y(50)-8) + ")")

            label = svg.append("text")
              .attr("class", "widgetnumber")
              .attr("fill": "#a1a1a1")
              .text(nr)

            bbox = label.node().getBBox()

            label.attr("x", x(nr) - bbox.width/2)
                  .attr("y", y(50)-18)

            rg = svg.append("g")
              .attr("transform", "translate(" + 10 + "," + (y(50)+35) + ")")

            rg.append("path")
              .attr("d", d3.svg.symbol().type("triangle-up"))
              .attr("fill", "#a1a1a1")
              .attr("transform",  "rotate(90)")

            rg.append("text")
              .attr("class", "widgettitle")
              .attr("x", 10)
              .attr("y", 4)
              .attr("fill", "#a1a1a1")
              .text((d) -> "Regional Rank  #{rr}")

            rg.append("path")
              .attr("d", d3.svg.symbol().type("triangle-up"))
              .attr("fill", "#a1a1a1")
              .attr("transform",  "translate(" + (width/2) + ",0) rotate(90)")

            rg.append("text")
              .attr("class", "widgettitle")
              .attr("x", (width/2) + 10)
              .attr("y", 4)
              .attr("fill", "#a1a1a1")
              .text((d) -> "District Rank  #{dr}")

        drawPassOverTime = (item) ->
          selector = ".widget #passOverTime"

          curYear = new Date().getFullYear()
          years = _.range(2012, curYear)
          values = years.map (x) -> item["pass_" + x]
          data = _.zip(years, values).map( (x) -> {"key": x[0], "val": x[1]})

          # remove years with no data
          data = data.filter( (x) -> x.val )

          dim = getDimensions(selector)
          h = 100
          w = (w = 350 if dim.w > 350) or dim.w

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

          svg = d3.select(selector).append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
          # transform within the margins
            .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

          svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + height + ")")
            .attr("fill", "#a1a1a1")
            .call(xAxis)

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
            if x < 40
              "circle-poor"
            else if 40 <= x < 60
              "circle-medium"
            else
              "circle-good"

          radius = 15
          # add a small buffer to prevent overlap with x axi
          padding = -5
          node.append("circle")
            .attr("class", (d) -> "dot " + findColorClass(d.val))
            .attr("cx", (d) -> x(d.key))
            .attr("cy", (d) -> y(d.val) + padding)
            .attr("r", radius)

          label = node.append("text")
            .attr("class", "dotlabel")
            .text((d) -> d.val + "%")

          bbox = label.node().getBBox()

          label.attr("x", (d) -> x(d.key) - bbox.width/2)
               .attr("y", (d) -> y(d.val) + radius/4 + padding)

        $scope.getTimes = (n) ->
            new Array(n)

        $scope.anchorScroll = () ->
            $anchorScroll()

]
