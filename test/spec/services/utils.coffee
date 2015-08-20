'use strict'

describe 'utils', ->

  # load the service's module
  beforeEach module 'edudashAppSrv'

  # grab the service
  u = null
  beforeEach inject (_utils_) ->
    u = _utils_

  describe 'rank', ->

    it 'should validate its parameters parameters', ->
      expect -> u.rank()
        .toThrow new Error "param `item` must be an object. Got 'undefined'"
      expect -> u.rank {}
        .toThrow new Error "param `list` must be an Array. Got 'undefined'"
      expect -> u.rank {}, []
        .toThrow new Error "param `rankProp` must be a string. Got 'undefined'"
      o = {}
      expect -> u.rank o, [o], 'a', null, true
        .toThrow new Error "param `order` must be 'ASC' or 'DESC'. Got boolean 'true'"
      expect -> u.rank o, [o], 'a', null, 'z'
        .toThrow new Error "param `order` must be 'ASC' or 'DESC'. Got string 'z'"

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

    it 'should have a total and rank reflecting the groupBy filtering', ->
      o = a: 1, b: 'z'
      expect u.rank o, [o, {a: 0, b: 'y'}], 'a', 'b'
        .toEqual rank: 1, total: 1


  describe 'rangeFilter', ->

    it 'should validate its params', ->
      expect -> u.rangeFilter()
        .toThrow new Error "param `props` must be a string. Got 'undefined'"
      expect -> u.rangeFilter 0
        .toThrow new Error "param `props` must be a string. Got 'number'"
      expect -> u.rangeFilter 'prop'
        .toThrow new Error "param `min` must be a number. Got 'undefined'"
      expect -> u.rangeFilter 'prop', 'a string'
        .toThrow new Error "param `min` must be a number. Got 'string'"
      expect -> u.rangeFilter 'prop', 0
        .toThrow new Error "param `max` must be a number. Got 'undefined'"
      expect -> u.rangeFilter 'prop', 'a string'
        .toThrow new Error "param `max` must be a number. Got 'string'"
      expect -> u.rangeFilter 'prop', 0, -1
        .toThrow new Error "invalid range [0, -1]"

    it 'should return a function', ->
      expect typeof u.rangeFilter 'a prop', 0, 1
        .toEqual 'function'

    it 'should pass an emty list throug', ->
      expect [].filter u.rangeFilter 'a prop', 0, 1
        .toEqual []

    it 'should include an object meeting the filter criteria', ->
      expect [{p: 0}].filter u.rangeFilter 'p', 0, 1
        .toEqual [{p: 0}]
      expect [{p: 0.5}].filter u.rangeFilter 'p', 0, 1
        .toEqual [{p: 0.5}]
      expect [{p: 1}].filter u.rangeFilter 'p', 0, 1
        .toEqual [{p: 1}]
      expect [{p: 0}].filter u.rangeFilter 'p', 0, 0
        .toEqual [{p: 0}]

    it 'should exclude objects with props failing the criteria', ->
      expect [{p: 2}].filter u.rangeFilter 'p', 0, 1
        .toEqual []
      expect [{p: -1}].filter u.rangeFilter 'p', 0, 1
        .toEqual []

    it 'should include objects missing the prop', ->
      expect [{z: 0}].filter u.rangeFilter 'p', 0, 1
        .toEqual [{z: 0}]
