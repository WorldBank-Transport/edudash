'use strict'

describe 'Controller: BrnCtrl', ->

  # load the controller's module
  beforeEach module 'edudashAppCtrl'

  BrnCtrl = {}
  scope = {}

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()
    BrnCtrl = $controller 'BrnCtrl', {
      $scope: scope
    }

  it 'should attach a list of awesomeThings to the scope', ->
    expect(scope.awesomeThings.length).toBe 3
