var app;

app = angular.module('tabApp', ['ui.router', 'ui.bootstrap', 'angular-underscore']);

app.run(function($rootScope, $state, $stateParams) {
  $rootScope.$state = $state;
  return $rootScope.$stateParams = $stateParams;
});

app.config(function($stateProvider, $urlRouterProvider) {
  $stateProvider.state('searches', {
    url: '/',
    templateUrl: '/dist/templates/tabPage/searches.html',
    controller: function($scope, $state, $http) {
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
              records: val,
              lda: SearchInfo.db({
                name: key
              }).first().lda
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
      return PageInfo.updateFunction(updateFn);
    }
  }).state('tree', {
    url: '/tree',
    templateUrl: '/dist/templates/tabPage/tree.html',
    controller: function($scope, $state) {
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
    }
  }).state('graph', {
    url: '/graph',
    templateUrl: '/dist/templates/tabPage/graph.html',
    controller: function($scope, $state) {
      var updateFn;
      updateFn = function() {
        var color, cosine, current_scale, current_translate, dot, drag, fixPoint, force, graph, height, i, inPoly, lineData, lineFunction, link, mag, mousedown, mousemove, mouseup, node, pin, pointInPolygon, polygon, queries, real_svg, render, svg, text, wasDragging, width, zoom;
        queries = SearchInfo.db({
          name: {
            '!is': ''
          },
          lda_vector: {
            isNull: false
          }
        }).get();
        console.log(queries);
        graph = {
          nodes: [],
          links: []
        };
        i = 0;
        _.each(queries, function(query) {
          return graph.nodes.push({
            name: query.name,
            group: i++,
            info: query,
            size: PageInfo.db({
              query: query.name
            }).get().length
          });
        });
        dot = function(v1, v2) {
          var v;
          v = _.map(_.zip(v1, v2), function(xy) {
            return xy[0] * xy[1];
          });
          v = _.reduce(v, function(x, y) {
            return x + y;
          });
          return v;
        };
        mag = function(v) {
          var out;
          v = _.map(v, function(x) {
            return x * x;
          });
          out = _.reduce(v, function(x, y) {
            return x + y;
          });
          return Math.sqrt(out);
        };
        cosine = function(v1, v2) {
          return dot(v1, v2) / (mag(v1) * mag(v2));
        };
        _.each(graph.nodes, function(node1) {
          return _.each(graph.nodes, function(node2) {
            var similarity;
            if (node2.group > node1.group) {
              similarity = cosine(node1.info.lda_vector, node2.info.lda_vector);
              return graph.links.push({
                source: node1.group,
                target: node2.group,
                value: similarity
              });
            }
          });
        });
        width = 1280;
        height = 800;
        color = d3.scale.category20();
        force = d3.layout.force().charge(1000).friction(0.01).linkDistance(function(l) {
          return Math.pow(1.0 - l.value, 1) * 500;
        }).size([width, height]);
        real_svg = d3.select("#graph").append("svg");
        svg = real_svg.append("g");
        current_scale = 1;
        current_translate = [0, 0];
        zoom = d3.behavior.zoom().scaleExtent([0.1, 10]).on("zoom", function() {
          console.log('onZoom');
          console.log(d3.event.translate);
          console.log(d3.event.scale);
          svg.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
          current_scale = d3.event.scale;
          return current_translate = d3.event.translate;
        }).center(null);
        real_svg.call(zoom).on('mousedown.zoom', null);
        fixPoint = function(point) {
          return {
            x: (point.x * current_scale) + current_translate[0],
            y: (point.y * current_scale) + current_translate[1]
          };
        };
        pointInPolygon = function(point, path) {
          var inside, intersect, j, x, xi, xj, y, yi, yj;
          point = fixPoint(point);
          x = point.x;
          y = point.y;
          inside = false;
          i = 0;
          j = path.length - 1;
          while (i < path.length) {
            xi = path[i].x;
            yi = path[i].y;
            xj = path[j].x;
            yj = path[j].y;
            intersect = ((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
            if (intersect) {
              inside = !inside;
            }
            j = i++;
          }
          return inside;
        };
        inPoly = false;
        lineData = [];
        mousedown = function() {
          if (d3.event.shiftKey) {
            console.log('mouse down');
            return inPoly = true;
          }
        };
        mousemove = function() {
          var xy;
          if (!inPoly) {
            return;
          }
          xy = d3.mouse(this);
          lineData.push({
            x: xy[0],
            y: xy[1]
          });
          return force.start();
        };
        mouseup = function() {
          console.log('mouse up');
          inPoly = false;
          node.each(function(d) {
            return d3.select(this).classed("selected", d.selected = pointInPolygon({
              x: d.x,
              y: d.y
            }, lineData));
          });
          lineData = [];
          return force.start();
        };
        real_svg.attr("width", width).attr("height", height).on('mousedown', mousedown).on('mousemove', mousemove).on('mouseup', mouseup);
        lineFunction = d3.svg.line().x(function(d) {
          return d.x;
        }).y(function(d) {
          return d.y;
        }).interpolate("basis-closed");
        polygon = real_svg.append('path').attr('stroke', 'lightblue').attr('stroke-width', 3).attr('fill', 'rgba(0,0,0,0.1)');
        node = svg.selectAll(".node");
        link = svg.selectAll(".link");
        text = svg.selectAll("text.label");
        pin = svg.selectAll(".pin");
        force.nodes(graph.nodes).links(graph.links).on("tick", function() {
          link.attr("x1", function(d) {
            return d.source.x;
          }).attr("y1", function(d) {
            return d.source.y;
          }).attr("x2", function(d) {
            return d.target.x;
          }).attr("y2", function(d) {
            return d.target.y;
          });
          node.attr("cx", function(d) {
            return d.x;
          }).attr("cy", function(d) {
            return d.y;
          });
          text.attr("transform", function(d) {
            return "translate(" + (d.x + (2.5 * d.size) + 5) + "," + (d.y + 3) + ")";
          });
          pin.attr("transform", function(d) {
            return "translate(" + (d.x - 2) + "," + (d.y - 2) + ")";
          }).attr("width", function(d) {
            if (d.fixed && !d.dragging) {
              return 4;
            }
            return 0;
          }).attr("height", function(d) {
            if (d.fixed && !d.dragging) {
              return 4;
            }
            return 0;
          });
          return polygon.attr('d', lineFunction(lineData));
        });
        wasDragging = false;
        drag = force.drag().on("drag", function(d) {
          console.log('onDrag');
          wasDragging = true;
          d.dragging = true;
          if (!d3.event.sourceEvent.shiftKey) {
            return d3.select(this).classed("fixed", d.fixed = true);
          }
        }).on("dragend", function(d) {
          console.log('onDragEnd');
          d.dragging = false;
          if (wasDragging && d3.event.sourceEvent.shiftKey) {
            d3.select(this).classed("fixed", d.fixed = false);
          }
          return wasDragging = false;
        });
        render = function() {
          console.log('render');
          console.log(graph.nodes);
          console.log('render');
          link = link.data(graph.links);
          link.enter().append("line").attr("class", "link").style("stroke-width", function(d) {
            if (d.value > 0.2) {
              return Math.pow(d.value, 2) * 3;
            } else {
              return 0;
            }
          });
          node = node.data(graph.nodes);
          node.enter().append("circle").attr("class", "node").attr("r", function(d) {
            return 2.5 * d.size;
          }).style("fill", function(d) {
            return color(d.group);
          }).call(drag).on('click', function(d) {
            var was_selected;
            console.log('onClick');
            if (d3.event.defaultPrevented) {
              console.log('onClick no');
              return;
            }
            if (!d3.event.shiftKey) {
              was_selected = d.selected;
              node.classed("selected", function(p) {
                return p.selected = p.previouslySelected = false;
              });
              return d3.select(this).classed("selected", d.selected = !was_selected);
            } else {
              was_selected = d.selected;
              d3.select(this).classed("selected", d.selected = !d.previouslySelected);
              return d3.select(this).classed("selected", d.selected = !was_selected);
            }
          });
          text = text.data(graph.nodes);
          text.enter().append("text").attr("class", "label").attr("fill", function(d) {
            return color(d.group);
          }).attr('stroke', 'lightgray').attr('stroke-width', 0.5).text(function(d) {
            return d.name + " (" + d.size + ")";
          });
          pin = pin.data(graph.nodes);
          return pin.enter().append("rect").attr("x", 0).attr("y", 0).attr("class", "pin").style("fill", 'black').call(drag);
        };
        render();
        return force.start();
      };
      return updateFn();
    }
  }).state('settings', {
    url: '/settings',
    templateUrl: '/dist/templates/tabPage/settings.html',
    controller: function($scope, $state, $modal) {
      return $scope.openDeleteModal = function() {
        var modalInstance;
        return modalInstance = $modal.open({
          templateUrl: 'deleteContent.html',
          size: 'sm',
          controller: 'removeModal'
        });
      };
    }
  });
  return $urlRouterProvider.otherwise('/');
});

app.controller('MainCtrl', function($scope, $rootScope, $state) {
  return $scope.getDomain = function(str) {
    var matches;
    matches = str.match(/^https?\:\/\/([^\/:?#]+)(?:[\/:?#]|$)/i);
    return matches && matches[1];
  };
});

app.controller('removeModal', function($scope, $modalInstance) {
  $scope.ok = function() {
    PageInfo.clearDB();
    SearchInfo.clearDB();
    return $modalInstance.close('cleared');
  };
  return $scope.cancel = function() {
    return $modalInstance.close('canceled');
  };

  /*
    if $cookies.state?
    $scope.$evalAsync (scope) ->
      $state.go($cookies.state)
   */
});

//# sourceMappingURL=tabPageController.js.map
