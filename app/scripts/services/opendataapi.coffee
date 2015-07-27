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
    '$http', '$resource', '$log', 'CsvParser', '$location', '$q'
    ($http, $resource, $log, CsvParser, $location, $q) ->
      # AngularJS will instantiate a singleton by calling "new" on this function
      regexp = /.*localhost.*/ig
      corsApi = if regexp.test($location.host()) then 'https://cors-anywhere.herokuapp.com' else 'http:/'
      apiRoot = '/data.takwimu.org/api/action/'
#      apiRoot = '/tsd.dgstg.org/api/action/'
      ckanQueryURL = corsApi + apiRoot + 'datastore_search_sql'
      datasetMapping =
        primary:
          'performance': '3a77adf7-925a-4a62-8c70-5e43f022b874'
          'improvement': 'bba2cbbb-97fb-48b1-aa51-8db69279fbc5'
        secondary: '743e5062-54ae-4c96-a826-16151b6f636b'

      converters =
        text: (t) -> t
        numeric: (n) -> +n

      ckanResp = (httpPromise) ->
        $q (resolve, reject) ->
          parse = (resp) ->
            if resp.data.success
              convertMap = resp.data.result.fields.reduce ((m, c) ->
                unless converters[c.type]?
                  reject "Unknown data type: '#{c.type}'"
                m[c.id] = converters[c.type] or converters.text
                m
              ), {}
              resolve resp.data.result.records.map (raw) ->
                conv = {}
                for key, val of raw
                  conv[key] = convertMap[key] val
                conv
            else
              reject data
          httpPromise.then parse, reject

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

      getTable = (educationLevel, subtype) ->
        if(subtype?)
          datasetMapping[educationLevel][subtype]
        else
          datasetMapping[educationLevel]

      getSql = (educationLevel, subtype, condition, sorted, limit, fields) ->
        strField = if fields? and fields.length > 0 then '"' + fields.join('","') + '"' else "*"
        table = getTable(educationLevel, subtype)
        sorted = if sorted? then "ORDER BY #{sorted}" else ''
        strLimit = if limit? then "LIMIT #{limit}" else ""
        "SELECT #{strField} FROM \"#{table}\" #{condition} #{sorted} #{strLimit}";

      getConditions = (educationLevel, moreThan40, year) ->
        condition = []
        if educationLevel == 'secondary' and moreThan40?
          condition.push "\"MORE_THAN_40\" = '#{if moreThan40 then 'YES' else 'NO'}'"
        if year
          condition.push '"YEAR_OF_RESULT" = ' + year
        if condition.length > 0 then "WHERE #{condition.join ' AND '}" else ""

      getChangeConditions = (educationLevel, moreThan40, year) ->
        condition = []
        if(educationLevel == 'secondary' and moreThan40?)
          condition.push "\"MORE_THAN_40\" = '#{moreThan40}'"
        if(year)
          condition.push "\"YEAR_OF_RESULT\" IN (#{year - 1}, #{year})"
        if condition.length > 0 then "WHERE #{condition.join ' AND '}" else ""

      datasetByQuery: (query) ->
        $params =
          sql: query
        req = $resource(corsApi + apiRoot + 'datastore_search_sql')
        req.get($params).$promise

      getSchools: ({year, schoolType, moreThan40, subtype}) ->
        ckanResp $http.get ckanQueryURL, params: sql: "
          SELECT
            \"CODE\" as id,
            \"NAME\" as name,
            \"LATITUDE\" as latitude,
            \"LONGITUDE\" as longitude,
            \"REGION\" as region,
            \"DISTRICT\" as district,
            \"WARD\" as ward,
            \"PASS_RATE\" as passrate,
            \"RANK\" as rank,
            \"CHANGE_PREVIOUS_YEAR\" as change
          FROM \"#{getTable schoolType, subtype}\"
          #{getConditions schoolType, moreThan40, year}"

      getBestSchool: (educationLevel, subtype, moreThan40, year) ->
        $params =
          sql: getSql(educationLevel, subtype, getConditions(educationLevel, moreThan40, year), '"RANK" ASC', "20")
        $http.get(ckanQueryURL, {params: $params})

      getWorstSchool: (educationLevel, subtype, moreThan40, year) ->
        $params =
          sql: getSql(educationLevel, subtype, getConditions(educationLevel, moreThan40, year), '"RANK" DESC', "20")
        $http.get(ckanQueryURL, {params: $params})

      mostImprovedSchools: (educationLevel, subtype, moreThan40, year) ->
        $params =
          sql: getSql(educationLevel, subtype, getConditions(educationLevel, moreThan40, year), '"CHANGE_PREVIOUS_YEAR" DESC', "20")
        $http.get(ckanQueryURL, {params: $params})

      leastImprovedSchools: (educationLevel, subtype, moreThan40, year) ->
        $params =
          sql: getSql(educationLevel, subtype, getConditions(educationLevel, moreThan40, year), '"CHANGE_PREVIOUS_YEAR" ASC', "20")
        $http.get(ckanQueryURL, {params: $params})

      getGlobalPassrate: (educationLevel, subtype, moreThan40, year) ->
        $params =
          sql: "SELECT AVG(\"PASS_RATE\") FROM \"#{getTable(educationLevel, subtype)}\" #{getConditions(educationLevel, moreThan40, year)}"
        $http.get(ckanQueryURL, {params: $params})

      getGlobalChange: (educationLevel, subtype, moreThan40, year) ->
        sql = "SELECT AVG(\"PASS_RATE\"), \"YEAR_OF_RESULT\" FROM \"#{getTable(educationLevel, subtype)}\" #{getChangeConditions(educationLevel, moreThan40, year)} GROUP BY \"YEAR_OF_RESULT\" ORDER BY \"YEAR_OF_RESULT\""
        $params =
          sql: sql
        $http.get(ckanQueryURL, {params: $params})

      search: (educationLevel, subtype, query, year) ->
        ckanResp $http.get ckanQueryURL, params: sql: "
          SELECT \"CODE\" as id
          FROM \"#{getTable(educationLevel, subtype)}\"
          WHERE
              (\"NAME\" ILIKE '%#{query}%'
                OR \"CODE\" ILIKE '%#{query}%')
            AND \"YEAR_OF_RESULT\" = #{year}
          LIMIT 10"

      getTopDistricts: (filters) ->
        # TODO implement me

      getRank: (selectedSchool, year) ->
        query = "SELECT _id,
                  \"REGIONAL_RANK_ALL\",
                  \"NATIONAL_RANK_ALL\",
                  \"DISTRICT_RANK_ALL\",
                  (SELECT COUNT(*) FROM \"743e5062-54ae-4c96-a826-16151b6f636b\" WHERE \"REGION\" = '#{selectedSchool.REGION}') as REGIONAL_SCHOOLS,
                  (SELECT COUNT(*) FROM \"743e5062-54ae-4c96-a826-16151b6f636b\" WHERE \"DISTRICT\" = '#{selectedSchool.DISTRICT}') as DISTRICT_SCHOOLS
                  FROM \"743e5062-54ae-4c96-a826-16151b6f636b\" WHERE _id = #{selectedSchool._id} AND \"YEAR_OF_RESULT\" = #{year}"
        $params =
          sql: query
        $http.get(ckanQueryURL, {params: $params})

      getPassOverTime: (educationLevel, subtype, moreThan40) ->
        condition = if(educationLevel == 'secondary' and moreThan40?) then "WHERE \"MORE_THAN_40\" = '#{moreThan40}'" else ''
        $params =
          sql: "SELECT AVG(\"PASS_RATE\"), \"YEAR_OF_RESULT\" FROM \"#{getTable(educationLevel, subtype)}\" #{condition} GROUP BY \"YEAR_OF_RESULT\" ORDER BY \"YEAR_OF_RESULT\" ASC"
        $http.get(ckanQueryURL, {params: $params})

      getSchoolPassOverTime: (educationLevel, subtype, code) ->
        $params =
          sql: "SELECT \"PASS_RATE\", \"YEAR_OF_RESULT\" FROM \"#{getTable(educationLevel, subtype)}\" WHERE \"CODE\" like '#{code}' ORDER BY \"YEAR_OF_RESULT\" ASC"
        $http.get(ckanQueryURL, {params: $params})

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

  ]
