'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:rankChart
 # @description
 # # rankChart
###
angular.module 'edudashAppDir'
.directive 'rankChart', (colorSrv) ->
    restrict: 'EA'
    template: '<div class="loading"></div>'
    # TODO: pass selectedSchool by props instead of using the parent scope
    link: (scope, element, attrs) ->
      scope.$watch attrs.datasource, (newValue, oldValue) -> if newValue?
        width = element.parent().width()
        element.highcharts({
            exporting:
              enabled: false
            credits:
              enabled: false
            chart:
              plotShadow: false
              height: 30
              width: width
            title:
              text: ""
              margin: 0
          }, (chart)->
            renderer = chart.renderer
            if (newValue.rank?)
              rank = newValue.rank
              worstRank = newValue.total
              lineRange = width * 0.6;
              startLine = width - lineRange;
              n=5
              section = lineRange/n
              group = renderer.g("highcharts-national-rank").add();
              padding = switch
                when rank < 10 then 0
                when rank < 100 then 0
                when rank < 1000 then 0
                when rank < 10000 then 0
                else 0
              renderer.label('<span class="rank-widgetnumber">' + rank + '</span>', padding, 0, undefined, 0, 0, true, true, 'widgetnumber').add(group)
              chartCenter = 20
              renderer.path(['M', startLine, chartCenter, 'L', startLine + section, chartCenter]).attr({
                'stroke-width': 4,
                stroke: colorSrv.color('POOR'),
                dashstyle: 'Solid'
              }).add(group);
              renderer.path(['M', startLine + section, chartCenter, 'L', startLine + section*(n-1), chartCenter])
              .attr({
                    'stroke-width': 4,
                    stroke: '#989898',
                    dashstyle: 'Solid'
                  })
              .add(group);
              renderer.path(['M', startLine + section*(n-1), chartCenter, 'L', startLine + lineRange, chartCenter])
              .attr({
                    'stroke-width': 4,
                    stroke: colorSrv.color('GOOD'),
                    dashstyle: 'Solid'
                  })
              .add(group);
              x = lineRange - (rank * lineRange / worstRank)
              labelColor = switch
                when x  > (section * (n-1)) then colorSrv.color('GOOD')
                when x  < section then colorSrv.color('POOR')
                else '#a1a1a1'
              arrowLength = 10
              arrowHalf = arrowLength / 2
              margin = 2
              start = startLine + x - margin
              renderer.path(['M', start - arrowHalf, chartCenter - arrowLength - margin,
                             'L', start + arrowHalf, chartCenter - arrowLength - margin,
                             'L', start, chartCenter - margin,
                             'L', start - arrowHalf, chartCenter - arrowLength - margin])
              .attr({
                    'stroke-width': 1,
                    stroke: labelColor,
                    fill: labelColor
                  })
              .add(group);
            else
              element.html('<span class="medium-character missing-data" style="position: static">Missing Data</span>')
          )

