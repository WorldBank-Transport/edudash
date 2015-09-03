'use strict'

###*
 # @ngdoc service
 # @name edudashApp.
 # @description
 # # 
 # Factory in the edudashApp.
###
angular.module('edudashAppSrv').factory 'loadingSrv', ($log) ->
  containerLoad: (promise, container) ->
    loader = ($ '<div class="loading ajax-loader"></div>')[0]
    container.appendChild loader
    promise
      .then -> container.removeChild loader
      .catch (err) ->
        loader.remove()
        container.appendChild ($ '<div class="loading ajax-failed">Failed to load</div>')[0]
        $log.error err
