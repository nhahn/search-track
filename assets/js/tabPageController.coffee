app = angular.module('tabApp', ['ui.router', 'ui.bootstrap', 'angular-underscore'])

app.run ($rootScope, $state, $stateParams) ->
  $rootScope.$state = $state
  $rootScope.$stateParams = $stateParams

app.config ($stateProvider, $urlRouterProvider) ->

  $stateProvider
    .state('searches', {
      url: '/'
      templateUrl: '/dist/templates/tabPage/searches.html'
      controller: ($scope, $state, $http) ->
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
          if !apply
            $scope.$apply () ->
              $scope.pages = _.pick grouped, (val, key, obj) ->
                key.length > 2
          else
            $scope.pages = _.pick grouped, (val, key, obj) ->
              key.length > 2
          req =
            method: "POST",
            url: 'http://127.0.0.1:5000/',
            #data: {'groups': JSON.stringify([['html1', 'html2'], ['html3', 'html4']])},
            data: JSON.stringify(grouped),
            headers: {'Content-Type': 'application/json'},
          onSuccess = (results) ->
            console.log 'onSuccess'
            grouped = results
          onComplete = () ->
            console.log 'onComplete'
            $scope.pages = _.pick grouped, (val, key, obj) ->
              key.length > 2
          $http(req).success(onSuccess).finally(onComplete)
        updateFn(true)
        # SearchInfo.updateFunction(updateFn)
        PageInfo.updateFunction(updateFn)          
      })
    .state('tree', {
      url: '/tree'
      templateUrl: '/dist/templates/tabPage/tree.html'
      controller: ($scope, $state) ->
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
      })
    .state('settings', {
      url: '/settings'
      templateUrl: '/dist/templates/tabPage/settings.html'
      controller: ($scope, $state, $modal) ->
        
        $scope.openDeleteModal = () ->
          modalInstance = $modal.open {
            templateUrl: 'deleteContent.html',
            size: 'sm',
            controller: 'removeModal'
          }
        
      })

  $urlRouterProvider.otherwise('/')

app.controller 'MainCtrl', ($scope, $rootScope, $state) ->
  $scope.getDomain = (str) ->
    matches = str.match(/^https?\:\/\/([^\/:?#]+)(?:[\/:?#]|$)/i)
    return matches && matches[1]

  
app.controller 'removeModal', ($scope, $modalInstance) ->
  
  $scope.ok = () ->
    PageInfo.clearDB()
    SearchInfo.clearDB()
    $modalInstance.close('cleared')
    
  $scope.cancel = () ->
    $modalInstance.close('canceled')
  ###
    if $cookies.state?
    $scope.$evalAsync (scope) ->
      $state.go($cookies.state)
  ###

  
