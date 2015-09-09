'use strict'

describe 'utils', ->

  # load the service's module
  beforeEach module 'edudashAppSrv'

  # grab the service
  u = null
  beforeEach inject (_utils_) ->
    u = _utils_

  # mocks
  $q = null
  $timeout = null
  $rootScope = null
  beforeEach inject (_$q_, _$timeout_, _$rootScope_) ->
    $q = _$q_
    $timeout = _$timeout_
    $rootScope = _$rootScope_

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
        .toThrow new Error "param `prop` must be a string. Got 'undefined'"
      expect -> u.rangeFilter 0
        .toThrow new Error "param `prop` must be a string. Got 'number'"
      expect -> u.rangeFilter 'prop'
        .toThrow new Error "param `min` must be a number. Got 'undefined'"
      expect -> u.rangeFilter 'prop', 'a string'
        .toThrow new Error "param `min` must be a number. Got 'string'"
      expect -> u.rangeFilter 'prop', 0
        .toThrow new Error "param `max` must be a number. Got 'undefined'"
      expect -> u.rangeFilter 'prop', 0, 'a string'
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

  describe 'debounce', ->
    it 'shoud validate its params', ->
      expect -> u.debounce()
        .toThrow new Error "param `wait` must be a number. Got 'undefined'"
      expect -> u.debounce 1.5, -> 0
        .toThrow new Error "param `wait` must be an integer. Got 1.5"
      expect -> u.debounce 100
        .toThrow new Error "param 'fn' must be a function. Got 'undefined'"

    it 'should not call the function synchronously', ->
      called = false
      deb = u.debounce 0, -> called = true
      deb()
      expect called
        .toBe false

    it 'should call the function', ->
      called = false
      deb = u.debounce 0, -> called = true
      deb()
      $timeout.flush()
      expect called
        .toBe true

    it 'should not call the function more than once', ->
      count = 0
      deb = u.debounce 0, -> count += 1
      deb()
      deb()
      $timeout.flush()
      expect count
        .toBe 1

    it 'should pass the last-provided arguments to the debounced function', ->
      result = null
      deb = u.debounce 0, (a) -> result = a
      deb 'one'
      $timeout.flush()
      expect result
        .toEqual 'one'
      deb 'flew'
      deb 'over'
      $timeout.flush()
      expect result
        .toEqual 'over'

  describe 'lookup', ->
    it 'should validate its params', ->
      expect -> u.lookup()
        .toThrow new Error "param `mapP` must be a Promise. Got 'undefined'"
      expect -> u.lookup {}
        .toThrow new Error "param `mapP` must be a Promise. Got 'object'"
      expect -> u.lookup $q.when {}
        .toThrow new Error "param `id` must be a string. Got 'undefined'"

      caught = null
      u.lookup $q.when(undefined), 'z'
        .catch (e) -> caught = e
      $rootScope.$apply()
      expect caught
        .toEqual "Promise `mapP` must resolve to an object. Got 'undefined'"

    it 'should return a promise', ->
      expect typeof (u.lookup $q.when({}), '').then
        .toEqual 'function'

    it 'should resolve null for empty object map', ->
      found = 'blah'
      u.lookup $q.when({}), 'z'
        .then (s) -> found = s
      $rootScope.$apply()
      expect found
        .toBe null

    it 'should resolve null for missing object', ->
      found = 'blah'
      u.lookup $q.when(a: {id: 'a'}), 'b'
        .then (s) -> found = s
      $rootScope.$apply()
      expect found
        .toBe null

    it 'should find the object by id', ->
      s = id: 'a'
      found = null
      u.lookup $q.when(a: s), 'a'
        .then (s) -> found = s
      $rootScope.$apply()
      expect found
        .toBe s

      found2 = null
      u.lookup $q.when(a: s, x: {id: 'x'}, y: {id: 'y'}), 'a'
        .then (s) -> found2 = s
      $rootScope.$apply()
      expect found2
        .toBe s

    it 'should validate that the map is not null (regression)', ->
      caught = null
      u.lookup $q.when(null), 'z'
        .catch (e) -> caught = e
      $rootScope.$apply()
      expect caught
        .toEqual "Promise `mapP` must resolve to an object. Got 'null'"

  describe 'max', ->
    it 'should validate its params', ->
      expect -> u.max $q.when {}
        .toThrow new Error "param `prop` must be a string. Got 'undefined'"
      expect -> u.max(($q.when {}), 1)
        .toThrow new Error "param `prop` must be a string. Got 'number'"
      expect -> u.max(($q.when {}), 'PASS_RATE')
        .toThrow new Error "param `defaultMax` must be a number. Got 'undefined'"
      expect -> u.max(($q.when {}), 'PASS_RATE', '0')
        .toThrow new Error "param `defaultMax` must be a number. Got 'string'"

    it 'should return the default if no values', ->
      max = null
      u.max ($q.when []), 'z', 1
        .then (m) -> max = m
      $rootScope.$apply()
      expect max
        .toEqual 1

    it 'should return the default if no values are higher', ->
      max = null
      u.max ($q.when [{z: 1}]), 'z', 2
        .then (m) -> max = m
      $rootScope.$apply()
      expect max
        .toEqual 2

    it 'should return the highest value higher than default', ->
      max = null
      u.max ($q.when [{z: 2}]), 'z', 1
        .then (m) -> max = m
      $rootScope.$apply()
      expect max
        .toEqual 2

      max2 = null
      u.max ($q.when [{z: 2}, {z: 3}]), 'z', 1
        .then (m) -> max2 = m
      $rootScope.$apply()
      expect max2
        .toEqual 3
