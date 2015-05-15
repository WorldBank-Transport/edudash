'use strict'

describe 'Service: WorldBankApi', ->

  # load the service's module
  beforeEach module 'edudashApp'

  # instantiate service
  WorldBankApi = {}
  $httpBackend = {}
  beforeEach inject (_WorldBankApi_, _$httpBackend_) ->
    WorldBankApi = _WorldBankApi_
    $httpBackend = _$httpBackend_
    authRequestHandler = $httpBackend.when('GET', 'http://wbank.cartodb.com/api/v2/sql').respond({userId: 'userX'}, {'A-Token': 'xxx'});

  afterEach () ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  it 'should do something', ->
    expect(!!WorldBankApi).toBe true

  it 'mock an http request', ->
    level = 'primary'
    url = 'http://wbank.cartodb.com/api/v2/sql?api_key=ad10ae57cef93e98482aabcf021a738a028c168b&q=SELECT+*+FROM+wbank.tz_primary_cleaned_dashboard++ORDER+BY+rank_2014+ASC+LIMIT+100'
    $httpBackend.when('GET', url).respond({header1: 'value'}, {'data': 'xxx'});
    $httpBackend.expectGET url
    promise = WorldBankApi.getBestSchool level
    $httpBackend.flush()
    expect(!!promise).toBe true

  it 'best secondary school', ->
    level = 'secondary'
    url = 'http://wbank.cartodb.com/api/v2/sql?api_key=ad10ae57cef93e98482aabcf021a738a028c168b&q=SELECT+*+FROM+wbank.tz_secondary_cleaned_dashboard++ORDER+BY+rank_2014+ASC+LIMIT+100'
    $httpBackend.when('GET', url).respond({header1: 'value'}, {'data': 'xxx'});
    $httpBackend.expectGET url
    promise = WorldBankApi.getBestSchool level
    $httpBackend.flush()
    expect(!!promise).toBe true

  it 'should get the http getWorstSchool', ->
    level = 'primary'
    url = 'http://wbank.cartodb.com/api/v2/sql?api_key=ad10ae57cef93e98482aabcf021a738a028c168b&q=SELECT+*+FROM+wbank.tz_primary_cleaned_dashboard++ORDER+BY+rank_2014+DESC+LIMIT+100'
    $httpBackend.when('GET', url).respond({header1: 'value'}, {'data': 'xxx'});
    $httpBackend.expectGET url
    promise = WorldBankApi.getWorstSchool level
    $httpBackend.flush()
    expect(!!promise).toBe true

  it 'should get the http mostImprovedSchools', ->
    level = 'primary'
    url = 'http://wbank.cartodb.com/api/v2/sql?api_key=ad10ae57cef93e98482aabcf021a738a028c168b&q=SELECT+*+FROM+wbank.tz_primary_cleaned_dashboard+WHERE+change_13_14+IS+NOT+NULL+ORDER+BY+change_13_14+DESC+LIMIT+300'
    $httpBackend.when('GET', url).respond({header1: 'value'}, {'data': 'xxx'});
    $httpBackend.expectGET url
    promise = WorldBankApi.mostImprovedSchools level
    $httpBackend.flush()
    expect(!!promise).toBe true

  it 'should get the http leastImprovedSchools', ->
    level = 'primary'
    url = 'http://wbank.cartodb.com/api/v2/sql?api_key=ad10ae57cef93e98482aabcf021a738a028c168b&q=SELECT+*+FROM+wbank.tz_primary_cleaned_dashboard++ORDER+BY+change_13_14+ASC+LIMIT+100'
    $httpBackend.when('GET', url).respond({header1: 'value'}, {'data': 'xxx'});
    $httpBackend.expectGET url
    promise = WorldBankApi.leastImprovedSchools level
    $httpBackend.flush()
    expect(!!promise).toBe true


