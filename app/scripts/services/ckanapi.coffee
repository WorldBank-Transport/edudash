'use strict'

###*
 # @ngdoc service
 # @name edudashApp.CKanApi
 # @description
 # # CKanApi
 # Service in the edudashApp.
###
angular.module 'edudashApp'
.service 'CKanApi', [
    '$http', '$resource', '$log'
    ($http, $resource, $log) ->
      # AngularJS will instantiate a singleton by calling "new" on this function
      corsApi = 'https://cors-anywhere.herokuapp.com'
      apiRoot = '/opendata.go.tz/api/action/'
      oapiRoot = 'http://wbank.cartodb.com/api/v2/sql'
      oapiKey = 'ad10ae57cef93e98482aabcf021a738a028c168b'

      getdata: () ->
        $params =
          resource_id: '3221ccb4-3b75-4137-a8bd-471a436ed7a5'
        req = $resource(corsApi + apiRoot + 'datastore_search')
        req.get($params).$promise

      getDataset: (id) ->
        $params =
          resource_id: id
        req = $resource(corsApi + apiRoot + 'datastore_search')
        req.get($params).$promise

      getDatasetType: (level) ->
        $params =
          id: level
        req = $resource(corsApi + apiRoot + 'package_show')
        req.get($params).$promise

      getodata: () ->
        $params =
          q: 'SELECT * FROM wbank.tz_primary_cleaned_dashboard ORDER BY rank_2014 ASC LIMIT 100'
          api_key: oapiKey
        $http.get(oapiRoot, {params: $params})

      getCsvValue: () ->
        resourceUrl = corsApi + '/opendata.go.tz/sw/dataset/12777377-33b6-463c-8055-91245d033c49/resource/82090966-ca83-433c-a535-167fc13225ac/download/Enrollment-of-Students-in-Secondary-Schools-by-School-2012.csv'
        req = $resource(resourceUrl)
        req.get().$promise

      getMyData: () ->
        [
          '1- HTML5 Boilerplate'
          '2- AngularJS'
          '3- Karma'
        ]
  ]
