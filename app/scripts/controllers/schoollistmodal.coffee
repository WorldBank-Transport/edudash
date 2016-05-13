'use strict'

###*
 # @ngdoc function
 # @name edudashApp.controller:SchoollistmodalCtrl
 # @description
 # # SchoollistmodalCtrl
 # Controller of the edudashApp
###
angular.module 'edudashAppCtrl'
  .controller 'SchoollistmodalCtrl', ($scope, $modalInstance, items, $q, shareSrv) ->
    $scope.printing = false
    $scope.items = $q (resolve, reject) ->
      if items?
        $scope.limit = items.total
        $scope.type = items.type
        $scope.school = items.school
        $scope.listType = items.listType
        resolve items.schoolList
      else
        reject "There are no school"

    $scope.cancel = () ->
      $modalInstance.dismiss('cancel');

    $scope.selectSchool = (code) ->
      $modalInstance.close(code);

    $scope.pdf = () ->
      $scope.printing = true
      modal = document.getElementsByClassName("modal-content")[0]
      documentHead = document.head.innerHTML.replace(/bower_components/g, "#{location.origin}\/bower_components").replace(/styles\//g, "#{location.origin}\/styles\/")
      styles = documentHead + "<style>.full-size-scroll {height: 100%;}</style>"
      htmlContent = "<html><head>#{styles}</head><body id=\"pdf-body\">#{modal.outerHTML}</body></html>";
      console.log(htmlContent)
      shareSrv.pdfExport(htmlContent).then (file) ->
        $scope.printing = false
        a = document.createElement('a');
        document.body.appendChild(a);
        a.style = 'display: none';
        url = window.URL.createObjectURL(file);
        a.href = url;
        a.download = 'dashboard.pdf';
        a.click();
        window.URL.revokeObjectURL(url);


