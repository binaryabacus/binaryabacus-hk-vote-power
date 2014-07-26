debug = true
log = if debug then console.log.bind(console) else () ->

min_size = 1
max_size = 300

force_g_offsetX = 100
force_g_offsetY = 200
pack_g_offsetX = 600
pack_g_offsetY = 200

power_scale = d3.scale.pow().exponent(0.25)
  .domain([0, 3000])
  .range([min_size, max_size / 3])

body= d3.select("body")
svg = d3.select("svg")

force_g = svg.append("g")
  .attr("transform", "translate(#{ force_g_offsetX }, #{ force_g_offsetY })")
pack_g = svg.append("g")
  .attr("transform", "translate(#{ pack_g_offsetX }, #{ pack_g_offsetY })")

d3.json "data.json", (err, data) ->
  power_data = init_power_data data
  pop_data = init_pop_data data

  log power_data
  log pop_data

  pack = d3.layout.pack()
    .size [max_size, max_size]
  pack_data = pack.nodes(pop_data).filter (d) -> !d.hidden

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

  force_data = []
  force_nodes = force_g.selectAll(".force.node").data(force_data, (d) -> d.id)
  force = d3.layout.force()
    .gravity 0.05
    .size [300, 300]
    .charge 0
    .on "tick", (e) ->
      force_nodes
        .each collide(e.alpha, force_data)
        .attr "transform", (d) -> "translate(#{d.x}, #{d.y})"
      # force_labels.style "-webkit-transform", (d) ->
      #   width_offset = if parseFloat this.style.width is 100 then -50 + d.force_r else 0
      #   x = d.x + force_g_offsetX - d.force_r + width_offset
      #   y = d.y + force_g_offsetY - d.force_r
      #   "translate3d(#{x}px, #{y}px, 0px)"

  update_force_node = () ->
    force_nodes = force_g.selectAll(".force.node").data(force_data)
    force_nodes.transition().duration(1000).select("circle")
      .attr "r", (d) -> power_scale d.value
    force_nodes.enter().append("g")
      .attr "class", "force node"
      .append("circle")
        .attr "r", 0
        .attr "id", (d) -> d.id
        # TODO: tween value instead
        .transition().duration(1000)
          .attr "r", (d) -> d.r
    force_nodes.exit().select("circle")
      .transition().duration(1000)
        .attr "r", 0
      .each "end", () -> this.parentNode.remove()

    force
      .nodes(force_data)
      .start()

  cur_stage = ""
  update = (stage) ->
    return if stage is cur_stage
    cur_stage = stage
    log cur_stage

    # TODO ec-voters should "split" into four nodes
    force_data = power_data[cur_stage]
    update_force_node()

  update "stage1"

  d3.select("button#stage1").on "click", -> update("stage1")
  d3.select("button#stage2").on "click", -> update("stage2")
  d3.select("button#stage3").on "click", -> update("stage3")
  d3.select("button#stage4").on "click", -> update("stage4")

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

  pop_data = {
    id: "all"
    name: "Registered Voter"
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
    children: [
      id: "#{sector.id}-cm"
      name: "Voted-in Election Comittee Members from #{sector.name}"
      # name: "Voted-in Election Comittee Members"
      value: data.election_comittee.seats_per_sector
    ,
      id: "#{sector.id}-non-cm",
      name: "Election Comittee Non-members from #{sector.name}"
      value: sector.count - data.election_comittee.seats_per_sector,
      hidden: true
    ]

  pop_data


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
  alpha = alpha * 0.25
  debugger
  quadtree = d3.geom.quadtree(force_data)
  (d) ->
    padding = 20
    r = d.r + padding
    nx1 = d.x - r
    nx2 = d.x + r
    ny1 = d.y - r
    ny2 = d.y + r
    quadtree.visit (quad, x1, y1, x2, y2) ->
      if quad.point and (quad.point isnt d)
        debugger
        x = d.x - quad.point.x
        y = d.y - quad.point.y
        l = Math.sqrt(x * x + y * y)
        r = d.r + quad.point.r + padding
        if l < r
          l = (l - r) / l * alpha
          d.x -= x *= l
          d.y -= y *= l
          quad.point.x += x
          quad.point.y += y
      x1 > nx2 or x2 < nx1 or y1 > ny2 or y2 < ny1
