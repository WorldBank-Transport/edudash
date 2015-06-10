'use strict'

###*
 # @ngdoc service
 # @name edudashApp.WorldBankApi
 # @description
 # # WorldBankApi
 # Service in the edudashApp.
###
angular.module 'edudashAppSrv'
  .service 'WorldBankApi', [
    '$http', '$resource', '$log'
    ($http, $resource, $log) ->
      wbApiRoot = 'http://wbank.cartodb.com/api/v2/sql'
      param1 = 'ad10ae57cef93e98482aabcf021a738a028c168b'
      primary = 'primary'
      secondary = 'secondary'

      mapLayers =
        'primary': 'http://worldbank.cartodb.com/api/v2/viz/a031f6f0-c1d0-11e4-966d-0e4fddd5de28/viz.json'
        'secondary': 'http://worldbank.cartodb.com/api/v2/viz/0d9008a8-c1d2-11e4-9470-0e4fddd5de28/viz.json'

      getSql = (educationLevel, condition, orderField, order, limit) ->
        condition ?= ''
        limit ?= '100'
        "SELECT * FROM wbank.tz_#{ educationLevel }_cleaned_dashboard #{condition} ORDER BY #{orderField} #{order} LIMIT #{limit}"

      getLayer: (educationLevel) ->
        mapLayers[educationLevel]

      getodata: () ->
        $params =
          q: 'SELECT * FROM wbank.tz_primary_cleaned_dashboard ORDER BY rank_2014 ASC LIMIT 100'
          api_key: param1
        $http.get(wbApiRoot, {params: $params})

      getBestSchool: (educationLevel) ->
        $params =
          q: getSql(educationLevel, undefined, 'rank_2014', 'ASC', undefined)
          api_key: param1
        $http.get(wbApiRoot, {params: $params})

      getWorstSchool: (educationLevel) ->
        $params =
          q: getSql(educationLevel, undefined, 'rank_2014', 'DESC', undefined)
          api_key: param1
        $http.get(wbApiRoot, {params: $params})

      mostImprovedSchools: (educationLevel) ->
        limit = ('300' if educationLevel is primary) or '100'
        $params =
          q: getSql(educationLevel, 'WHERE change_13_14 IS NOT NULL', 'change_13_14', 'DESC', limit)
          api_key: param1
        $http.get(wbApiRoot, {params: $params})

      leastImprovedSchools: (educationLevel) ->
        $params =
          q: getSql(educationLevel, undefined, 'change_13_14', 'ASC', undefined)
          api_key: param1
        $http.get(wbApiRoot, {params: $params})

      getSchoolRegionRank: (educationLevel, region, id) ->
        schoolRankSql = "SELECT pos FROM
                                    (SELECT cartodb_id, rank() OVER (PARTITION BY region ORDER BY rank_2014 ASC) AS pos
                                      FROM wbank.tz_#{ educationLevel}_cleaned_dashboard WHERE region = '#{region}') AS tmp
                                    WHERE cartodb_id = #{id}"
        $http.get(wbApiRoot, {params: { q: schoolRankSql, api_key: param1 }})

      getSchoolDistrictRank: (educationLevel, region, district, id) ->
        schoolRankSql = "SELECT pos FROM
                                    (SELECT cartodb_id, rank() OVER (PARTITION BY district ORDER BY rank_2014 ASC) AS pos
                                      FROM wbank.tz_#{ educationLevel}_cleaned_dashboard WHERE region = '#{region}' AND district = '#{district}') AS tmp
                                    WHERE cartodb_id = #{id}"
        $http.get(wbApiRoot, {params: { q: schoolRankSql, api_key: param1 }})

      getSchoolsChoices: (educationLevel, query) ->
        searchSQL = "SELECT * FROM wbank.tz_#{ educationLevel }_cleaned_dashboard WHERE (name ilike '%#{ query }%' OR code ilike '%#{ query }%') LIMIT 10"
        $http.get(wbApiRoot, {params: { q: searchSQL, api_key: param1 }})

      getSchooldByCartoDb: (educationLevel, cartodb_id) ->
        schoolSql = "SELECT * FROM wbank.tz_#{educationLevel}_cleaned_dashboard WHERE cartodb_id=#{cartodb_id}"
        $http.get(wbApiRoot, {params: { q: schoolSql, api_key: param1}})

      updateLayers: (layers, educationLevel, passRange) ->
        layers[1].getSubLayer(0).setSQL(
          "SELECT * FROM tz_#{educationLevel}_cleaned_dashboard WHERE (pass_2014 >= #{passRange.min} AND pass_2014 <= #{passRange.max})")
        layers[1].getSubLayer(1).setSQL(
          "SELECT * FROM tz_#{educationLevel}_cleaned_topworstperformance WHERE (pass_2014 >= #{passRange.min} AND pass_2014 <= #{passRange.max})")
        layers[1].getSubLayer(2).setSQL(
          "SELECT * FROM tz_#{educationLevel}_cleaned_topworstimproved WHERE (pass_2014 >= #{passRange.min} AND pass_2014 <= #{passRange.max})")

      updateLayersPt: (layers, educationLevel, passRange, ptRange) ->
        layers[1].getSubLayer(0).setSQL(
          "SELECT * FROM tz_#{ educationLevel }_cleaned_dashboard
                                      WHERE (pass_2014 >= #{passRange.min } AND pass_2014 <= #{passRange.max })
                                      AND (pt_ratio >= #{ ptRange.min } AND pt_ratio <= #{ ptRange.max })")
        layers[1].getSubLayer(1).setSQL(
          "SELECT * FROM tz_#{ educationLevel }_cleaned_topworstperformance
                                      WHERE (pass_2014 >= #{ passRange.min } AND pass_2014 <= #{ passRange.max })
                                      AND (pt_ratio >= #{ ptRange.min } AND pt_ratio <= #{ ptRange.max })")
        layers[1].getSubLayer(2).setSQL(
          "SELECT * FROM tz_#{ educationLevel }_cleaned_topworstimproved
                                      WHERE (pass_2014 >= #{ passRange.min } AND pass_2014 <= #{ passRange.max })
                                      AND (pt_ratio >= #{ ptRange.min } AND pt_ratio <= #{ ptRange.max })")

      getGlobalPassrate: (educationLevel, year) ->
        selectedYear = if year? then year else '2014'
        schoolSql = "SELECT AVG(pass_#{selectedYear}) FROM wbank.tz_#{educationLevel}_cleaned_dashboard"
        $http.get(wbApiRoot, {params: { q: schoolSql, api_key: param1}})

      getGlobalChange: (educationLevel) ->
        schoolSql = "SELECT AVG(change_12_13) FROM wbank.tz_#{educationLevel}_cleaned_dashboard"
        $http.get(wbApiRoot, {params: { q: schoolSql, api_key: param1}})

      getTopDistricts: (filters) ->
        metric = if filters.metric is 'avg_pass_rate' then 'avg_pass_1' else 'change_13_'
        table = if filters.educationLevel is 'primary' then 'wbank.districts_primary' else 'wbank.secondary_districts'
        schoolSql = "SELECT district_n as name, #{metric} as rate, the_geom as location FROM #{table} WHERE #{metric} IS NOT NULL ORDER BY #{metric} #{filters.order} LIMIT 5"
        $http.get(wbApiRoot, {params: { q: schoolSql, api_key: param1}})

      getPassOverTime: (filters) ->
        condition = if filters.query then " WHERE #{filters.query.field} ilike '%#{ filters.query.value }% " else ""
        sql = "SELECT AVG(pass_2012) as pass_2012, AVG(pass_2013) as pass_2013, AVG(pass_2014) as pass_2014 FROM tz_#{filters.educationLevel}_cleaned_dashboard #{condition}"
        $http.get(wbApiRoot, {params: { q: sql, api_key: param1}})

      getSchools: (educationLevel) ->
        sql = "SELECT * FROM tz_#{educationLevel}_cleaned_dashboard"
        $http.get(wbApiRoot, {params: { q: sql, api_key: param1}})

  ]
