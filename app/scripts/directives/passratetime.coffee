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
    template: '<div></div>'
    scope:
      data: '=datasource'
    link: (scope, element, attrs) ->
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
          text: attrs.title
          align: 'left'
          style:
            color: '#05a2dc'
            fontSize: 10
        xAxis:
          categories: scope.data.x
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
          data: scope.data.y
        }]
      element.highcharts(lineOptions)
