app = angular.module('tabApp', ['ui.bootstrap', 'angular-underscore', 'ngDexieBind', 'angular.filter'])

diff = (arr1, arr2) ->
  arr1.filter (i) ->
    arr2.filter({id: i.id}).length <= 0

app.controller 'MainCtrl', ($scope, $rootScope, $dexieBind) ->
  $scope.tasks = []
  $scope.visitMap = {}
  $scope.watchListeners = {}
  $scope.pageMap = {}
  $scope.tasks = $dexieBind.bind(db,db.Task.filter((val) -> val.hidden == false), $scope)
    
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
          $pageMap[visit.page] = $dexieBind.bind(db, db.Page.where('id').equals(visit.page), $scope)
       



  
