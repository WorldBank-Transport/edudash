'use strict'

###*
 # @ngdoc service
 # @name edudashApp.MetricsSrv
 # @description
 # # MetricsSrv
 # Service in the edudashApp.
###
angular.module 'edudashAppSrv'
.service 'MetricsSrv', [
    'OpenDataApi', '$log', 'CsvParser', '$q',
    (OpenDataApi, $log, CsvParser, $q) ->
      getPassRate: (filter) ->
        year = if filter? && filter.year? then filter.year else 2012
        datasetName = ''

      getPupilTeacherRatio: (filter) ->
        level = filter.level

        if(level == 'secondary')
          sqlEnrolment = 'SELECT sum("Grand Total") from "1da40512-19d0-4baf-bac8-3764141b632a"'
          sqlTeacher = 'SELECT sum("Total") from "71b854a1-6038-4da0-9be0-8ab723dff1b7"'
        else
          sqlEnrolment = 'SELECT sum("Total") from "43342fa9-6050-4b04-a2ed-1601eee6dbb3"'
          sqlTeacher = 'SELECT sum("Total") from "70d7f660-e188-4602-923d-d93d306936f0"'

        $q.all([
          OpenDataApi.dataserByQuery(sqlEnrolment),
          OpenDataApi.dataserByQuery(sqlTeacher)
        ])
        .then((values) ->
            data =
              enrolments: values[0].result.records[0].sum
              teachers: values[1].result.records[0].sum
              rate: values[0].result.records[0].sum / values[1].result.records[0].sum
            console.log data
            data
          )

  ]