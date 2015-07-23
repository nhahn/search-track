listApp = angular.module 'listApp', ['ngDraggable', 'ngDexieBind']

listApp.controller 'RootCtrl', ($scope, $dexieBind, $location, $q) ->
  getTasksUpTo = (level, tasks) ->
    return tasks if tasks[tasks.length-1].level <= level
    return tasks[tasks.length-1].$join(db.Task, 'parent', 'id').then (res) ->
      tasks.push(res)
      return getTaskUpTo(level, tasks)
    
  $scope.tasks = []
  $scope.level = $location.search().level
  
  chrome.runtime.sendMessage { getCurrentTab: true }, (msg) ->
    
    $dexieBind.bind(db, db.Tab.where('tab').equals(msg[0].id).and((val) -> val.status is 'active'), $scope).then (tab) ->
      $scope.tab = tab
      return $scope.tab.$join(db.Task, 'task', 'id')
    .then (tasks) ->
      getTasksUpTo($scope.level, [tasks])
    .then (tasks) ->
      $scope.curTasks = tasks
      $dexieBind.bind(db,db.Task.filter((val) -> val.hidden == false), $scope)
    .then (tasks) ->
      $scope.tasks = tasks
  
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