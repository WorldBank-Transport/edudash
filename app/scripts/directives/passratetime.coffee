'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:passRateTime
 # @description
 # # passRateTime
###
angular.module 'edudashAppDir'
  .directive 'passRateTime', ->
    restrict: 'EA'
    template: '<div class="loading"></div>'
    link: (scope, element, attrs) ->
      updateChart = (value) ->
        ranges = attrs.ranges.split(',')
        colors = attrs.colors.split(',')
        lineOptions =
          chart:
            type: 'line'
            height: 120
            width: element.parent().width()
            margin: [10, 0, 0, 0]
            spacingLeft: 1
          credits:
            enabled: false
          exporting:
            enabled: false
          legend:
            enabled: false
          title:
            text: "<span style='font-size: 10px;text-transform: uppercase;'>#{attrs.title}</span>"
            useHTML: true
            x: -100
            style:
              color: '#05a2dc'
              fontSize: 10
          xAxis:
            categories: value.years
            labels:
              enabled: true
              style:
                fontWeight: 'bold'
              y: -10
          yAxis:
            gridLineWidth: 0
            title:
              text: ''
          plotOptions:
            line:
              color: 'silver'
              dataLabels:
                enabled: true
                padding: 10
                style:
                  fontSize: "14px", fontWeight: "bold"
                formatter: (format) ->
                  format.style.color = switch
                    when this.y < ranges[0] then colors[0]
                    when this.y > ranges[1] then colors[2]
                    else colors[1]
                  format.style.textShadow = null
                  return this.y + ' %'
              enableMouseTracking: true
            series:
              marker:
                radius: 8
                symbol: 'circle'
          series: [{
            name: 'Pass Rate',
            data: value.data
          }]
        element.highcharts(lineOptions)

      scope.$watch attrs.datasource, (newValue, oldValue) -> if newValue
        years = Object.keys newValue
          .map (y) -> parseInt y
          .sort()
        vals = years.map (y) -> [
          y,
          Math.round newValue[''+y].PASS_RATE  # explicit string-cast for key
        ]
        updateChart years: years, data: vals

      attrs.$observe 'title', (value) ->
        # TODO This way we could custom the style for swahilli
        chart = element.highcharts()
        if(chart?)
          titleObj =
            text: "<span style='font-size: 10px;text-transform: uppercase;'>#{value}</span>"
            useHTML: true
            x: -80
            style:
              color: '#05a2dc'
              fontSize: 10
          chart.setTitle(titleObj)