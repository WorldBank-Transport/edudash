'use strict'

###*
 # @ngdoc service
 # @name edudashApp.charts
 # @description
 # # Charts service
 # Old D3 charts
###

angular.module('edudashAppSrv').factory 'chartSrv', [
  '$q', 'd3',
  ($q, d3) ->

    getDimensions = (selector) ->
      pn = d3.select(selector).node().parentNode
      h = d3.select(selector).style('height').replace('px', '')
      w = d3.select(selector).style('width').replace('px', '')
      {h: h, w: w}

    drawNationalRanking: (item, schoolType, worst) ->
      selector = ".widget #nationalRanking"
      # TODO: assumes 2014
      nr = item.rank_2014
      dim = getDimensions(selector)
      h = 50
      w = (w = 350 if dim.w > 350) or dim.w

      margin =
        top: 20
        right: 25
        bottom: 20
        left: 100

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

      yHight = y(50)

      svg.append("line")
        .attr("x1", 0)
        .attr("y1", yHight)
        .attr("x2", section)
        .attr("y2", yHight)
        .attr("stroke-width", 4)
        .attr("stroke", "#f56053")

      svg.append("line")
        .attr("x1", section + 2)
        .attr("y1", yHight)
        .attr("x2", section * (n-1))
        .attr("y2", yHight)
        .attr("stroke-width", 4)
        .attr("stroke", "#989898")

      svg.append("line")
        .attr("x1", section * (n-1) + 2)
        .attr("y1", yHight)
        .attr("x2", width)
        .attr("y2", yHight)
        .attr("stroke-width", 4)
        .attr("stroke", "#38a21c")

      labelColor = switch
        when x(nr)  > (section * (n-1)) then '#38a21c'
        when x(nr)  < section then '#f56053'
        else '#a1a1a1'
      if x(nr)  > (width/2)
        rotate = -90
        xArrow = -4
      else
        rotate = 90
        xArrow = 4

      svg.append("path")
        .attr("d", d3.svg.symbol().type("triangle-down"))
        .attr("fill": labelColor)
        .attr("transform",  "translate(#{x(nr) + xArrow},#{yHight}) rotate(#{rotate})")

      label = svg.append("text")
        .attr("class", "widgetnumber")
        .attr("fill": "#000")
        .attr("x", -100)
        .attr("y", yHight + 11)
        .text(nr)

      bbox = label.node().getBBox()

      rg = svg.append("g")
        .attr("transform", "translate(" + 10 + "," + (yHight+35) + ")")

    drawPassOverTime: (item) ->
      selector = ".widget #passOverTime"

      curYear = new Date().getFullYear()
      years = _.range(2012, curYear)
      values = years.map (x) -> item["pass_" + x]
      _.zip(years, values).map( (x) -> {"key": x[0], "val": x[1]})

]
