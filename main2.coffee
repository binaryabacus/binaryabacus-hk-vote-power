min_size = 1
max_size = 300
circle_spacing = 50
circle_offsetY = 0
label_margin = 40
desc_margin = 20
cx_left = window.innerWidth / 2 - max_size - circle_spacing
cy = window.innerHeight / 2 - max_size - circle_offsetY
cx_right = window.innerWidth / 2 + max_size + circle_spacing
label_y = cy + max_size+ label_margin
desc_x = window.innerWidth / 2
desc_y = label_y + desc_margin
si_format = d3.format(".3s")

circle_fill = "#f4f4f4"
stroke_fill = "#DDDBDB"

first_desc = "If you are a <strong>registered voter</strong> under
  universal suffarage, you have the <strong>same</strong> voting
  power than anyone else"

body = d3.select("body")
svg = d3.select("svg")
force_g_offsetX = 100
force_g_offsetY = 200
pack_g_offsetX = 450
pack_g_offsetY = 200
force_g = svg.append("g")
  .attr("transform", "translate(#{ force_g_offsetX }, #{ force_g_offsetY })")
pack_g = svg.append("g")
  .attr("transform", "translate(#{ pack_g_offsetX }, #{ pack_g_offsetY })")
label_container = d3.select(".container")
  .append("div").attr("class", "label-container")

d3.json("data.json", (err, data) ->
  pop_scale = d3.scale.sqrt().domain([0, data.registered_voter]).range([min_size, max_size])
  power_scale = d3.scale.linear().domain([0, max_size]).range([max_size, min_size])

  vote_power_scaled = (d, total) -> power_scale(vote_power(d, total))

  vote_power = (d, total = data.registered_voter) ->
    d3.format(".0f")(total / d)

  pack_root = {
    id: "all",
    name: "Registered Voter",
    value: data.registered_voter,
    label: { stage1: { size: "big" } },
    children: [
      {
        id: "non-voters",
        name: "Non-voters",
        value: data.registered_voter - data.election_comittee.voter,
      }, {
        id: "ec-voters",
        name: "Voters for Election Comittee",
        value: data.election_comittee.voter,
        children: []
      }
    ]
  }

  pack_root.children[1].children = data.election_comittee.sectors.map((sector) ->
    return {
      id: sector.id,
      name: sector.name,
      value: sector.count,
      children: [
        {
          id: "#{sector.id}-cm",
          name: "Voted-in Election Comittee Members from #{sector.name}",
          value: data.election_comittee.seats_per_sector,
        }, {
          id: "#{sector.id}-non-cm",
          name: "Election Comittee Non-members from #{sector.name}",
          value: sector.count - data.election_comittee.seats_per_sector,
          hidden: true
        }
      ]
    }
  )

  stage_style = {
    "stage1": [
      { id: "all", size: "big", fill: true, label_position: "fit" }
    ],
    "stage2": [
      { id: "all", size: "big", fill: false, label_position: "fit" }
      { id: "non-voters", size: "big", fill: false, label_position: "fit" }
      { id: "ec-voters", size: "big", fill: true, label_position: "fit" }
    ],
    "stage3": [
      { id: "non-voters", size: "big", fill: false }
      { id: "ec-voters", size: "big", fill: true, label_position: "fit" }
      { id: "sector-ftit", size: "small", label_position: { x: 100, y: 100 }, fill: true }
      { id: "sector-ehil", size: "small", label_position: { x: 100, y: 100 }, fill: true }
      { id: "sector-lrw", size: "small", label_position: { x: 100, y: 100 }, fill: true }
      { id: "sector-hkcpb", size: "small", label_position: { x: 100, y: 100 }, fill: true }
    ],
    "stage4": [
      { id: "sector-ftit-cm", size: "small", label_position: { x: 100, y: 100 }, pointer: false }
    ]
  }

  pack_g.datum(pack_root)
  pack = d3.layout.pack()
    .size([max_size, max_size])

  pack_data = pack.nodes(pack_root).filter((d) -> return !d.hidden )

  pack_node = pack_g.selectAll(".pack.node").data(pack_data)
    .enter().append("g")
      .attr("transform", (d) ->
        cpoint = { x: max_size / 2, y: max_size / 2 }
        pt = rotate(d, cpoint, -Math.PI / 2)
        d.pack_x = pt.x
        d.pack_y = pt.y
        return "translate(#{d.pack_x}, #{d.pack_y})"
      )
      .attr("class", (d) -> "pack node #{d.id}")

  pack_node.append("circle")
    .attr("r", (d) -> return d.r)

  pack_label = label_container.selectAll(".pack.label").data(pack_data)
    .enter().append("div")
      .attr("class", (d) -> "pack label #{d.id}")
      .attr("id", (d) -> "label-#{d.id}")
      .style("top", (d) -> pack_g_offsetY + d.pack_y - d.r)
      .style("left", (d) -> pack_g_offsetX + d.pack_x - d.r)
      .style("width", (d) -> d.r * 2)
      .style("height", (d) -> d.r * 2)

  pack_label.append("p")
    .html((d) -> "<strong>#{d.name}</strong> #{vote_power(d.value)}x")

  force_data = []
  force_node = force_g.selectAll(".force.node").data(force_data)
  force = d3.layout.force()
    .links([])
    .size([max_size, max_size])
    .charge((d) -> return -20 * power_scale(d.r) )

  force.on("tick", (e) ->
    force_node.attr("transform", (d) -> "translate(#{d.x}, #{d.y})")
  )

  update = (stage) ->
    styles = stage_style[stage]
    body.attr("class", stage)

    styles.forEach (style) ->
      pack_node.filter (d) -> d.id is style.id
        .style "opacity", 1

      pack_label.filter (d) -> d.id is style.id
        .style "opacity", 1

      force_data = pack_data.filter (d) -> d.id is style.id
      force_node = force_g.selectAll(".force.node").data(force_data)
      force_node.exit().remove()
      force_node.enter().append("g")
          .attr("transform", (d) -> "translate(#{d.x}, #{d.y})")
          .attr("id", (d) -> "power-#{d.id}"; )
            .append("circle")
              .attr("r", (d) -> power_scale(d.r) )

      force.start()

  update("stage2")
)

# http://stackoverflow.com/questions/2259476/rotating-a-point-about-another-point-2d
rotate = (point, cpoint, angle) ->
  s = Math.sin(angle)
  c = Math.cos(angle)

  x = point.x - cpoint.x
  y = point.y - cpoint.y

  x: cpoint.x + x * c - y * s,
  y: cpoint.y + x * s + y * c

# http://bl.ocks.org/mbostock/7555321
wrap = (text, width) ->
  text.each( ->
    text = d3.select(this)
    words = text.text().split(/\s+/).reverse()
    word
    line = []
    lineNumber = 0
    lineHeight = 1.1 # em
    x = text.attr("x") || 0
    y = text.attr("y") || 0
    dy = parseFloat(text.attr("dy")) || 0
    tspan = text.text(null).append("tspan")
      .attr("x", x).attr("y", y).attr("dy", dy + "em")
    while (word = words.pop())
      line.push(word)
      tspan.text(line.join(" "))
      if (tspan.node().getComputedTextLength() > width)
        line.pop()
        tspan.text(line.join(" "))
        line = [word]
        tspan = text.append("tspan")
          .attr("x", x).attr("y", y)
          .attr("dy", ++lineNumber * lineHeight + dy + "em")
          .text(word)
  )
