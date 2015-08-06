'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:rankChart
 # @description
 # # rankChart
###
angular.module 'edudashAppDir'
.directive 'rankChart', ->
    restrict: 'EA'
    template: '<div class="loading"></div>'
    link: (scope, element, attrs) ->
      scope.$watch 'selected.ranks.national', (newValue, oldValue) -> if newValue?
        width = element.parent().width()
        element.highcharts({
            exporting:
              enabled: false
            credits:
              enabled: false
            chart:
              plotShadow: false
              height: 50
              width: width
            title:
              text: ""
              margin: 0
          }, (chart)->
            rank = newValue.rank
            worstRank = newValue.total
            lineRange = width * 0.7;
            startLine = width - lineRange;
            n=5
            section = lineRange/n
            renderer = chart.renderer
            group = renderer.g("highcharts-national-rank").add();
            renderer.label('' + rank, 5, -5).attr("class", "widgetnumber")
              .add(group)
            chartCenter = 20
            renderer.path(['M', startLine, chartCenter, 'L', startLine + section, chartCenter]).attr({
              'stroke-width': 4,
              stroke: '#f56053',
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
                  stroke: '#38a21c',
                  dashstyle: 'Solid'
                })
            .add(group);
            x = lineRange - (rank * lineRange / worstRank)
            labelColor = switch
              when x  > (section * (n-1)) then '#38a21c'
              when x  < section then '#f56053'
              else '#a1a1a1'
            arrowLength = 15
            arrowDirection = if x  < (lineRange/2) then -1*arrowLength else arrowLength
            start = startLine + x - arrowDirection
            renderer.path(['M', start, 27,
                           'L', start, 15,
                           'L', start + arrowDirection, chartCenter,
                           'L', start, 25])
            .attr({
                  'stroke-width': 3,
                  stroke: labelColor, fill: labelColor
                })
            .add(group);
          )

