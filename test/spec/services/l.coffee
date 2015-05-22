'use strict'

describe 'Service: L', ->

  # load the service's module
  beforeEach module 'edudashAppSrv'

  # instantiate service
  L = {}
  beforeEach inject (_L_) ->
    L = _L_

  # there is not a meaningful way to test leaflet, at least until we drop
  # cartodb
