  app.controller 'treeController', ($scope, $state) ->
    #Get our list of queries
    queryUpdate = () ->
      $scope.$apply () ->
        $scope.queries = SearchInfo.db().get()
    $scope.queries = SearchInfo.db().get()
    $scope.query = $scope.queries[0]
    #Initialize everything for d3
    d3_tree.init_vis()
    toggleAll = (d) ->
      if d.children
        d.children.forEach(toggleAll)
        d3_tree.toggle(d)

    updateFn = () ->
      page_info = PageInfo.db({query: $scope.query.name}, {referrer: {isNull: false}}).get()
      #Root is the one without the referrer
      d3_tree.root = PageInfo.db({query: $scope.query.name}, {referrer: {isNull: true}}).first()
      d3_tree.root.children = [] 
      d3_tree.root.x0 = d3_tree.h/2
      d3_tree.root.y0 = 0
      d3_tree.root.name = d3_tree.root.query

      _.each page_info, (record) ->
        record.children = []

      _.each page_info, (record) ->
        #uri = new URI(record.url)
        record.name = record.url
        referrer = _.find page_info, (item) ->
          item.___id == record.referrer
        if referrer?
          referrer.children.push(record)
        else
          d3_tree.root.children.push(record)


      d3_tree.root.children.forEach(toggleAll)
      d3_tree.update d3_tree.root  

    updateFn()
    SearchInfo.updateFunction(queryUpdate)
    PageInfo.updateFunction(updateFn)
    $scope.$watch 'query', (newVal, oldVal) ->
      updateFn()