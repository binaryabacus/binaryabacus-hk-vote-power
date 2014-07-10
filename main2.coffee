body = d3.select("body")
svg = d3.select("svg")

min_size = 1
max_size = 300

circle_fill = "#f4f4f4"
stroke_fill = "#DDDBDB"

# desc_x = window.innerWidth / 2
# desc_y = label_y + desc_margin
force_g_offsetX = 100
force_g_offsetY = 200
pack_g_offsetX = 450
pack_g_offsetY = 200

pop_format = d3.format(".3s")
power_scale = d3.scale.pow().exponent(0.25).domain([0, 3000]).range([min_size, max_size / 2])

power_format = d3.format(".0f")

force_g = svg.append("g")
  .attr("transform", "translate(#{ force_g_offsetX }, #{ force_g_offsetY })")
pack_g = svg.append("g")
  .attr("transform", "translate(#{ pack_g_offsetX }, #{ pack_g_offsetY })")
label_container = d3.select(".container")
  .append("div").attr("class", "label-container")

d3.json("data.json", (err, data) ->
  ec_voter = data.election_comittee.voter
  ec_voter_power = data.registered_voter / ec_voter
  sectors_length = data.election_comittee.sectors.length

  pack_root = {
    id: "all"
    name: "Registered Voter"
    value: data.registered_voter
    power: 1
    children: [
      {
        id: "others"
        name: "Others"
        value: data.registered_voter - ec_voter
        power: 0
      }, {
        id: "ec-voters",
        name: "Voters for Election Comittee"
        value: ec_voter
        power: ec_voter_power
        children: []
      }
    ]
  }

  pack_root.children[1].children = data.election_comittee.sectors.map((sector) ->
    return {
      id: sector.id
      name: sector.name
      value: sector.count
      power: (ec_voter / sectors_length) / sector.count * ec_voter_power
      children: [
        {
          id: "#{sector.id}-cm"
          name: "Voted-in Election Comittee Members from #{sector.name}"
          # name: "Voted-in Election Comittee Members"
          value: data.election_comittee.seats_per_sector
          power: data.registered_voter / (data.election_comittee.seats_per_sector * sectors_length)
        }, {
          id: "#{sector.id}-non-cm",
          name: "Election Comittee Non-members from #{sector.name}"
          value: sector.count - data.election_comittee.seats_per_sector
          power: 0
        }
      ]
    }
  )

  stage_style = {
    "stage1": [
      { id: "all", size: "big", fill: true, pop_label: "fit", power: true }
    ],
    "stage2": [
      { id: "all", size: "big", fill: false, pop_label: false, power: false }
      { id: "others", size: "big", fill: false, pop_label: "fit", power: true }
      { id: "ec-voters", size: "big", fill: true, pop_label: "fit", power: true }
    ],
    "stage3": [
      { id: "all", size: "big", fill: false, pop_label: false }
      { id: "others", size: "big", fill: false, pop_label: "fit", power: true }
      { id: "ec-voters", size: "big", fill: false, pop_label: false }
      { id: "sector-lrw", size: "small", pop_label: { x: -120, y: -45 }, fill: true, power: true }
      { id: "sector-hkcpb", size: "small", pop_label: { x: -145, y: -15 }, fill: true, power: true }
      { id: "sector-ftit", size: "small", pop_label: { x: -110, y: 35 }, fill: true, power: true }
      { id: "sector-ehil", size: "small", pop_label: { x: 85, y: 10 }, fill: true, power: true }

      { id: "sector-lrw-cm", size: "small", pop_label: false }
      { id: "sector-hkcpb-cm", size: "small", pop_label: false }
      { id: "sector-ftit-cm", size: "small", pop_label: false }
      { id: "sector-ehil-cm", size: "small", pop_label: false }
    ],
    "stage4": [
      { id: "all", size: "big", fill: false, pop_label: false }
      { id: "others", size: "big", fill: false, pop_label: false, power: true }
      { id: "ec-voters", size: "big", fill: false, pop_label: false }
      { id: "sector-lrw", size: "small", pop_label: false, fill: false }
      { id: "sector-hkcpb", size: "small", pop_label: false, fill: false }
      { id: "sector-ftit", size: "small", pop_label: false, fill: false }
      { id: "sector-ehil", size: "small", pop_label: false, fill: false }
      # cm
      { id: "sector-lrw-cm", size: "small", pop_label: { x: -130, y: -125 }, power: true }
      { id: "sector-hkcpb-cm", size: "small", pop_label: { x: -145, y: -55 } }
      { id: "sector-ftit-cm", size: "small", pop_label: { x: -120, y: -5 } }
      { id: "sector-ehil-cm", size: "small", pop_label: { x: 65, y: -45 } }
    ]
  }

  pack_g.datum(pack_root)
  pack = d3.layout.pack()
    .size([max_size, max_size])

  pack_data = pack.nodes(pack_root).filter((d) -> return !d.hidden )

  pop_nodes = pack_g.selectAll(".pop.node").data(pack_data)
    .enter().append("g")
      .attr("transform", (d) ->
        cpoint = { x: max_size / 2, y: max_size / 2 }
        pt = rotate(d, cpoint, -Math.PI / 2)
        d.pack_x = pt.x
        d.pack_y = pt.y
        return "translate(#{d.pack_x}, #{d.pack_y})"
      )
      .attr("id", (d) -> "pop-#{d.id}")
      .attr("class", (d) -> "pop node #{d.id}")

  pop_nodes.append("circle")
    .attr("r", (d) -> return d.r)

  pop_labels = label_container.selectAll(".pack.label").data(pack_data)
    .enter().append("div")
      .attr("class", (d) -> "pack label #{d.id}")
      .attr("id", (d) -> "label-#{d.id}")
      .style("top", (d) -> d.label_top = pack_g_offsetY + d.pack_y - d.r)
      .style("left", (d) -> d.label_left = pack_g_offsetX + d.pack_x - d.r)
      .style("width", (d) -> d.label_width = d.r * 2)
      .style("height", (d) -> d.label_height = d.r * 2)

  pop_labels.append("p")
    .html((d) -> "<strong>#{d.name}</strong> #{pop_format(d.value)}")

  force_data = []
  force_nodes = force_g.selectAll(".force.node").data(force_data)
  window.force = force = d3.layout.force()
    .links([])
    .size([300, 300])
    .charge((d) -> -15 * d.force_r )
    .on("tick", (e) ->
      force_nodes.attr("transform", (d) -> "translate(#{d.x}, #{d.y})")
      force_labels.style("-webkit-transform", (d) -> "translate3d(#{d.x + force_g_offsetX - d.force_r}px, #{d.y + force_g_offsetY - d.force_r}px, 0px)")
    )

  force_labels = label_container.selectAll(".power.label").data(force_data)

  window.update = update = (stage) ->
    styles = stage_style[stage]
    body.attr("class", stage)

    pop_nodes.style("opacity", 0)
    pop_labels.style("opacity", 0)
    d3.selectAll(".label-link").remove()

    force_data = []

    styles.forEach (style) ->
      data = pack_data.filter (d) -> d.id is style.id and style.power
      if data.length
        data[0].style = style
        force_data.push(data[0])

      pop_nodes.filter (d) -> d.id is style.id
        .style("opacity", 1)
        .selectAll("circle")
        .style("fill", (d) -> if style.fill then null else "#FDFDFD")

      pop_labels.filter (d) -> d.id is style.id
        .style("width", (d) ->
          d.label_width = if typeof style.pop_label is "object" then 100 else d.label_width
        ).style("top", (d) ->
          if typeof style.pop_label is "object"
            d.label_top + style.pop_label.y
          else
            d.label_top
        ).style("left", (d) ->
          if typeof style.pop_label is "object"
            d.label_left + style.pop_label.x
          else
            d.label_left
        )
        .transition().duration(500)
          .style("opacity", (d) -> if style.pop_label then 1 else 0)

      if typeof style.pop_label is "object"
        pop_labels.filter (d) -> d.id is style.id
          .each((d) ->
            label_height = parseFloat(d3.select(this).style("height"))
            pack_g.append("line").datum(d)
              .attr("class", "label-link" )
              .attr("x1", (d) -> d.pack_x )
              .attr("y1", (d) -> d.pack_y )
              .attr("x2", (d) ->
                offset = if style.pop_label.x > 0 then -5 else d.label_width + 5
                d.label_left + style.pop_label.x - pack_g_offsetX + offset )
              .attr("y2", (d) -> d.label_top + style.pop_label.y - pack_g_offsetY + label_height / 2 )
        )

    others = pack_root.children[1]
    all = pack_root
    { x: othersx, y: othersy } = others
    { x: allx, y: ally } = all
    all.x = all.px = othersx
    all.y = all.py = othersy
    others.x = others.px = allx
    others.y = others.py = ally

    force_nodes = force_nodes.data(force_data, (d) ->
      # HACK: for transitioning all into others and others into all
      if d.id is "all"
        "others"
      else
        d.id )
    force_nodes.attr("transform", (d) -> "translate(#{d.x}, #{d.y})")
      .select("circle").transition().duration(500)
        .attr("r", (d) -> d.force_r = power_scale(d.power) )
    force_nodes.exit().remove()
    force_nodes.enter().append("g")
      .each((d) ->
        # d.px = d.x += Math.random() * 50 - 25
        # d.py = d.y += Math.random() * 50 - 25
        delete d.px
        delete d.py
        delete d.x
        delete d.y)
      # .attr("transform", (d) -> "translate(#{d.x}, #{d.y})")
      .attr("id", (d) -> "power-#{d.id}"; )
        .append("circle")
          # .attr("r", 0)
          # .transition().duration(500)
          .attr("r", (d) -> d.force_r = power_scale(d.power) )

    force_labels.remove()
    force_labels = label_container.selectAll(".power.label").data(force_data)
    force_labels.enter().append("div")
      .attr("class", (d) -> "power label #{d.id}")
      .attr("id", (d) -> "label-#{d.id}")
      .style("width", (d) -> d.force_r * 2)
      .style("height", (d) -> d.force_r * 2)
      .append("p")
        .html((d) ->
          "<strong>#{d.name}</strong> #{(power_format(d.power))}x")

    force.nodes(force_data).start()

  update("stage4")

  d3.select("button#stage1").on "click", -> update("stage1")
  d3.select("button#stage2").on "click", -> update("stage2")
  d3.select("button#stage3").on "click", -> update("stage3")
  d3.select("button#stage4").on "click", -> update("stage4")
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
