app.controller('graphController', function($scope, $state) {
  var color, current_scale, current_translate, drag, fixPoint, force, graph, height, inPoly, lineData, lineFunction, link, mousedown, mousemove, mouseup, node, pin, pointInPolygon, polygon, real_svg, render, svg, text, tick, updateFn, wasDragging, width, zoom;
  width = 1280;
  height = 800;
  color = d3.scale.category20();
  force = d3.layout.force().charge(-400).linkDistance(function(l) {
    return Math.pow(1.0 - l.value, 1) * 500;
  }).size([width, height]);
  real_svg = d3.select("#graph").append("svg");
  svg = real_svg.append("g");
  current_scale = 1;
  current_translate = [0, 0];
  zoom = d3.behavior.zoom().scaleExtent([0.1, 10]).on("zoom", function() {
    svg.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
    current_scale = d3.event.scale;
    current_translate = d3.event.translate;
    $('text.label').css('font-size', 1.25 * (1 / current_scale) + 'em');
    $('.node').css('stroke-width', 3 * (1 / current_scale) + 'px');
    text.attr('stroke-width', function(d) {
      return 0.5 * (1 / current_scale);
    });
    node.attr('r', function(d) {
      return 2.5 * d.size * (1 / current_scale);
    });
    link.style("stroke-width", function(d) {
      if (d.value > 0.2) {
        return Math.pow(d.value, 2) * 3 * (1 / current_scale);
      } else {
        return 0;
      }
    });
    return tick();
  }).center(null);
  real_svg.call(zoom).on('mousedown.zoom', null);
  fixPoint = function(point) {
    return {
      x: (point.x * current_scale) + current_translate[0],
      y: (point.y * current_scale) + current_translate[1]
    };
  };
  pointInPolygon = function(point, path) {
    var i, inside, intersect, j, x, xi, xj, y, yi, yj;
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
      inPoly = true;
      return d3.select("body").style("cursor", "crosshair");
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
    return tick();
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
    tick();
    return d3.select("body").style("cursor", "default");
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
  tick = function() {
    text.attr("transform", function(d) {
      return "translate(" + (d.x + ((2.5 * d.size + 5) * (1 / current_scale))) + "," + (d.y + (3 * (1 / current_scale))) + ")";
    });
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
    pin.attr("transform", function(d) {
      return "translate(" + (d.x - (2 / current_scale)) + "," + (d.y - (2 / current_scale)) + ")";
    }).attr("width", function(d) {
      if (d.fixed && !d.dragging) {
        return 4 * (1 / current_scale);
      }
      return 0;
    }).attr("height", function(d) {
      if (d.fixed && !d.dragging) {
        return 4 * (1 / current_scale);
      }
      return 0;
    });
    return polygon.attr('d', lineFunction(lineData));
  };
  force.on("tick", tick);
  wasDragging = false;
  drag = force.drag().on("drag", function(d) {
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
  graph = {
    nodes: [],
    links: []
  };
  render = function() {
    var cosine, dot, getLDAVector, i, mag, queries, scale, stack;
    i = 0;
    graph = {
      nodes: [],
      links: []
    };
    queries = SearchInfo.db({
      name: {
        '!is': ''
      }
    }).get();
    console.log(queries);
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
    scale = function(v, factor) {
      return _.map(v, function(s) {
        return s * factor;
      });
    };
    stack = function(v1, v2) {
      var v;
      return v = _.map(_.zip(v1, v2), function(xy) {
        return xy[0] + xy[1];
      });
    };
    getLDAVector = function(query) {
      var pages, total, vector, vectors;
      console.log('getLDAVector(query)');
      pages = _.map(query.tabs, function(___id) {
        return PageInfo.db({
          ___id: ___id
        }).first();
      });
      console.log(pages);
      pages = _.filter(pages, function(page) {
        return !page.isSERP;
      });
      console.log(pages);
      pages = _.filter(pages, function(page) {
        return page.size != null;
      });
      console.log(pages);
      pages = _.filter(pages, function(page) {
        return page.topic_vector != null;
      });
      console.log(pages);
      if (pages.length === 0) {
        return null;
      }
      total = _.reduce(_.map(pages, function(page) {
        return page.size;
      }), function(x, y) {
        return x + y;
      });
      console.log(total);
      vectors = _.map(pages, function(page) {
        return scale(page.topic_vector, page.size / total);
      });
      console.log(vectors);
      vector = _.reduce(vectors, stack);
      console.log(vector);
      return vector;
    };
    _.each(queries, function(query) {
      var lda_vector;
      lda_vector = getLDAVector(query);
      if (lda_vector !== null) {
        return graph.nodes.push({
          name: query.name,
          group: i++,
          lda_vector: lda_vector,
          size: PageInfo.db({
            query: query.name,
            isSERP: false
          }).get().length
        });
      }
    });
    _.each(graph.nodes, function(node1) {
      return _.each(graph.nodes, function(node2) {
        var similarity;
        if (node2.group > node1.group) {
          similarity = cosine(node1.lda_vector, node2.lda_vector);
          return graph.links.push({
            source: node1.group,
            target: node2.group,
            value: similarity
          });
        }
      });
    });
    console.log('render');
    console.log(graph.nodes);
    console.log('render');
    force.nodes(graph.nodes).links(graph.links);
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
  updateFn = function() {
    render();
    return force.start();
  };
  return updateFn();
});

//# sourceMappingURL=graph.js.map
