'use strict'

###*
 # @ngdoc service
 # @name edudashApp.
 # @description
 # # 
 # Factory in the edudashApp.
###
angular.module('edudashAppLoading', [])
.config(($httpProvider) ->
    $("#spinner").hide();
    requestCounter = 0
    $httpProvider.defaults.transformRequest.push  (data, headersGetter) ->
      $("#spinner").show()
      requestCounter++
      data
    $httpProvider.defaults.transformResponse.push (data) ->
      if(requestCounter > 0)
        requestCounter--
      if(requestCounter == 0)
        $("#spinner").hide()
      data

)