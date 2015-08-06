'use strict'

describe 'watchComputeSrv', ->

  # load the service's module
  beforeEach module 'edudashAppSrv'

  # grab the service
  b = null
  beforeEach inject (_bracketsSrv_) ->
    b = _bracketsSrv_


  it 'should provide brackets for good, med, poor, unknown', ->
    expect(b.bracket.GOOD?).toBe true
    expect(b.bracket.MEDIUM?).toBe true
    expect(b.bracket.POOR?).toBe true
    expect(b.bracket.UNKNOWN?).toBe true

  it 'should provide unique brackets', ->
    expect(b.bracket.GOOD in [
        b.bracket.MEDIUM,
        b.bracket.POOR,
        b.bracket.UNKNOWN,
      ]).toBe false
    expect(b.bracket.MEDIUM in [
        b.bracket.POOR,
        b.bracket.UNKNOWN,
      ]).toBe false
    expect(b.bracket.POOR == b.bracket.UNKNOWN).toBe false

  it 'should validate getMetric parameters', ->
    expect -> b.getMetric()
      .toThrow new Error "Unknown school type 'undefined'"
    expect -> b.getMetric 'bad school type'
      .toThrow new Error "Unknown school type 'bad school type'"
    expect -> b.getMetric 'primary'
      .toThrow new Error "Unknown criteria 'undefined'"
    expect -> b.getMetric 'primary', 'bad criteria'
      .toThrow new Error "Unknown criteria 'bad criteria'"

  it 'should provide the correct metric from getMetric', ->
    # exhaustive check because we can
    expect b.getMetric 'primary', 'performance'
      .toEqual 'AVG_MARK'
    expect b.getMetric 'primary', 'improvement'
      .toEqual 'CHANGE_PREVIOUS_YEAR'
    expect b.getMetric 'secondary', 'performance'
      .toEqual 'AVG_GPA'
    expect b.getMetric 'secondary', 'improvement'
      .toEqual 'CHANGE_PREVIOUS_YEAR_GPA'

  it 'should validate getBracket parameters', ->
    expect -> b.getBracket 'z'
      .toThrow new Error "val must be a number. Got: 'z' which is 'string'"
    expect -> b.getBracket 1
      .toThrow new Error "Unknown metric: 'undefined'"
    expect -> b.getBracket 1, 'not a metric'
      .toThrow new Error "Unknown metric: 'not a metric'"

  it 'should return UNKNOWN for NaN', ->
    expect(b.getBracket NaN, 'AVG_MARK').toBe b.bracket.UNKNOWN
    expect(b.getBracket NaN, 'AVG_GPA').toBe b.bracket.UNKNOWN
    expect(b.getBracket NaN, 'CHANGE_PREVIOUS_YEAR').toBe b.bracket.UNKNOWN
    expect(b.getBracket NaN, 'CHANGE_PREVIOUS_YEAR_GPA').toBe b.bracket.UNKNOWN
    expect(b.getBracket undefined, 'AVG_MARK').toBe b.bracket.UNKNOWN

  it 'AVG_MARK ranges', ->
    expect(b.getBracket -1, 'AVG_MARK').toBe b.bracket.UNKNOWN
    expect(b.getBracket 0,  'AVG_MARK').toBe b.bracket.POOR
    expect(b.getBracket 39, 'AVG_MARK').toBe b.bracket.POOR
    expect(b.getBracket 40, 'AVG_MARK').toBe b.bracket.MEDIUM
    expect(b.getBracket 60, 'AVG_MARK').toBe b.bracket.MEDIUM
    expect(b.getBracket 61, 'AVG_MARK').toBe b.bracket.GOOD
    expect(b.getBracket 100,'AVG_MARK').toBe b.bracket.GOOD
    expect(b.getBracket 101,'AVG_MARK').toBe b.bracket.UNKNOWN

  it 'AVG_GPA ranges', ->
    expect(b.getBracket 0,  'AVG_GPA').toBe b.bracket.UNKNOWN
    expect(b.getBracket 1,  'AVG_GPA').toBe b.bracket.POOR
    expect(b.getBracket 3,  'AVG_GPA').toBe b.bracket.POOR
    expect(b.getBracket 3.1,'AVG_GPA').toBe b.bracket.MEDIUM
    expect(b.getBracket 4.2,'AVG_GPA').toBe b.bracket.MEDIUM
    expect(b.getBracket 4.3,'AVG_GPA').toBe b.bracket.GOOD
    expect(b.getBracket 5,  'AVG_GPA').toBe b.bracket.GOOD
    expect(b.getBracket 5.1,'AVG_GPA').toBe b.bracket.UNKNOWN

  it 'CHANGE_PREVIOUS_YEAR ranges', ->
    expect(b.getBracket -1,'CHANGE_PREVIOUS_YEAR').toBe b.bracket.POOR
    expect(b.getBracket 0, 'CHANGE_PREVIOUS_YEAR').toBe b.bracket.MEDIUM
    expect(b.getBracket 1, 'CHANGE_PREVIOUS_YEAR').toBe b.bracket.GOOD

  it 'CHANGE_PREVIOUS_YEAR_GPA ranges', ->
    expect(b.getBracket -1,'CHANGE_PREVIOUS_YEAR_GPA').toBe b.bracket.POOR
    expect(b.getBracket 0, 'CHANGE_PREVIOUS_YEAR_GPA').toBe b.bracket.MEDIUM
    expect(b.getBracket 1, 'CHANGE_PREVIOUS_YEAR_GPA').toBe b.bracket.GOOD

  it 'should validate colour() parameters', ->
    expect -> b.colour()
      .toThrow new Error "Unknown bracket: 'undefined'"
    expect -> b.colour {}
      .toThrow new Error "Unknown bracket: '[object Object]'"
    expect -> b.colour _: 'GOOD'
      .toThrow new Error "Unknown bracket: '[object Object]'"

  it 'should return hex colour strings from colour()', ->
    expect(typeof b.colour b.bracket.GOOD).toEqual 'string'
    expect(typeof b.colour b.bracket.MEDIUM).toEqual 'string'
    expect(typeof b.colour b.bracket.POOR).toEqual 'string'
    expect(typeof b.colour b.bracket.UNKNOWN).toEqual 'string'
    expect((b.colour b.bracket.GOOD).slice(0, 1)).toEqual '#'
    expect((b.colour b.bracket.MEDIUM).slice(0, 1)).toEqual '#'
    expect((b.colour b.bracket.POOR).slice(0, 1)).toEqual '#'
    expect((b.colour b.bracket.UNKNOWN).slice(0, 1)).toEqual '#'
