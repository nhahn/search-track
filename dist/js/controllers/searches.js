app.controller('searchesController', function($scope, $state, $http) {
  var updateFn;
  updateFn = function(apply) {
    var grouped, page_info;
    page_info = PageInfo.db({
      referrer: {
        isNull: false
      }
    }).get();
    grouped = _.groupBy(page_info, function(record) {
      return record.query;
    });
    grouped = _.object(_.map(grouped, function(val, key) {
      return [
        key, _.groupBy(val, function(record) {
          var hash, uri;
          uri = new URI(record.url);
          hash = uri.hash();
          if (hash) {
            uri.hash("");
            record.hash = hash;
          }
          return uri.toString();
        })
      ];
    }));
    grouped = _.object(_.map(grouped, function(val, key) {
      return [
        key, {
          records: val
        }
      ];
    }));
    if (!apply) {
      return $scope.$apply(function() {
        return $scope.pages = _.pick(grouped, function(val, key, obj) {
          return key.length > 2;
        });
      });
    } else {
      return $scope.pages = _.pick(grouped, function(val, key, obj) {
        return key.length > 2;
      });
    }
  };
  updateFn(true);
  SearchInfo.updateFunction(updateFn);
  return PageInfo.updateFunction(updateFn);
});

//# sourceMappingURL=searches.js.map
