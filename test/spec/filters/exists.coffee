'use strict'

describe 'Filter: exists', ->

  # load the filter's module
  beforeEach module 'edudashApp'

  # initialize a new instance of the filter before each test
  exists = {}
  beforeEach inject ($filter) ->
    exists = $filter 'exists'

  it 'should return the input prefixed with "exists filter:"', ->
    text = 'angularjs'
    expect(exists text).toBe ('exists filter: ' + text)
