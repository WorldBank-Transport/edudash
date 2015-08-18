'use strict'

describe 'utils', ->

  # load the service's module
  beforeEach module 'edudashAppSrv'

  # grab the service
  u = null
  beforeEach inject (_utils_) ->
    u = _utils_

  it 'should validate its parameters parameters', ->
    expect -> u.rank()
      .toThrow new Error "param `item` must be an object. Got 'undefined'"
    expect -> u.rank {}
      .toThrow new Error "param `list` must be an Array. Got 'undefined'"
    expect -> u.rank {}, []
      .toThrow new Error "param `rankProp` must be a string. Got 'undefined'"

  it 'should throw if `item` is not in `list`', ->
    o = a: 1
    expect -> u.rank o, [], 'a'
      .toThrow new Error "`item` must be in `list`"
    expect -> u.rank o, [a: 2], 'a'
      .toThrow new Error "`item` must be in `list`"

  it 'should rank an object missing `rankBy` as `undefined`', ->
    o = {}
    expect u.rank o, [o], 'a'
      .toEqual rank: undefined, total: 1

  it 'should should rank an object missing `groupBy` as `undefined`', ->
    o = a: 1
    expect u.rank o, [o], 'a', 'b'
      .toEqual rank: undefined, total: 0

  it 'should 1-index the rank', ->
    o = a: 1
    expect u.rank o, [o], 'a'
      .toEqual rank: 1, total: 1
    expect u.rank o, [o, a: 2], 'a'
      .toEqual rank: 1, total: 2
    expect u.rank o, [o, a: 0], 'a'
      .toEqual rank: 2, total: 2

  it 'should filter to the groupBy parameter', ->
    o = a: 1, b: 'z'
    expect u.rank o, [o], 'a', 'b'
      .toEqual rank: 1, total: 1
    expect u.rank o, [o, {a: 2}], 'a', 'b'
      .toEqual rank: 1, total: 1
    expect u.rank o, [o, {a: 2, b: 'y'}], 'a', 'b'
      .toEqual rank: 1, total: 1
    expect u.rank o, [o, {a: 2, b: 'z'}], 'a', 'b'
      .toEqual rank: 1, total: 2
    expect u.rank o, [o, {a: 0, b: 'z'}], 'a', 'b'
      .toEqual rank: 2, total: 2

  it 'should rank ascending or descending', ->
    o = a: 1
    expect u.rank o, [o], 'a', null, 'ASC'
      .toEqual rank: 1, total: 1
    expect u.rank o, [o], 'a', null, 'DESC'
      .toEqual rank: 1, total: 1
    expect u.rank o, [o, {a: 2}], 'a', null, 'ASC'
      .toEqual rank: 1, total: 2
    expect u.rank o, [o, {a: 2}], 'a', null, 'DESC'
      .toEqual rank: 2, total: 2
