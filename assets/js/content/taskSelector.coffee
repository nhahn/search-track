listApp = angular.module 'listApp', ['ngDraggable', 'ngDexieBind']

listApp.controller 'RootCtrl', ($scope, $dexieBind) ->
  $scope.tasks = []
  $dexieBind.bind(db,db.Task.filter((val) -> val.hidden == false), $scope).then (data) ->
    $scope.tasks = data
  
  chrome.runtime.sendMessage { getCurrentTab: true }, (msg) ->
    
    $dexieBind.bind(db, db.Tab.where('tab').equals(msg[0].id).and((val) -> val.status is 'active'), $scope).then (tab) ->
      $scope.tab = tab
      return $scope.tab.$join(db.Task, 'task', 'id')
    .then (tasks) ->
      $scope.curTask = tasks

  
  $scope.createTask = () ->
    task = new Task({name: $scope.newTask})
    task.save().then (task) ->
      $scope.taskSelect(task)
    $scope.newTask = ''
  
  $scope.taskSelect = (task) ->
    db.Tab.update($scope.tab[0].id, {task: task.id})
    db.PageVisit.update($scope.tab[0].pageVisit, {task: task.id})
  
  $scope.close = () ->
    chrome.runtime.sendMessage({toggleTasks:true}); 