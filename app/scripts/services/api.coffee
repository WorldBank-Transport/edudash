'use strict'

###*
 # @ngdoc service
 # @name edudashApp.api
 # @description
 # # api
 # Service in the edudashApp.
###
angular.module 'edudashAppSrv'
  .service 'api',
    ($http, $log, $location, $q, $window, topojson) ->
      ckanQueryURL = '//data.takwimu.org/api/action/datastore_search_sql'
      datasetMapping =
        primary:
          'performance': '59f06138-4ac9-454e-9c26-a1641c897279'
          'improvement': 'd1b88ec0-236b-462c-b663-1d24bba7c4d4'
        secondary: 'd57dfd49-a0b8-4aaa-a3b6-86738c2b8164'

      xget = switch
        when $window.OLDIE? then (url, opts, otherArgs...) ->
          unless opts.params?
            opts.params = {}
          if opts.params.callback?
            $log.warn "Overriding request `callback` param (#{opts.params.callback}) for JSONP for #{url}"
          opts.params.callback = 'JSON_CALLBACK'
          $http.jsonp url, opts, otherArgs...
        else $http.get

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

      getTable = (educationLevel, subtype) ->
        if(subtype? and educationLevel is 'primary')
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

      getStaticData = (url) ->
        $q (resolve, reject) -> ($http.get url).then ((resp) -> resolve resp.data), reject

      getSchools: (year, schoolType, moreThan40, subtype) ->
        extraFields = if schoolType is 'secondary' then ",\"AVG_GPA\", \"CHANGE_PREVIOUS_YEAR_GPA\" " else ",\"AVG_MARK\"" # TODO add CHANGE_PREVIOUS_YEAR_MARK
        dataP = ckanResp xget ckanQueryURL, params: sql: "
          SELECT
            \"CHANGE_PREVIOUS_YEAR\",
            \"CODE\",
            \"DISTRICT\",
            \"LATITUDE\",
            \"LONGITUDE\",
            \"NAME\",
            \"OWNERSHIP\",
            \"PASS_RATE\",
            \"RANK\",
            \"REGION\",
            \"WARD\",
            \"PUPIL_TEACHER_RATIO\"
            #{extraFields}
            FROM \"#{getTable schoolType, subtype}\"
          #{getConditions schoolType, moreThan40, year}"
        dataP.then (data) -> $q.when data.map (d) ->
          # Fix wrong datatype "text" for numeric CHANGE_PREVIOUS_YEAR_GPA and PUPIL_TEACHER_RATIO in CKAN
          if schoolType == 'secondary'
            d.CHANGE_PREVIOUS_YEAR_GPA = parseFloat d.CHANGE_PREVIOUS_YEAR_GPA
          d.PUPIL_TEACHER_RATIO = parseFloat d.PUPIL_TEACHER_RATIO
          d
        dataP

      getYearAggregates: (educationLevel, subtype, moreThan40, year) ->
        ckanResp xget ckanQueryURL, params: sql: "
          SELECT
            AVG(\"PASS_RATE\") as average_pass_rate,
            \"YEAR_OF_RESULT\"
          FROM \"#{getTable(educationLevel, subtype)}\"
          GROUP BY \"YEAR_OF_RESULT\"
          ORDER BY \"YEAR_OF_RESULT\""

      search: (educationLevel, subtype, query, year) ->
        ckanResp xget ckanQueryURL, params: sql: "
          SELECT \"CODE\"
          FROM \"#{getTable(educationLevel, subtype)}\"
          WHERE
              (\"NAME\" ILIKE '%#{query}%'
                OR \"CODE\" ILIKE '%#{query}%')
            AND \"YEAR_OF_RESULT\" = #{year}
          ORDER BY
            CASE
              WHEN \"NAME\" ILIKE '#{query}%' THEN 1
              WHEN \"CODE\" ILIKE '#{query}%' THEN 2
              ELSE 3
            END
          LIMIT 10"

      getYears: (educationLevel, subtype) ->
        ckanResp xget ckanQueryURL, params: sql: "
          SELECT DISTINCT \"YEAR_OF_RESULT\"
          FROM \"#{getTable(educationLevel, subtype)}\"
          ORDER BY \"YEAR_OF_RESULT\""

      getSchoolAggregates: (educationLevel, subtype, code) ->
        ckanResp xget ckanQueryURL, params: sql: "
          SELECT
            \"PASS_RATE\",
            \"YEAR_OF_RESULT\"
          FROM \"#{getTable(educationLevel, subtype)}\"
          WHERE \"CODE\" = '#{code}'
          ORDER BY \"YEAR_OF_RESULT\" ASC"

      getRegions: ->
        getStaticData '/layers/tz_regions.json'
          .then (topo) ->
            {features} = topojson.feature topo, topo.objects.tz_Regions
            $q.when features.map (feature) ->
              type: feature.type
              id: feature.properties.name.toUpperCase()
              geometry: feature.geometry

      getDistricts: ->
        getStaticData '/layers/tz_districts.json'
          .then (topo) ->
            {features} = topojson.feature topo, topo.objects.tz_districts
            $q.when features.map (feature) ->
              type: feature.type
              id: feature.properties.name.toUpperCase()
              geometry: feature.geometry
