'use strict'

describe 'Directive: gaugeChart', ->

  # load the directive's module
  beforeEach module 'edudashAppDir'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

#  it 'should make hidden element visible', inject ($compile) ->
#    element = angular.element '<gauge-chart></gauge-chart>'
#    element = $compile(element) scope
#    expect(element.text()).toBe 'this is the gaugeChart directive'
