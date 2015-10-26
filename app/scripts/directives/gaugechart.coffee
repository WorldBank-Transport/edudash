'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:gaugeChart
 # @description
 # # gaugeChart
###
angular.module 'edudashAppDir'
  .directive 'gaugeChart', ($translate, colorSrv, bracketsSrv) ->
      restrict: 'EA'
      template: '<div class="loading"></div>'
      link: (scope, element, attrs) ->
        gaugeValue = undefined
        update = (value) ->
          gaugeValue = value
          ranges = bracketsSrv.getBrackets(attrs.property)
          labelColor = colorSrv.color bracketsSrv.getBracket value, attrs.property
          width = element.parent().width()
          gaugeOptions =
            chart:
              type: 'gauge'
              plotBackgroundColor: '#FFF'
              plotBackgroundImage: null
              plotBorderWidth: 0
              plotShadow: false
              height: 100
              width: width + 20
              margin: [0, 0, 0, 0]
              spacingLeft: 1
            credits:
              enabled: false
            tooltip:
              enabled: false
            title:
              text: "<div class='col-md-12 gauge-title #{attrs.chartTitleClass}'>
                       <span class='chart-title ng-binding'>#{attrs.chartTitle}</span>
                     </div>"
              useHTML: true
              y: 60
              width: width + 40
              align: 'center'
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
                  from: ranges[0]
                  to: ranges[1]
                  color: colorSrv.color bracketsSrv.getBracket ranges[0]+1, attrs.property
                  thickness: '25%'
                }
                {
                  from: ranges[1]
                  to: ranges[2]
                  color: colorSrv.color bracketsSrv.getBracket ranges[1]+1, attrs.property
                  thickness: '25%'
                }
                {
                  from: ranges[2]
                  to: ranges[3]
                  color: colorSrv.color bracketsSrv.getBracket ranges[2]+1, attrs.property
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
                  '<p class="medium-character missing-data gauge-na">' + na + '</p>
                   <div class="col-md-12 gauge-title withoutchart">
                     <span class="chart-title ng-binding gauge ' + attrs.chartTitleClass + '">'+attrs.chartTitle+'</span>
                   </div>')

        attrs.$observe 'chartTitle', (value) ->
          # TODO This way we could custom the style for swahilli
          chart = element.highcharts()
          width = element.parent().width()
          unless gaugeValue
            $translate('chart.metric.missing-data').then (na) ->
              element.html(
                "<p class='medium-character missing-data gauge-na'>#{na}</p>
                 <div class='col-md-12 gauge-title withoutchart #{if value.length > 20 then 'swahili-title' else ''}'>
                   <span class='chart-title ng-binding gauge'>#{value}</span>
                 </div>")
          else if(chart?)
            titleObj =
              text: "<div class='col-md-12 gauge-title #{if value.length > 20 then 'swahili-title' else ''}'>
                       <span class='chart-title ng-binding gauge'>#{value}</span>
                     </div>"
              useHTML: true
              y: 60
              width: width + 40
              align: 'center'
              style:
                color: '#05a2dc'
            chart.setTitle(titleObj)
