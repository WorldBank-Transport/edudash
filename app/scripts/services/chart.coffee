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
      _.zip(years, values).map( (x) -> {"key": x[0], "val": x[1]})

]
