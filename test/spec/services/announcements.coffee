'use strict'

describe 'Service: _', ->

  # load the service's module
  beforeEach module 'edudashAppSrv'

  # instantiate service
  announcements = null
  beforeEach inject (_announcements_) ->
    announcements = _announcements_

  it 'should expose a listen function', ->
    expect(typeof announcements).toBe 'function'

  it 'should return an unlisten function when listened to', ->
    expect(typeof (announcements () -> null)).toBe 'function'
