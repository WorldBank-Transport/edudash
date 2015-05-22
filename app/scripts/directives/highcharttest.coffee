'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:highchartTest
 # @description
 # # highchartTest
###
angular.module 'edudashAppDir'
  .directive 'highchartTest', [
    '$log'
    ($log) ->
      restrict: 'E'
      template: '<div id="containerTest" style="margin: 0 auto; width: 120px; height: 80px; float: left">not working</div><div id="containerTest2" style="margin: 0 auto; width: 300px; height: 200px; float: left">not working</div>'
      link: (scope, element, attrs) ->
        gaugeOptions =
          chart:
            type: 'solidgauge'
            renderTo: 'containerTest'
          title: null
          pane:
            center: ['50%', '85%']
            size: '140%'
            startAngle: -90
            endAngle: 90
            background:
              backgroundColor: (Highcharts.theme && Highcharts.theme.background2) || '#EEE'
              innerRadius: '60%'
              outerRadius: '100%'
              shape: 'arc'
          tooltip:
            enabled: false
          yAxis:
            stops: [
              [0.1, '#55BF3B']
              [0.5, '#DDDF0D']
              [0.9, '#DF5353']
            ],
            lineWidth: 0
            minorTickInterval: null
            tickPixelInterval: 400
            tickWidth: 0
            title:
              y: -70
            labels:
              y: 16
          plotOptions:
            solidgauge:
              dataLabels:
                y: 5
                borderWidth: 0
                useHTML: true
        options =
          yAxis:
            min: 0
            max: 100
            title:
              text: 'Speed'
          credits:
            enabled: false
          series: [
            name: 'Speed'
            data: [80]
            dataLabels:
              format: '<div style="text-align:center"><span style="font-size:12px;color:' +
              ((Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black') + '">{y}</span>' +
              '</div>'
            tooltip:
              valueSuffix: ' pass rate'
          ]

#        options =
#          chart:
#            renderTo: 'containerTest'
#            plotBackgroundColor: null
#            plotBorderWidth: null
#            plotShadow: false
#          title:
#            text: 'Browser market shares at a specific website, 2010'
#          tooltip:
#            pointFormat: '{series.name}: <b>{point.percentage}%</b>'
#            percentageDecimals: 1
#          plotOptions:
#            pie:
#              allowPointSelect: true
#              cursor: 'pointer'
#              dataLabels:
#                enabled: true
#                color: '#000000'
#                connectorColor: '#000000'
#                formatter: () -> '<b>' + this.point.name + '</b>: ' + this.percentage + ' %'
#
#          series: [
#            type: 'pie'
#            name: 'Browser share'
#            data: [25, 50, 15, 10]
#          ]

        #        $('.highchartTest')
        $log.debug options
        chart2 = new Highcharts.Chart(Highcharts.merge(gaugeOptions, options))
        options2 =
          chart:
            type: 'gauge'
            renderTo: 'containerTest2'
            plotBackgroundColor: null
            plotBackgroundImage: null
            plotBorderWidth: 0
            plotShadow: false
          title:
            text: ''
          pane:
            startAngle: -150
            endAngle: 150
            background: [
              {
                backgroundColor:
                  linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1 }
                  stops: [
                    [0, '#FFF'],
                    [1, '#333']
                  ]
                borderWidth: 0
                outerRadius: '109%'
              }
              {
                backgroundColor:
                  linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1 }
                  stops: [
                    [0, '#333']
                    [1, '#FFF']
                  ]
                borderWidth: 1
                outerRadius: '107%'
              }
              {
                backgroundColor: '#DDD'
                borderWidth: 0
                outerRadius: '105%'
                innerRadius: '103%'
              }
            ]
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
              step: 2
              rotation: 'auto'
            title:
              text: ''
            plotBands: [
              {
                from: 0
                to: 40
                color: '#DF5353'
                thickness: '20%'
              }
              {
                from: 40
                to: 60
                color: '#DDDF0D'
                thickness: '20%'
              }
              {
                from: 60
                to: 100
                color: '#55BF3B'
                thickness: '20%'
              }
            ]
          series: [{
            name: 'Speed'
            data: [40]
            tooltip: {
              valueSuffix: ' rate'
            }
          }]
        $log.debug options2
        chart2 = new Highcharts.Chart(options2)
  ]