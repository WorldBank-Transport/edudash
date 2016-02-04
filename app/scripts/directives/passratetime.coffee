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
        lineOptions =
          chart:
            type: 'line'
            height: 120
            width: element.parent().width()
            marginLeft: 1
            marginTop:24
          credits:
            enabled: false
          exporting:
            enabled: false
          legend:
            enabled: false
          tooltip:
            enabled: false
          title:
            text: "<div class='col-md-12 passrate-time-title #{attrs.chartTitleClass}'>
                      <span class='chart-title ng-binding gauge'>#{attrs.chartTitle}</span>
                   </div>"
            useHTML: true
            align: 'left'
          xAxis:
            categories: value.years
            lineColor: '#FFFFFF'
            labels:
              enabled: true
              style:
                fontWeight: 'bold'
              y: 10
          yAxis:
            gridLineWidth: 0
            title:
              text: ''
          plotOptions:
            line:
              color: 'silver'
              dataLabels:
                enabled: true
                padding: 8
                style:
                  fontSize: "13px", fontWeight: "bold"
                formatter: () ->
                  return this.y + ' %'
            series:
              marker:
                radius: 6
                symbol: 'circle'
                lineWidth: 0
          series: [{
            name: 'Pass Rate',
            data: value.data
          }]
        element.highcharts(lineOptions)

      scope.$watch attrs.datasource, (newValue, oldValue) -> if newValue
        years = if newValue.years? then newValue.years.sort() else Object.keys(newValue).sort()
        values = if newValue.values? then newValue.values else newValue
        vals = years.map (y) -> {
          x: y,
          y: if values[''+y]? then Math.round values[''+y].PASS_RATE else 0 # explicit string-cast for key
          marker:
            fillColor: values[''+y].color
            states:
              hover:
                fillColor: values[''+y].color

        }
        updateChart years: years, data: vals

      attrs.$observe 'chartTitle', (value) ->
        # TODO This way we could custom the style for swahilli
        chart = element.highcharts()
        if(chart?)
          titleObj =
            text: "<div class='col-md-12 passrate-time-title #{if value.length > 20 then 'swahili-title' else ''}'>
                     <span class='chart-title school-panel-title ng-binding gauge'>#{value}</span>
                   </div>"
            useHTML: true
            align: 'left'
            style:
              color: '#05a2dc'
              fontSize: 10
          chart.setTitle(titleObj)
