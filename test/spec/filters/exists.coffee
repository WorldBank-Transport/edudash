'use strict'

describe 'Filter: exists', ->

  # load the filter's module
  beforeEach module 'edudashApp'

  # initialize a new instance of the filter before each test
  exists = {}
  beforeEach inject ($filter) ->
    exists = $filter 'exists'

  it 'should be true for a defined variable', ->
    text = 'angularjs'
    expect(exists text).toBe true

  it 'should be false for an undefined variable', ->
    nothing = undefined
    expect(exists nothing).toBe false
