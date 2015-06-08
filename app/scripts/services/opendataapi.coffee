'use strict'

###*
 # @ngdoc service
 # @name edudashApp.OpenDataApi
 # @description
 # # OpenDataApi
 # Service in the edudashApp.
###
angular.module 'edudashAppSrv'
.service 'OpenDataApi', [
    '$http', '$resource', '$log', 'CsvParser'
    ($http, $resource, $log, CsvParser) ->
      # AngularJS will instantiate a singleton by calling "new" on this function
      corsApi = 'https://cors-anywhere.herokuapp.com'
      apiRoot = '/tsd.dgstg.org/api/action/'
      datasetMapping =
        primary:
          'enrolment_district': ''
          'enrolment_region': ''
          'teacher_district': ''
          'teacher_region': ''
          'ranking_district_region_2012': ''
          'PSLE-ranking_district_region_2013': ''
          'std-seven-national-examination_region_2011': ''
          'droppedout_region': ''
          'schools_region_2012': ''
          'desks_region': ''
          'textbook_region': ''
          'pupils-with-disabilities_region': ''
          'pitlatrine_region_district': ''
          'droppedout_district': ''
          'textbook_district': ''
          'gross-net-enrolment-ratio_ger-ner_2012': ''
        secondary:
          'enrolment_region_districts_2013': ''
          'teacher_region_districts_2012': ''
          'ranking_less40_2012': 'CSEE-2012-SCHOOL-RANKING---CENTRES-WITH-LESS-THAN-40-CANDIDATES.csv'
          'ranking_more40_2012': 'CSEE-2012-SCHOOL-RANKING---CENTRE-WITH-40-AND-MORE-CANDIDATES.csv'
          'ranking_less40_2013': 'CSEE-2013-SCHOOL-RANKING---CENTRE-WITH-LESS-THAN-40-CANDIDATES.csv'
          'droppedout_2012': 'Dropout-of-Students-in-Secondary-Schools-by-School--2012.csv'
          'pitlatrine_2013': 'Number-of-Pitratrine-in-Secondary-Schools-by-School-2013.csv'
          'advance-student_2012': 'Number-of-Advanced-Secondary-Students-year-2012.csv'
          'advance-student_2013': 'Number-of-Advanced-Secondary-Students-by-school-year-2013.csv'
          'pupils-with-disabilities_region_2012': 'Number-of-Pupils-with-Disabilities-in-Secondary-Schools-by-Region-2012.csv'
          'pupils-with-disabilities_region_2013': 'Number-of-Pupils-with-Disabilities-in-Secondary-Schools-by-region-2013.csv'

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

      dataserByQuery: (query) ->
        $params =
          sql: query
        req = $resource(corsApi + apiRoot + 'datastore_search_sql')
        req.get($params).$promise

      getDatasetType: (level) ->
        $params =
          id: level
        req = $resource(corsApi + apiRoot + 'package_show')
        req.get($params).$promise

      getCsv: (file) ->
        file = file.replace(/^(http|https):\/\//gm, '')
        resourceUrl = corsApi + '/' + file
        $resource(resourceUrl, {},
          getDataSet: {
            method: 'GET'
            isArray: false
            headers:
              'Content-Type': 'text/csv; charset=utf-8'
            responseType: 'text'
            transformResponse: (data, headers) ->
              #$log.debug 'csv raw data'
              result = CsvParser.parseToJson data
              #$log.debug result
              result
          }
        )

#        .success (data, status) ->
#          $log.debug 'csv raw data' + status
#          $log.debug CsvParser.parseToJson data
#        req = $resource(resourceUrl)
#        req.get().$promise

      saveData: () ->
        data =
          resource_id: 'eaa77110-a1cf-4eb6-ae1c-ef89c4f1e80e'
          force: true
          method: 'insert'
          records: [
            code:"S5183"
            name:"NYABUMHANDA SECONDARY SCHOOL"
            region:"Mwanza"
            clean_candidates_2014:22
            passed_candidates_2014:8
            pass_2014:36
            rank_2014:1892
            more_than_40:0
            code_2013:""
            clean_candidates_2013:null
            passed_candidates_2013:null
            pass_2013:null
            change_13_14:null
            rank_2013:null
            clean_candidates_2012:null
            passed_candidates_2012:null
            pass_2012:null
            change_12_13:null
            rank_2012:null
            more_than_40_2013:null
            ownership:""
            ward:""
            enrolled:""
            teaching_staff:null
            pt_ratio:null
            non_teaching_staff_employed_by_school:""
            non_teaching_staff_employed_by_government:""
            district:""
            longitude:32.9
            latitude:-2.51667
            location_is_ward:0
            location_is_geocoder:1
            loaction_is_district:0
            location_is_approximate:1
            cartodb_id:4407
            created_at:"2015-04-06T19:08:09Z"
            updated_at:"2015-04-06T19:08:09Z"
          ]
        req = $resource(corsApi + apiRoot + 'datastore_upsert', {},
                  save: {
                    method: 'POST'
                    isArray: false
                    headers: 'Authorization': '1495642d-ee14-401b-be64-19f7dfd7b23c'
                  }
        )

        response = req.save(data)


      getMyData: () ->
        [
          '1- HTML5 Boilerplate'
          '2- AngularJS'
          '3- Karma'
        ]
  ]
