app.controller 'searchesController', ($scope, $state, $http, $dexieBind) ->
  $scope.tasks = []
  $dexieBind.bind(db,db.Task.filter((val) -> val.hidden == false), $scope).then (data) ->
    $scope.tasks = tasks
    
  $scope.$watchCollection 'tasks', (newTasks, oldTasks) ->
    $scope.built = []
    angular.forEach newTasks, (task) ->
      $dexieBind.bind(db, db.PageVisit.where('task').equals(task.id), $scope).then (visits) ->
        built = angular.copy(task)
        built.pageVisits = visits