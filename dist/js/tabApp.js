var app;

app = angular.module('tabApp', ['ui.router', 'ui.bootstrap', 'angular-underscore']);

app.run(function($rootScope, $state, $stateParams) {
  $rootScope.$state = $state;
  return $rootScope.$stateParams = $stateParams;
});

app.config(function($stateProvider, $urlRouterProvider) {
  $stateProvider.state('searches', {
    url: '/',
    templateUrl: '/templates/tabPage/searches.html',
    controller: 'searchesController'
  }).state('tree', {
    url: '/tree',
    templateUrl: '/templates/tabPage/tree.html',
    controller: 'treeController'
  }).state('graph', {
    url: '/graph',
    templateUrl: '/templates/tabPage/graph.html',
    controller: 'graphController'
  }).state('settings', {
    url: '/settings',
    templateUrl: '/templates/tabPage/settings.html',
    controller: function($scope, $state, $modal) {
      $scope.openDeleteModal = function() {
        var modalInstance;
        return modalInstance = $modal.open({
          templateUrl: 'deleteContent.html',
          size: 'sm',
          controller: 'removeModal'
        });
      };
      return $scope.settings = AppSettings;
    }
  });
  return $urlRouterProvider.otherwise('/');
});

app.controller('MainCtrl', function($scope, $rootScope, $state) {
  return $scope.getDomain = function(str) {
    var matches;
    matches = str.match(/^https?\:\/\/([^\/:?#]+)(?:[\/:?#]|$)/i);
    return matches && matches[1];
  };
});

app.controller('removeModal', function($scope, $modalInstance) {
  $scope.ok = function() {
    PageInfo.clearDB();
    SearchInfo.clearDB();
    return $modalInstance.close('cleared');
  };
  return $scope.cancel = function() {
    return $modalInstance.close('canceled');
  };

  /*
    if $cookies.state?
    $scope.$evalAsync (scope) ->
      $state.go($cookies.state)
   */
});

//# sourceMappingURL=tabApp.js.map
