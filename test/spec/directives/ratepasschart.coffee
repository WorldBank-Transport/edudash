'use strict'

describe 'Directive: ratePassChart', ->

  # load the directive's module
  beforeEach module 'edudashApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element', inject ($compile) ->
    element = angular.element '<rate-pass-chart></rate-pass-chart>'
    element = $compile(element) scope
    expect(element.text()).toBe ''

