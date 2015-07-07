app = angular.module('tabApp', ['ui.router', 'ui.bootstrap', 'angular-underscore', 'ngDexieBind', 'angular.filter'])

diff = (arr1, arr2) ->
  arr1.filter (i) ->
    arr2.filter({id: i.id}).length <= 0

app.config ($stateProvider, $urlRouterProvider) ->
  $stateProvider
    .state('searches', {
      url: '/'
      templateUrl: '/templates/popup/searches.html'
      controller: ($q, $scope, $state, $dexieBind, $rootScope) ->
        $scope.tasks = []
        $dexieBind.bind(db,db.Task.filter((val) -> val.hidden == false), $scope).then (data) ->
          $scope.tasks = data

        deferred = new $q.defer()
        $scope.curTask = deferred.promise
        chrome.tabs.queryAsync({active: true, currentWindow: true}).then (tab) ->
          Tab.findByTabId(tab[0].id)
        .then (tab) ->
          deferred.resolve(tab.task)
          
        $scope.taskSelect = (task) ->
          $rootScope.task = task
          $state.go('pages', {}, {location: false})
    }).state('pages', {
      url: '/pages'
      templateUrl: '/templates/popup/pages.html'
      controller: ($q, $scope, $state, $dexieBind, $rootScope) ->
        $scope.pageMap = {}
        $dexieBind.bind(db, db.PageVisit.where('task').equals($rootScope.task.id), $scope).then (data) ->
          $scope.visits = data
        $scope.$watchCollection 'visits', (newVisits, oldVisits) ->
          return if !(newVisits instanceof Array)
          newPages = _.chain(newVisits).map((val) -> val.page).uniq().difference(_.keys($scope.pageMap)).value()
          angular.forEach newPages, (page) ->
            $dexieBind.bind(db, db.Page.where('id').equals(page), $scope).then (data) ->
              $scope.pageMap[page] = data
    })
            
  $urlRouterProvider.otherwise('/')

###  
$scope.$watchCollection 'tasks', (newTasks, oldTasks) ->
  addedTasks = diff(newTasks, oldTasks)
  removedTasks = diff(oldTasks, newTasks)
  angular.forEach removedTasks, (task) ->
    $scope.watchListeners[task.id]()
    delete $scope.visitMap[task.id]
  angular.forEach addedTasks, (task) ->
    $scope.visitMap[task.id] = $dexieBind.bind(db, db.PageVisit.where('task').equals(task.id), $scope)
    $scope.watchListeners[task.id] = $scope.$watchCollection (($scope) -> $scope.visitMap[task.id]), (newVisits, oldVisits) ->
      addedVisits = diff(newVisits, oldVisits)
      removedVisits = diff(oldVisits, newVisits)
      angular.forEach addedTasks, (visit) ->
        pageMap[visit.page] = $dexieBind.bind(db, db.Page.where('id').equals(visit.page), $scope)
###
       



  
