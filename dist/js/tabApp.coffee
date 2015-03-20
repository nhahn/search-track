app = angular.module('tabApp', ['ui.router', 'ui.bootstrap', 'angular-underscore'])

app.run ($rootScope, $state, $stateParams) ->
  $rootScope.$state = $state
  $rootScope.$stateParams = $stateParams

app.config ($stateProvider, $urlRouterProvider) ->

  $stateProvider
    .state('searches', {
      url: '/'
      templateUrl: '/templates/tabPage/searches.html'
      controller: 'searchesController'       
    })
    .state('tree', {
      url: '/tree'
      templateUrl: '/templates/tabPage/tree.html'
      controller: 'treeController'
    })
    .state('graph', {
      url: '/graph'
      templateUrl: '/templates/tabPage/graph.html'
      controller: 'graphController'
    })
    .state('settings', {
      url: '/settings'
      templateUrl: '/templates/tabPage/settings.html'
      controller: ($scope, $state, $modal) ->
        $scope.openDeleteModal = () ->
          modalInstance = $modal.open {
            templateUrl: 'deleteContent.html',
            size: 'sm',
            controller: 'removeModal'
          }
        
      })

  $urlRouterProvider.otherwise('/')

app.controller 'MainCtrl', ($scope, $rootScope, $state) ->
  $scope.getDomain = (str) ->
    matches = str.match(/^https?\:\/\/([^\/:?#]+)(?:[\/:?#]|$)/i)
    return matches && matches[1]

  
app.controller 'removeModal', ($scope, $modalInstance) ->
  
  $scope.ok = () ->
    PageInfo.clearDB()
    SearchInfo.clearDB()
    $modalInstance.close('cleared')
    
  $scope.cancel = () ->
    $modalInstance.close('canceled')
  ###
    if $cookies.state?
    $scope.$evalAsync (scope) ->
      $state.go($cookies.state)
  ###

  
