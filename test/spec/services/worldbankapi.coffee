'use strict'

describe 'Service: WorldBankApi', ->

  # load the service's module
  beforeEach module 'edudashApp'

  # instantiate service
  WorldBankApi = {}
  beforeEach inject (_WorldBankApi_) ->
    WorldBankApi = _WorldBankApi_

  it 'should do something', ->
    expect(!!WorldBankApi).toBe true
