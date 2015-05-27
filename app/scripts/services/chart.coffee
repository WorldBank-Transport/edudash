'use strict'

###*
 # @ngdoc service
 # @name edudashApp.charts
 # @description
 # # Charts service
 # Old D3 charts
###

angular.module('edudashAppSrv').factory 'chartSrv', [
  '$q', 'd3', 'WorldBankApi',
  ($q, d3, WorldBankApi) ->

    getDimensions = (selector) ->
      pn = d3.select(selector).node().parentNode
      h = d3.select(selector).style('height').replace('px', '')
      w = d3.select(selector).style('width').replace('px', '')
      {h: h, w: w}

    drawNationalRanking: (item, schoolType, worst) ->
      selector = ".widget #nationalRanking"

      # TODO: assumes 2014
      nr = item.rank_2014

      $q.all([
        WorldBankApi.getSchoolRegionRank(schoolType, item.region, item.cartodb_id)
        WorldBankApi.getSchoolDistrictRank(schoolType, item.region, item.district, item.cartodb_id)
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


    drawPassOverTime: (item) ->
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
]
