'use strict'

describe 'Service: API', ->

  # load the service's module
  beforeEach module 'edudashAppSrv'

  # instantiate service
  api = {}
  beforeEach inject (_api_) ->
    api = _api_

#  it 'should do something', ->
#    expect(!!api).toBe true
