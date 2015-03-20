app.controller('treeController', function($scope, $state) {
  var queryUpdate, toggleAll, updateFn;
  queryUpdate = function() {
    return $scope.$apply(function() {
      return $scope.queries = SearchInfo.db().get();
    });
  };
  $scope.queries = SearchInfo.db().get();
  $scope.query = $scope.queries[0];
  d3_tree.init_vis();
  toggleAll = function(d) {
    if (d.children) {
      d.children.forEach(toggleAll);
      return d3_tree.toggle(d);
    }
  };
  updateFn = function() {
    var page_info;
    page_info = PageInfo.db({
      query: $scope.query.name
    }, {
      referrer: {
        isNull: false
      }
    }).get();
    d3_tree.root = PageInfo.db({
      query: $scope.query.name
    }, {
      referrer: {
        isNull: true
      }
    }).first();
    d3_tree.root.children = [];
    d3_tree.root.x0 = d3_tree.h / 2;
    d3_tree.root.y0 = 0;
    d3_tree.root.name = d3_tree.root.query;
    _.each(page_info, function(record) {
      return record.children = [];
    });
    _.each(page_info, function(record) {
      var referrer;
      record.name = record.url;
      referrer = _.find(page_info, function(item) {
        return item.___id === record.referrer;
      });
      if (referrer != null) {
        return referrer.children.push(record);
      } else {
        return d3_tree.root.children.push(record);
      }
    });
    d3_tree.root.children.forEach(toggleAll);
    return d3_tree.update(d3_tree.root);
  };
  updateFn();
  SearchInfo.updateFunction(queryUpdate);
  PageInfo.updateFunction(updateFn);
  return $scope.$watch('query', function(newVal, oldVal) {
    return updateFn();
  });
});

//# sourceMappingURL=tree.js.map
