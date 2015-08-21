'use strict'

###*
 # @ngdoc directive
 # @name edudashApp.directive:schoolList
 # @description
 # # schoolList
###
angular.module 'edudashApp'
  .directive 'schoolList', (loadingSrv, bracketsSrv, $modal, $log) ->
    restrict: 'E'
    templateUrl: 'views/schoollist.html'
    scope:
      listTitle: '@listTitle'
      listType: '@type'
      dataset: '=dataset'
      click: '=click'
      hover: '=hover'
      unHover: '=unHover'
      property: '@property'
      modalLimit: '@modallimit'
      rankby: '=rankby'
      showHeader: '@showheader'
      columns: '=columns'
      school: '=school'
      limit: '=limit'
      sufix: '@sufix'
    link: (scope, el, attrs) ->
      scope.schools = null
      scope.$watch 'dataset', (p) ->
        if p?
          p.then (schools) ->
            scope.allSchools = schools
            scope.schools = schools.slice 0, scope.limit
          loadingSrv.containerLoad p, el[0]
        else
          scope.schools = null

      scope.getStyle = (val, prop) ->
        switch bracketsSrv.getBracket val, prop
          when 'GOOD' then 'passrategreen'
          when 'MEDIUM' then 'passrateyellow'
          when 'POOR' then 'passratered'
          when 'UNKNOWN' then 'passrateunknow'
          else throw new Error "Unknown bracket: '#{brace}'"

      scope.showModal = () ->
        modalInstance = $modal.open
          animation: true,
          templateUrl: 'views/schoollistmodal.html',
          controller: 'SchoollistmodalCtrl',
          size: 'lg',
          resolve:
            items: () ->
              schoolList: scope.allSchools
              total: scope.modalLimit
              type: scope.rankby
              school: scope.school
        modalInstance.result.then (selectedItem) ->
          scope.click(selectedItem)
        , () ->
          $log.info('Modal dismissed at: ' + new Date())
        loadingSrv.containerLoad modalInstance.opened, el.parents('.map-widget')[0]
