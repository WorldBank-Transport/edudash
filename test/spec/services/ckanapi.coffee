'use strict'

describe 'Service: CKanApi', ->

  # load the service's module
  beforeEach module 'edudashApp'

  # instantiate service
  CKanApi = {}
  beforeEach inject (_CKanApi_) ->
    CKanApi = _CKanApi_

  it 'should do something', ->
    expect(!!CKanApi).toBe true
