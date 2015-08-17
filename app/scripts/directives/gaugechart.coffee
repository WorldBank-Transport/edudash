'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:gaugeChart
 # @description
 # # gaugeChart
###
angular.module 'edudashAppDir'
  .directive 'gaugeChart', ['$translate', ($translate) ->
    restrict: 'EA'
    template: '<div class="loading"></div>'
    link: (scope, element, attrs) ->
      update = (value) ->
        ranges = attrs.ranges.split(',')
        colors = attrs.colors.split(',')
        labelColor = switch
          when value < ranges[0] then colors[0]
          when value > ranges[1] then colors[2]
          else colors[1]

        width = element.parent().width()
        gaugeOptions =
          chart:
            type: 'gauge'
            plotBackgroundColor: '#FFF'
            plotBackgroundImage: null
            plotBorderWidth: 0
            plotShadow: false
            height: 110
            width: width + 20
            margin: [0, 0, 0, 0]
            spacingLeft: 1
          credits:
            enabled: false
          title:
            text: "<span style='font-size: 10px;text-transform: uppercase;'>#{attrs.title}</span>"
            useHTML: true
            y: 70
            width: width + 40
            align: 'left'
            style:
              color: '#05a2dc'
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
                  fontSize: '12px'
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
            name: attrs.tooltip
            data: [value]
          }]
        element.highcharts(gaugeOptions)

      datasource = attrs.datasource
      scope.$watch datasource, (newValue, oldValue) ->
        if newValue?
          update(parseFloat(newValue.toFixed(1)))
        else
          $translate('chart.metric.missing-data').then (na) ->
            element.html(
                '<p class="medium-character missing-data" style="position: static">' + na + '</p>
                 <div class="col-md-12" style="position: absolute; white-space: nowrap; margin-left: 0px; margin-top: 5px; left: -5px; top: 64px;">
                   <span class="chart-title ng-binding" style="font-size: 10px; font-weight: bold;">'+attrs.title+'</span>
                 </div>')

      attrs.$observe 'title', (value) ->
        # TODO This way we could custom the style for swahilli
        chart = element.highcharts()
        width = element.parent().width()
        if(chart?)
          titleObj =
            text: "<span style='font-size: 10px;text-transform: uppercase;'>#{value}</span>"
            useHTML: true
            y: 70
            width: width + 40
            align: 'left'
            style:
              color: '#05a2dc'
          chart.setTitle(titleObj)
  ]