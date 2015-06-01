app.controller 'searchesController', ($scope, $state, $http, $dexieBind) ->          
  $dexieBind.bind(db,db.PageInfo.toCollection(), $scope).then (data) ->
    $scope.pages = data
  