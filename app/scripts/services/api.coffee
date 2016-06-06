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
      ckanQueryURL = '//datahub.tehamalab.com/api/action/datastore_search_sql'
      SHARE_API = '//api.takwimu.org/share'
      PDF_EXPORT_API = '//api.takwimu.org/pdf'
      # PDF_EXPORT_API = '//localhost:9080/pdf'
      datasetMapping =
        primary:
          'performance': 'b8777069-a7ed-4d69-9108-630ae328b2c9'
          'improvement': '3845948d-ba01-40a6-9296-400f88dc5a88'
        secondary: '2e7479a6-8c5c-4ddd-93d9-ae9aade30659'

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
        int8: (n) -> +n

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
            \"PUPIL_TEACHER_RATIO\",
            \"LOCATION_IS_APPROXIMATE\"
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
        condition = switch educationLevel
          when 'secondary' then "WHERE \"MORE_THAN_40\" = '#{if moreThan40 then 'YES' else 'NO'}'"
          else ''
        ckanResp xget ckanQueryURL, params: sql: "
          SELECT
            AVG(\"PASS_RATE\") as average_pass_rate,
            \"YEAR_OF_RESULT\"
          FROM \"#{getTable(educationLevel, subtype)}\"
          #{condition}
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

      getLocationCountByGroup: (educationLevel, group, year) ->
        ckanResp xget ckanQueryURL, params: sql: "
          SELECT \"#{group}\",\"LOCATION_IS_APPROXIMATE\",COUNT(*)
          FROM \"#{getTable(educationLevel, 'performance')}\"
          WHERE \"YEAR_OF_RESULT\" = #{year}
          GROUP BY \"#{group}\",\"LOCATION_IS_APPROXIMATE\" ORDER BY \"#{group}\""

      getSchoolsCountByGroup: (educationLevel, group, year) ->
        ckanResp xget ckanQueryURL, params: sql: "
          SELECT \"#{group}\",COUNT(*)
          FROM \"#{getTable(educationLevel, 'performance')}\"
          WHERE \"YEAR_OF_RESULT\" = #{year}
          GROUP BY \"#{group}\""

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

      postShare: (shareData) =>
        $http.post SHARE_API, shareData

      getShare: (shareId) =>
        xget SHARE_API, params: id: shareId

      postHtml2Pdf: (html) =>
        $http.post PDF_EXPORT_API, {content: html}, {responseType: 'blob'}
