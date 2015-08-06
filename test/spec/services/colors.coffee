'use strict'

describe 'watchComputeSrv', ->

  # load the service's module
  beforeEach module 'edudashAppSrv'

  # grab the service
  c = null
  beforeEach inject (_colorSrv_) ->
    c = _colorSrv_

  it 'should validate colour() parameters', ->
    expect -> c.color()
      .toThrow new Error "Unknown bracket: 'undefined'"
    expect -> c.color {}
      .toThrow new Error "Unknown bracket: '[object Object]'"
    expect -> c.color _: 'GOOD'
      .toThrow new Error "Unknown bracket: '[object Object]'"

  it 'should return hex colour strings from colour()', ->
    expect(typeof c.color 'GOOD').toEqual 'string'
    expect(typeof c.color 'MEDIUM').toEqual 'string'
    expect(typeof c.color 'POOR').toEqual 'string'
    expect(typeof c.color 'UNKNOWN').toEqual 'string'
    expect((c.color 'GOOD').slice(0, 1)).toEqual '#'
    expect((c.color 'MEDIUM').slice(0, 1)).toEqual '#'
    expect((c.color 'POOR').slice(0, 1)).toEqual '#'
    expect((c.color 'UNKNOWN').slice(0, 1)).toEqual '#'
