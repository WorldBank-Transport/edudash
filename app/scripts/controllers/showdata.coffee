'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:ShowdataCtrl
 # @description
 # # ShowdataCtrl
 # Controller of the edudashApp
###
angular.module 'edudashApp'
.controller 'ShowdataCtrl', [
    '$scope', '$log', 'CKanApi'
    ($scope, $log, CKanApi) ->

      simpleCSV = 'http://opendata.go.tz/sw/dataset/3de642ad-fac1-46d8-a95b-e4a10be184db/resource/3221ccb4-3b75-4137-a8bd-471a436ed7a5/download/Enrolment-by-Regions.csv'
      CKanApi.getCsv(simpleCSV).getDataSet (data) ->
        #$log.debug data.result.records
        $scope.opendata = data.result.records
        $scope.opendatafield = data.result.fields

      CKanApi.getodata().success (data) ->
        $scope.mydata = data.rows

      $scope.educationValues = [
        {value: 'elimu-ya-awali', label: 'Pre-Primary Education'},
        {value: 'elimu-ya-msingi', label: 'Primary'},
        {value: 'elimu-ya-sekondari', label: 'Secondary'},
        {value: 'elimu-ya-watu-wazima-na-elimu-nje-ya-mfumo-rasmi', label: 'Adult and Non-Formal Education'}
      ]
      $scope.sumUp =
        total: 25

      $scope.education = 'elimu-ya-msingi'

      CKanApi.getDatasetType($scope.education).then (data) ->
        $scope.datasetValues = data.result.resources

#      CKanApi.getCsv('http://opendata.go.tz/sw/dataset/3de642ad-fac1-46d8-a95b-e4a10be184db/resource/3221ccb4-3b75-4137-a8bd-471a436ed7a5/download/Enrolment-by-Regions.csv').getDataSet (data) ->
#        $log.debug data

      $scope.selectEducation = () ->
        $log.debug $scope.education
        CKanApi.getDatasetType($scope.education).then((data) ->
          $log.debug data.result
          $scope.datasetValues = data.result.resources
        )

      $scope.selectDataset = () ->
        $log.debug $scope.dataset
        CKanApi.getCsv($scope.dataset).getDataSet (data) ->
          $log.debug data.result
          $scope.opendatafield = data.result.fields
          $scope.opendata = data.result.records

      $scope.awesomeThings = [
        'HTML5 Boilerplate'
        'AngularJS'
        'Karma'
      ]
  ]