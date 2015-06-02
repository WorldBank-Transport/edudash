'use strict'

describe 'Directive: passRateTime', ->

  # load the directive's module
  beforeEach module 'edudashAppDir'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

#  it 'should make hidden element visible', inject ($compile) ->
#    element = angular.element '<pass-rate-time></pass-rate-time>'
#    element = $compile(element) scope
#    expect(element.text()).toBe 'this is the passRateTime directive'
