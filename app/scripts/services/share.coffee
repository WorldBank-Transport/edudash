'use strict'

###*
 # @ngdoc service
 # @name edudashApp.share
 # @description
 # # Share functionality to get and set the scope variables
###


angular.module('edudashAppSrv').factory 'shareSrv',
  (api, $q) ->
    isShare = false
    data = null

    get: (id) ->
      $q (resolve, reject) ->
        api.getShare(id).then (response) ->
          if (response.status is 200 and response.data.code is 200)
            isShare = true
            data = response.data.object
            resolve "/dashboard/#{response.data.object.schoolType}"
          else
            reject response.status

    saveShare: ($scope, map) ->
      $q (resolve, reject) ->
        bounds = map.getBounds();
        shareData = 
          bounds: [[bounds.getNorthEast().lat, bounds.getNorthEast().lng], [bounds.getSouthWest().lat, bounds.getSouthWest().lng]]
          year: $scope.year
          viewMode: $scope.viewMode
          visMetric: $scope.visMetric
          visMode: $scope.visMode
          schoolType: $scope.schoolType
          moreThan40: $scope.moreThan40
          rankBy: $scope.rankBy
          range: $scope.range
          selectedSchoolCode: $scope.selectedSchoolCode
          selectedPolyId: $scope.selectedPolyId
          polyType: $scope.polyType

        api.postShare(shareData).then (response) ->
          if (response.status is 200 and response.data.code is 200)
            resolve "#{window.location.origin}/#/share/#{response.data.object.shareId}/"
          else
            reject response.status

    getShareData: () -> if isShare then data else throw Error('Share is not found')

    isShare: () -> isShare
