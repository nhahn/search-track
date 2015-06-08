app.controller 'searchesController', ($scope, $state, $http, $dexieBind) ->          
  $dexieBind.bind(db,db.Page.toCollection(), $scope).then (data) ->
    $scope.pages = data
  
