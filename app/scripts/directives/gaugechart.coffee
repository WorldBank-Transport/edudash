'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:gaugeChart
 # @description
 # # gaugeChart
###
angular.module 'edudashAppDir'
  .directive 'gaugeChart', ->
    restrict: 'EA'
    scope:
      data: '=datasource'
    template: '<div>not working</div>'
    link: (scope, element, attrs) ->
      ranges = attrs.ranges.split(',')
      colors = attrs.colors.split(',')
      value = scope.data
      labelColor = switch
        when value < ranges[0] then colors[0]
        when value > ranges[1] then colors[2]
        else colors[1]

      gaugeOptions =
        chart:
          type: 'gauge'
          plotBackgroundColor: '#FFF'
          plotBackgroundImage: null
          plotBorderWidth: 0
          plotShadow: false
          height: 110
          width: element.parent().width()
          margin: [0, 0, 0, 0]
          spacingLeft: 1
        credits:
          enabled: false
        title:
          text: attrs.title
          y: 70
          style:
            color: '#05a2dc'
            fontSize: 11
            marginBottom: 2
        pane:
          size: '100%'
          startAngle: -90
          endAngle: 90
          BorderWidth: 0
          background: [{
            backgroundColor: '#fff',
            borderWidth: 0
          }]
        exporting:
          enabled: false
        plotOptions:
          gauge:
            dataLabels:
              borderWidth: 0
              y: -40
              format: attrs.format
              style:
                fontWeight: 'bold'
                fontSize: '14px'
                color: labelColor
                textShadow: null
            dial:
              radius: '25%'
              backgroundColor: 'black'
              borderColor: 'black'
              borderWidth: 1
              baseWidth: 15
              topWidth: 1
              baseLength: '5%'
              rearLength: '10%'
        yAxis:
          min: 0
          max: 100
          minorTickInterval: 'auto'
          minorTickWidth: 0
          minorTickLength: 10
          minorTickPosition: 'inside'
          minorTickColor: '#666'
          tickPixelInterval: 50
          tickWidth: 0
          tickPosition: 'inside'
          tickLength: 10
          tickColor: '#666'
          labels:
            enabled: false
          plotBands: [
            {
              from: 0
              to: ranges[0]
              color: colors[0]
              thickness: '25%'
            }
            {
              from: ranges[0]
              to: ranges[1]
              color: colors[1]
              thickness: '25%'
            }
            {
              from: ranges[1]
              to: 100
              color: colors[2]
              thickness: '25%'
            }
          ]
        series: [{
          name: 'Rate'
          data: [value]
          tooltip: {
            valueSuffix: ' rate'
          }
        }]
      element.highcharts(gaugeOptions)