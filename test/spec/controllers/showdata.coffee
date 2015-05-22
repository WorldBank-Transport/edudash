'use strict'

describe 'Controller: ShowdataCtrl', ->

  # load the controller's module
  beforeEach module 'edudashAppCtrl'

  ShowdataCtrl = {}
  scope = {}

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()
    ShowdataCtrl = $controller 'ShowdataCtrl', {
      $scope: scope
      $log: {}
      OpenDataApi:
        getCsv: ->
          getDataSet: ->
            data:
              result:
                fields: []
                records: []
        getDatasetType: ->
          then: ->
            data:
              result:
                resources: []
    }

  it 'should attach a list of awesomeThings to the scope', ->
    expect(scope.awesomeThings.length).toBe 3
