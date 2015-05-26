'use strict'

describe 'Controller: SpeakoutCtrl', ->

  # load the controller's module
  beforeEach module 'edudashAppCtrl'

  SpeakoutCtrl = {}
  scope = {}

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()
    SpeakoutCtrl = $controller 'SpeakoutCtrl', {
      $scope: scope
    }

  it 'should attach a list of awesomeThings to the scope', ->
    expect(scope.awesomeThings.length).toBe 3
