debug = true
log = if debug then console.log.bind(console) else () ->

min_size = 1
max_size = 300

# TODO: use margin for positioning (http://bl.ocks.org/mbostock/3087986)

force_g_offsetX = 100
force_g_offsetY = 200
pack_g_offsetX = 600
pack_g_offsetY = 200

pop_format = d3.format(".3s")
power_format = d3.format(".0f")

power_scale = d3.scale.pow().exponent(0.25)
  .domain([0, 3000])
  .range([min_size, max_size / 3])

body= d3.select("body")
svg = d3.select("svg")

force_g = svg.append("g")
  .attr("transform", "translate(#{ force_g_offsetX }, #{ force_g_offsetY })")
pack_g = svg.append("g")
  .attr("transform", "translate(#{ pack_g_offsetX }, #{ pack_g_offsetY })")
label_container = d3.select(".container")
  .append("div").attr("class", "label-container")

d3.json "data.json", (err, data) ->
  power_data = init_power_data data
  pop_data = init_pop_data data

  log power_data
  log pop_data

  # -- PACK INITIALIZATION -- #

  pack = d3.layout.pack()
    .size [max_size, max_size]
  pack_data = pack.nodes(pop_data)
    .filter (d) -> !d.hidden
    .reverse()

  pack_g.datum(pack_data)
  pack_nodes = pack_g.selectAll(".pack.node").data(pack_data)
    .enter().append("g")
      .attr "transform", (d) ->
        cpoint = x: max_size / 2, y: max_size / 2
        pt = rotate d, cpoint, -Math.PI / 2
        d.pack_x = pt.x
        d.pack_y = pt.y
        return "translate(#{d.pack_x}, #{d.pack_y})"
      .attr "id", (d) -> "pack-#{d.id}"
      .attr "class", (d) -> "pack node #{d.id}"

  pack_nodes.append("circle")
    .attr "r", (d) -> return d.r

  pop_labels = label_container.selectAll(".pack.label").data(pack_data)
    .enter().append("div")
      .attr "class", (d) -> "pack label #{d.id}"
      .attr "id", (d) -> "label-#{d.id}"
      .style "top", (d) -> d.label_top = pack_g_offsetY + d.pack_y - d.r
      .style "left", (d) -> d.label_left = pack_g_offsetX + d.pack_x - d.r
      .style "width", (d) -> d.label_width = d.r * 2
      .style "height", (d) -> d.label_height = d.r * 2

  pop_labels.append("p")
    .html((d) -> "<strong>#{d.name}</strong> #{pop_format(d.value)}")

  pop_label_links_data = pack_data.filter (d) -> d.label_pos
  pop_label_links = pack_g.selectAll("line.label-link").data(pop_label_links_data)
    .enter().append("line")
      .attr "class", "label-link"
      .attr "x1", (d) -> d.pack_x
      .attr "y1", (d) -> d.pack_y
      .attr "x2", (d) ->
        offset = if d.label_pos.x > 0 then 0 else 100
        d.label_left + d.label_pos.x - pack_g_offsetX + offset
      .attr "y2", (d) -> d.label_top + d.label_pos.y - pack_g_offsetY + 100 / 2

  # -- FORCE INITIALIZATION -- #

  force_data = []
  last_force_data = force_data
  force_nodes = force_g.selectAll(".force.node").data(force_data, (d) -> d.id)
  force_labels = label_container.selectAll(".power.label").data(force_data)
  force = d3.layout.force()
    .gravity 0.05
    .size [300, 300]
    .charge 0
    .friction 0.3
    .on "tick", (e) ->
      force_nodes
        .each collide(e.alpha, force_data)
        .attr "transform", (d) -> "translate(#{d.x}, #{d.y})"
      force_labels.style "transform", (d) ->
        # offset label so that they are centered
        width_offset = if parseFloat(this.style.width) is 100 then -50 + d.r else 0
        d.force_x = d.x + force_g_offsetX - d.r + width_offset
        d.force_y = d.y + force_g_offsetY - d.r
        "translate3d(#{d.force_x}px, #{d.force_y}px, 0px)"

  # -- Force Layout Update -- #

  update_force_node = () ->
    force_nodes = force_g.selectAll(".force.node").data(force_data, (d) -> d.id)
    force_nodes.select("circle")
      .transition().duration(1000).tween('force_r', (d) ->
        console.log "changed", d.id
        i = d3.interpolate(this.getAttribute("r") or 0, power_scale d.value)
        (t) ->
          d.r = i(t)
          this.setAttribute("r", d.r)
      )
    enter_nodes = force_nodes.enter().append("g")
      .attr "class", "force node"
    enter_nodes.transition().duration(1000).tween "force_translate_enter", (d) ->
      enter_link_nodes = last_force_data.filter (e) -> d.enter?.indexOf(e.id) >= 0
      circle = d3.select(this).select("circle")
      target = enter_link_nodes[0];
      original_r = target?.r or 0
      if (target)
        random_x = random(-5, 5)
        random_y = random(-5, 5)
        d.px = target.px + random_x
        d.py = target.py + random_y
        d.x = target.x + random_x
        d.y = target.y + random_y
      target_r = power_scale d.value
      i_r = d3.interpolate(original_r, target_r)
      # Set initial transform to prevent flash
      d3.select(this).attr("transform", "translate(#{d.x}, #{d.y})")
      (t) ->
        d.r = i_r t
        d.collide_factor = if t > 0.9 then 1 else d3.scale.sqrt()(t)
        # d.no_collide = true
        circle.attr "r", d.r
    enter_nodes.append("circle")
      .attr "id", (d) -> d.id

    force_nodes.exit()
      .transition().duration(1000).tween "force_translate_exit", (d) ->
        console.log "removed", d.id
        exit_link_nodes = force_data.filter (e) -> d.exit?.indexOf(e.id) >= 0
        target = exit_link_nodes[0];

        original = get_translate this
        circle = d3.select(this).select('circle')
        original_r = circle.attr "r"
        (t) ->
          if target
            pos = move_to original, target, t
            this.setAttribute "transform", "translate(#{pos.x}, #{pos.y})"
          circle.attr "r", scale_to original_r, target?.r or 0, t
      .each "end", () -> this.remove()

    force_labels = label_container.selectAll(".power.label").data(force_data, (d) -> d.id)
    force_labels
      .attr "class", (d) -> "power label #{d.id}"
      .attr "id", (d) -> "label-#{d.id}"
      .style "width", (d) -> Math.max power_scale(d.value) * 2, 100
      .style "height", (d) -> power_scale(d.value) * 2
      .select "p"
        .html (d) -> "<strong>#{d.name}</strong> #{(power_format(d.value))}x"
        .style "opacity", 0
          .transition().duration(1000).style "opacity", 1
    force_labels.enter().append("div")
      .attr "class", (d) -> "power label #{d.id}"
      .attr "id", (d) -> "label-#{d.id}"
      .style "width", (d) -> Math.max power_scale(d.value) * 2, 100
      .style "height", (d) -> power_scale(d.value) * 2
      .append("p")
        .html (d) -> "<strong>#{d.name}</strong> #{(power_format(d.value))}x"
          .style "opacity", 0
          .transition().delay(if first_run then 0 else 500).duration(1000).style "opacity", 1
    # force_labels.exit().transition().duration(1000).style("opacity", 0).remove()
    force_labels.exit()
      .transition().duration(250).style "opacity", 0
      .each "end", () -> this.remove()

    force
      .nodes(force_data)
      .start()

    force_nodes.call force.drag

  # -- Pack Layout Update -- #

  update_pack_node = (depth) ->
    # pack_nodes.select("circle")
    #   .filter (d) -> d.depth isnt depth
    #   .transition()
    #     .style "fill", "none"

    # pack_nodes.select("circle")
    #   .filter (d) -> d.depth is depth
    #   .style "fill", ""
    #   .transition()
    #     .style "opacity", 1

    pack_nodes
      .filter (d) -> d.depth is depth
      .classed "no-fill", false

    pack_nodes
      .filter (d) -> d.depth isnt depth
      .classed "no-fill", true

    pop_labels
      .style "opacity", 0
      .filter (d) -> d.depth is depth or (depth >= 2 and d.id is "others")
      .transition().duration(1000)
        .style "opacity", 1

    pop_label_links
      .style "opacity", 0
      .filter (d) -> d.depth is depth
      .transition().duration(1000)
        .style "opacity", 1

    pop_labels
      .filter (d) -> d.depth is depth and d.label_pos
      .style "width", 100
      .style "height", 100
      .style "top", (d) -> d.label_top + d.label_pos.y
      .style "left", (d) -> d.label_left + d.label_pos.x

  # -- Mouse Selection -- #

  show_link = (pack_node, force_node) ->
    svg.classed "highlighted", true
    return if !active_force_node?.size() or !active_pack_node?.size()

    # TODO set active to labels too
    active_pack_node.classed "active", true
    active_force_node.classed "active", true

  hide_link = () ->
    svg.classed "highlighted", false
    return if !active_force_node?.size() or !active_pack_node?.size()

    active_pack_node.classed "active", false
    active_force_node.classed "active", false

  active_pack_node = null
  active_force_node = null

  update_active_links = () ->
    return if !active_force_node?.size() or !active_pack_node?.size()

    point1 =
      x: active_force_node.datum().x + force_g_offsetX, y: active_force_node.datum().y + force_g_offsetY
    point2 =
      x: active_pack_node.datum().pack_x + pack_g_offsetX, y: active_pack_node.datum().pack_y + pack_g_offsetY
    radius1 = active_force_node.datum().r
    radius2 = active_pack_node.datum().r
    tangents = get_common_tangent point1, point2, radius1, radius2
  
    active_links = svg.selectAll("line.active-link").data(tangents)
      .attr "x1", (d) -> d[0][0]
      .attr "y1", (d) -> d[0][1]
      .attr "x2", (d) -> d[1][0]
      .attr "y2", (d) -> d[1][1]
    active_links.enter()
      .append "line"
      .attr "class", "active-link"
      .attr "x1", (d) -> d[0][0]
      .attr "y1", (d) -> d[0][1]
      .attr "x2", (d) -> d[1][0]
      .attr "y2", (d) -> d[1][1]
    active_links.exit()
      .remove()


  force.on "tick.update-active-link", update_active_links

  update_mouse_binding = (depth) ->
    pack_nodes
      .on "mousemove", () ->
        active_pack_node = d3.select this
        pack_node_name = active_pack_node.datum().name
        active_force_node = force_nodes.filter (d) -> d.name is pack_node_name
        if active_pack_node?.size() and active_force_node?.size()
          show_link()
          update_active_links()
      .on "mouseout", () ->
        hide_link()
        active_force_node = active_pack_node = null

    force_nodes
      .on "mousemove", () ->
        active_force_node = d3.select(this)
        force_node_name = active_force_node.datum().name
        active_pack_node = pack_nodes.filter (d) -> d.name is force_node_name
        if active_pack_node?.size() and active_force_node?.size()
          show_link()
          update_active_links()
      .on "mouseout", () ->
        hide_link()
        active_force_node = active_pack_node = null

  # -- Main Update -- #

  cur_stage = ""
  cur_depth = 0
  first_run = true

  update = (stage, depth) ->
    return if stage is cur_stage

    force_data = power_data[stage]
    last_force_data = power_data[cur_stage] or []

    # Copy the position of the last node to the current node
    # so no weird animation
    if (last_force_data)
      force_data.forEach (d) ->
        match_nodes = last_force_data.filter (e) -> d.id is e.id
        match_nodes.forEach (e) ->
          d.x = e.x
          d.y = e.y

    update_force_node()
    update_pack_node(depth)
    update_mouse_binding(depth)

    cur_stage = stage
    cur_depth = depth
    log cur_stage, cur_depth

    first_run = false

  update "stage1", 0

  d3.select("button#stage1").on "click", -> update("stage1", 0)
  d3.select("button#stage2").on "click", -> update("stage2", 1)
  d3.select("button#stage3").on "click", -> update("stage3", 2)
  d3.select("button#stage4").on "click", -> update("stage4", 3)

# --- Data Formating --- #

init_power_data = (data) ->
  ec_voter = data.election_comittee.voter
  ec_voter_power = data.registered_voter / ec_voter
  sectors_length = data.election_comittee.sectors.length

  power_data =
    stage1: [
      id: "all"
      name: "Registered Voters"
      value: 1
    ]

    stage2: [
      id: "all"
      name: "Others"
      value: 0
    ,
      id: "ec-voters"
      name: "Voters for Election Comittee"
      value: data.registered_voter / ec_voter
    ]

    stage3: [
      id: "all"
      name: "Others"
      value: 0
    ]

    stage4: [
      id: "all"
      name: "Others"
      value: 0
    ]

  data.election_comittee.sectors.forEach (sector) ->
    power_data.stage3.push(
      id: sector.id
      name: sector.name
      value: (ec_voter / sectors_length) / sector.count * ec_voter_power
      exit: ["ec-voters"]
      enter: ["ec-voters"]
    )
    power_data.stage4.push(
      id: sector.id
      name: "Voted-in Election Comittee Members from #{sector.name}"
      value: data.registered_voter / (data.election_comittee.seats_per_sector * sectors_length)
    )

  for stage_name, nodes of power_data
    nodes.forEach (d) ->
      d.r = power_scale d.value

  power_data

init_pop_data = (data) ->
  ec_voter = data.election_comittee.voter

  label_pos =
    "sector-lrw": { x: -120, y: -50 }
    "sector-fhit": { x: -110, y: -20 }
    "sector-hkcpb": { x: -130, y: 20 }
    "sector-ehil": { x: 85, y: 10 }

    "sector-lrw-cm": { x: -130, y: -125 }
    "sector-fhit-cm": { x: -130, y: -70 }
    "sector-hkcpb-cm": { x: -120, y: 10 }
    "sector-ehil-cm": { x: 65, y: -45 }

  pop_data = {
    id: "all"
    name: "Registered Voters"
    value: data.registered_voter
    children: [
      {
        id: "others"
        name: "Others"
        value: data.registered_voter - ec_voter
      }, {
        id: "ec-voters",
        name: "Voters for Election Comittee"
        value: ec_voter
        children: []
      }
    ]
  }

  pop_data.children[1].children = data.election_comittee.sectors.map (sector) ->
    id: sector.id
    name: sector.name
    value: sector.count
    label_pos: label_pos[sector.id]
    children: [
      id: "#{sector.id}-cm"
      name: "Voted-in Election Comittee Members from #{sector.name}"
      value: data.election_comittee.seats_per_sector
      label_pos: label_pos["#{sector.id}-cm"]
    ,
      id: "#{sector.id}-non-cm",
      name: "Election Comittee Non-members from #{sector.name}"
      value: sector.count - data.election_comittee.seats_per_sector,
      hidden: true
    ]

  pop_data

# --- Misc Helpers --- #

# http://stackoverflow.com/questions/2259476/rotating-a-point-about-another-point-2d
rotate = (point, cpoint, angle) ->
  s = Math.sin(angle)
  c = Math.cos(angle)

  x = point.x - cpoint.x
  y = point.y - cpoint.y

  x: cpoint.x + x * c - y * s,
  y: cpoint.y + x * s + y * c

# http://bl.ocks.org/mbostock/7881887
collide = (alpha, force_data) ->
  alpha = alpha * 0.3
  quadtree = d3.geom.quadtree(force_data)
  (d) ->
    padding = 40
    r = d.r + padding
    nx1 = d.x - r
    nx2 = d.x + r
    ny1 = d.y - r
    ny2 = d.y + r
    quadtree.visit (quad, x1, y1, x2, y2) ->
      if quad.point and (quad.point isnt d) and !quad.point.no_collide
        x = d.x - quad.point.x
        y = d.y - quad.point.y
        l = Math.sqrt(x * x + y * y)
        r = d.r + quad.point.r + padding
        collide_factor = d.collide_factor or 1
        if l < r
          l = (l - r) / l * alpha * collide_factor
          d.x -= x *= l
          d.y -= y *= l
          quad.point.x += x
          quad.point.y += y
      x1 > nx2 or x2 < nx1 or y1 > ny2 or y2 < ny1

find_centroid = (pts) ->
  pts = pts.map (pt) -> [pt.x, pt.y]
  poly = d3.geom.polygon(pts)
  centroid = poly.centroid()

  x: centroid[0]
  y: centroid[1]

move_to = (original, target, t) ->
  x: d3.interpolate(original.x, target.x)(t)
  y: d3.interpolate(original.y, target.y)(t)

scale_to = (original_r, target_r, t) ->
  d3.interpolate(original_r, target_r)(t)

get_translate = (el) ->
  transform = d3.transform(el.getAttribute("transform"));

  x: transform.translate[0]
  y: transform.translate[1]

random = (min, max) -> Math.random() * (max - min) + min

# http://stackoverflow.com/questions/12034019/as3-draw-a-line-along-the-common-tangents-of-two-circles
# get_common_tangent = (point1, point2, radius1, radius2) ->
#   theta = Math.atan2(point2.y - point1.y, point2.x - point1.x)

#   line1_start = [
#     point1.x + Math.cos(theta + Math.PI / 2) * radius1
#     point1.y + Math.sin(theta + Math.PI / 2) * radius1
#   ]

#   line1_end = [
#     point2.x + Math.cos(theta + Math.PI / 2) * radius2
#     point2.y + Math.sin(theta + Math.PI / 2) * radius2
#   ]

#   line2_start = [
#     point1.x + Math.cos(theta - Math.PI / 2) * radius1
#     point1.y + Math.sin(theta - Math.PI / 2) * radius1
#   ]

#   line2_end = [
#     point2.x + Math.cos(theta - Math.PI / 2) * radius2
#     point2.y + Math.sin(theta - Math.PI / 2) * radius2
#   ]

#   [
#     [line1_start, line1_end]
#     [line2_start, line2_end]
#   ]

get_common_tangent = (p1, p2, r1, r2) ->
  dx = p2.x - p1.x
  dy = p2.y - p1.y
  dist = Math.sqrt(dx*dx + dy*dy)

  angle1 = Math.atan2(dy, dx)
  angle2 = Math.acos((r1 - r2)/dist)

  line1_start = [
    p1.x + r1 * Math.cos(angle1 + angle2)
    p1.y + r1 * Math.sin(angle1 + angle2)
  ]

  line1_end = [
    p2.x + r2 * Math.cos(angle1 + angle2)
    p2.y + r2 * Math.sin(angle1 + angle2)
  ]

  line2_start = [
    p1.x + r1 * Math.cos(angle1 - angle2)
    p1.y + r1 * Math.sin(angle1 - angle2)
  ]

  line2_end = [
    p2.x + r2 * Math.cos(angle1 - angle2)
    p2.y + r2 * Math.sin(angle1 - angle2)
  ]

  [
    [line1_start, line1_end]
    [line2_start, line2_end]
  ]

