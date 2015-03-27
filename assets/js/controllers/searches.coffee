app.controller 'searchesController', ($scope, $state, $http) ->  
  updateFn = (apply) ->
    page_info = PageInfo.db().get()
    # {query: [record, record,..], ...}
    grouped = _.groupBy page_info, (record) ->
      record.query

    # [{query, {url: [record, record, ...]}}, ...]
    grouped = _.object _.map grouped, (val,key) ->
      [key, _.groupBy val, (record) ->
        uri = new URI(record.url)
        hash = uri.hash()
        if (hash)
          uri.hash("")
          record.hash = hash
        return uri.toString()
      ]

    grouped = _.object _.map grouped, (val, key) ->
      [key, {records: val}]

    if !apply
      $scope.$apply () ->
        $scope.pages = _.pick grouped, (val, key, obj) ->
          key.length > 2
    else
      $scope.pages = _.pick grouped, (val, key, obj) ->
        key.length > 2
  updateFn(true)
  SearchInfo.updateFunction(updateFn)
  PageInfo.updateFunction(updateFn) 