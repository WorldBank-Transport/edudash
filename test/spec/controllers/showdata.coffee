'use strict'

describe 'Controller: ShowdataCtrl', ->

  # load the controller's module
  beforeEach module 'edudashApp'

  ShowdataCtrl = {}
  scope = {}

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()
    ShowdataCtrl = $controller 'ShowdataCtrl', {
      $scope: scope
    }

  it 'should attach a list of awesomeThings to the scope', ->
    expect(scope.awesomeThings.length).toBe 3
