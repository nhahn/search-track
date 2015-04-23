app.controller 'graphController', ($scope, $state) ->
  #Get our list of queries

  width = 1280
  height = 800
  color = d3.scale.category20()

  force = d3.layout.force()
      .charge(-400)
      .linkDistance (l) -> Math.pow(1.0 - l.value, 1) * 500
      .size([width, height])

  real_svg = d3.select("#graph").append("svg")
  svg = real_svg.append("g")
  current_scale = 1
  current_translate = [0, 0]
  zoom = d3.behavior.zoom()
          .scaleExtent([0.1, 10])
          .on("zoom", () ->
            svg.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")")
            current_scale = d3.event.scale
            current_translate = d3.event.translate
            $('text.label').css('font-size', 1.25*(1/current_scale) + 'em')
            $('.node').css('stroke-width', 3*(1/current_scale) + 'px')
            text.attr('stroke-width', (d) -> 0.5 * (1/current_scale))
            node.attr('r', (d) -> 2.5 * d.size * (1/current_scale))
            link.style("stroke-width", (d) -> 
              if d.value > 0.2
                Math.pow(d.value, 2) * 3 * (1/current_scale)
              else
                0
            )
            tick()
          ).center(null)
  real_svg.call(zoom).on('mousedown.zoom',null)

  fixPoint = (point) ->
    {x: (point.x * current_scale) + current_translate[0], y: (point.y * current_scale) + current_translate[1]}

  pointInPolygon = (point, path) ->
    # ray-casting algorithm based on
    # http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html

    point = fixPoint(point)

    x = point.x
    y = point.y

    inside = false
    i = 0
    j = path.length - 1
    while (i < path.length)
      xi = path[i].x
      yi = path[i].y
      xj = path[j].x
      yj = path[j].y

      intersect = ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
      if (intersect)
        inside = !inside
      j = i++

    return inside

  inPoly = false
  lineData = []
  mousedown = () ->
    if (d3.event.shiftKey)
      console.log 'mouse down'
      inPoly = true
      d3.select("body").style("cursor", "crosshair")
  mousemove = () ->
    if not inPoly
      return
    xy = d3.mouse(this)
    lineData.push {x: xy[0], y: xy[1]}
    tick()
  mouseup = () ->
    console.log 'mouse up'
    inPoly = false
    node.each((d) ->
      d3.select(this).classed("selected", d.selected = pointInPolygon({x: d.x, y: d.y}, lineData))
    )
    lineData = []
    tick()
    d3.select("body").style("cursor", "default")

  real_svg.attr("width", width)
      .attr("height", height)
      .on('mousedown', mousedown)
      .on('mousemove', mousemove)
      .on('mouseup', mouseup)


  lineFunction = d3.svg.line()
                .x((d) -> d.x )
                .y((d) -> d.y )
                .interpolate("basis-closed")

  polygon = real_svg.append('path')
        .attr('stroke', 'lightblue')
        .attr('stroke-width', 3)
        .attr('fill', 'rgba(0,0,0,0.1)')

  node = svg.selectAll(".node")
  link = svg.selectAll(".link")
  text = svg.selectAll("text.label")
  pin = svg.selectAll(".pin")

  tick = () ->
        text.attr("transform", (d) ->
          "translate(" + (d.x + ((2.5*d.size+5)*(1/current_scale))) + "," + (d.y + (3*(1/current_scale))) + ")"
        )

        link.attr("x1", (d) -> d.source.x)
            .attr("y1", (d) -> d.source.y)
            .attr("x2", (d) -> d.target.x)
            .attr("y2", (d) -> d.target.y)

        node.attr("cx", (d) -> d.x )
            .attr("cy", (d) -> d.y )

        pin.attr("transform", (d) ->
          "translate(" + (d.x-(2/current_scale)) + "," + (d.y-(2/current_scale)) + ")"
        )
        .attr("width", (d) ->
          if d.fixed and not d.dragging
            return 4 * (1/current_scale)
          return 0
        )
        .attr("height", (d) ->
          if d.fixed and not d.dragging
            return 4 * (1/current_scale)
          return 0
        )
        polygon.attr('d', lineFunction(lineData))
  force.on("tick", tick)

  wasDragging = false
  drag = force.drag()
    .on("drag", (d) ->
      wasDragging = true
      d.dragging = true
      if (!d3.event.sourceEvent.shiftKey)
        d3.select(this).classed("fixed", d.fixed = true)
    )
    .on("dragend", (d) ->
      console.log 'onDragEnd'
      d.dragging = false
      if (wasDragging and d3.event.sourceEvent.shiftKey)
        d3.select(this).classed("fixed", d.fixed = false)
      wasDragging = false
    )

  graph = {nodes: [], links: []}
  render = () ->
    i = 0
    graph = {nodes: [], links: []}
    queries = SearchInfo.db({name: {'!is': ''}}).get()
    console.log queries
    dot = (v1, v2) ->
      v = _.map _.zip(v1, v2), (xy) -> xy[0] * xy[1]
      v = _.reduce v, (x, y) -> x + y
      v

    mag = (v) ->
      v = _.map v, (x) -> x*x
      out = _.reduce v, (x, y) -> x + y
      Math.sqrt(out)

    cosine = (v1, v2) ->
      dot(v1, v2) / (mag(v1) * mag(v2))

    scale = (v, factor) ->
      _.map v, (s) -> s*factor

    stack = (v1, v2) ->
      v = _.map _.zip(v1, v2), (xy) -> xy[0] + xy[1]


    getLDAVector = (query) ->
      console.log 'getLDAVector(query)'
      pages = _.map query.tabs, (___id) -> PageInfo.db({___id: ___id}).first()
      console.log pages
      pages = _.filter pages, (page) -> not page.isSERP
      console.log pages
      pages = _.filter pages, (page) -> page.size?
      console.log pages
      pages = _.filter pages, (page) -> page.topic_vector?
      console.log pages

      if pages.length == 0
          return null

      total = _.reduce _.map(pages, (page) -> page.size), (x,y)->x+y
      console.log total
      vectors = _.map pages, (page) -> scale(page.topic_vector, page.size/total)
      console.log vectors
      vector = _.reduce vectors, stack
      console.log vector
      vector

    _.each queries, (query) ->
      lda_vector = getLDAVector(query)
      if lda_vector != null
        graph.nodes.push {name: query.name, group: i++, lda_vector: lda_vector, size: PageInfo.db({query: query.name, isSERP: false}).get().length}


    _.each graph.nodes, (node1) ->
      _.each graph.nodes, (node2) ->
        if node2.group > node1.group
          similarity = cosine(node1.lda_vector, node2.lda_vector)
          graph.links.push {source: node1.group, target: node2.group, value: similarity}


    console.log 'render'
    console.log graph.nodes
    console.log 'render'


    force.nodes(graph.nodes)
        .links(graph.links)

    link = link.data(graph.links)
    link.enter().append("line")
        .attr("class", "link")
        .style("stroke-width", (d) -> 
          if d.value > 0.2
            Math.pow(d.value, 2) * 3 
          else
            0
        )

    node = node.data(graph.nodes)
    node.enter().append("circle")
        .attr("class", "node")
        .attr("r", (d) -> 2.5 * d.size)
        .style("fill", (d) -> color(d.group) )
        .call(drag)
        .on('click', (d) ->
          console.log 'onClick'
          if (d3.event.defaultPrevented)
            console.log 'onClick no'
            return

          if (!d3.event.shiftKey)
            was_selected = d.selected
            node.classed("selected", (p) -> p.selected =  p.previouslySelected = false)
            d3.select(this).classed("selected", d.selected = !was_selected)
          else
            was_selected = d.selected
            d3.select(this).classed("selected", d.selected = !d.previouslySelected)
            d3.select(this).classed("selected", d.selected = !was_selected)
        )

    text = text.data(graph.nodes)
    text.enter().append("text")
          .attr("class", "label")
          .attr("fill", (d) -> color(d.group))
          .attr('stroke', 'lightgray')
          .attr('stroke-width', 0.5)
          .text((d) -> d.name + " (" + d.size + ")")

    pin = pin.data(graph.nodes)
    pin.enter().append("rect")
        .attr("x", 0)
        .attr("y", 0)
        .attr("class", "pin")
        .style("fill", 'black')
        .call(drag)

  updateFn = () ->
    render()
    force.start()
  updateFn()
#SearchInfo.updateFunction(updateFn)