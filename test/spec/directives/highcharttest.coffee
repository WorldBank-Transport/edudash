'use strict'

describe 'Directive: highchartTest', ->

  # load the directive's module
  beforeEach module 'edudashAppDir'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

#need to investigate how to create a test for highchart
#  it 'should make hidden element visible', inject ($compile) ->
#    element = angular.element '<highchart-test></highchart-test>'
#    element = $compile(element) scope
#    expect(element.text()).toBe ''
