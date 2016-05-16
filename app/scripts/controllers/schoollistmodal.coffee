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
      styles = "<style>body {font-family: \"Open Sans\", sans-serif;font-size: 14px;line-height: 1.42857143;} .full-size-scroll{height: 90%;} .modal-header{height: 10%;} .poor-perform {background: #f56053;} .best-perform {background: #49ab30;} .performance-header {border-radius: 2px; background-clip: padding-box; font-size: 13px; font-weight: bold; padding: 0 10px 5px 10px; line-height: 16px; color: #ffffff;} h3 {font-size: 24px;} .school-performance {width: 100%; background-color: transparent;border-spacing: 0;border-collapse: collapse;margin-top: 10px;} .school-performance th {line-height: 14px;margin-top: 5px;margin-bottom: 5px;} th {text-align: left;} .school-performance tr:nth-child(even) {background: #f0f0f0;} .school-performance td.passrategreen { color: #49ab30;font-weight: bold;padding-right: 3px;text-align: right;} .school-performance td.passratered { color: #f56053;font-weight: bold;padding-right: 3px;text-align: right;} .school-performance td.passrateyellow {color: #e9c941; font-weight: bold;text-align: right;} .btn {display: none;} .ng-hide {display: none;} </style>"
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


