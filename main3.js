// Generated by CoffeeScript 1.7.1
(function() {
  var body, collide, debug, find_centroid, force_g, force_g_offsetX, force_g_offsetY, get_common_tangent, get_translate, init_pop_data, init_power_data, label_container, log, max_size, min_size, move_to, pack_g, pack_g_offsetX, pack_g_offsetY, pop_format, power_format, power_scale, random, rotate, scale_to, svg;

  debug = true;

  log = debug ? console.log.bind(console) : function() {};

  min_size = 1;

  max_size = 300;

  force_g_offsetX = 100;

  force_g_offsetY = 200;

  pack_g_offsetX = 600;

  pack_g_offsetY = 200;

  pop_format = d3.format(".3s");

  power_format = d3.format(".0f");

  power_scale = d3.scale.pow().exponent(0.25).domain([0, 3000]).range([min_size, max_size / 3]);

  body = d3.select("body");

  svg = d3.select("svg");

  force_g = svg.append("g").attr("transform", "translate(" + force_g_offsetX + ", " + force_g_offsetY + ")");

  pack_g = svg.append("g").attr("transform", "translate(" + pack_g_offsetX + ", " + pack_g_offsetY + ")");

  label_container = d3.select(".container").append("div").attr("class", "label-container");

  d3.json("data.json", function(err, data) {
    var active_force_label, active_force_node, active_pack_label, active_pack_node, cur_depth, cur_stage, first_run, force, force_data, force_labels, force_nodes, hide_link, last_force_data, next, pack, pack_data, pack_nodes, pop_data, pop_label_links, pop_label_links_data, pop_labels, power_data, prev, show_link, transitioning, update, update_active_links, update_force_node, update_mouse_binding, update_pack_node;
    power_data = init_power_data(data);
    pop_data = init_pop_data(data);
    log(power_data);
    log(pop_data);
    pack = d3.layout.pack().size([max_size, max_size]);
    pack_data = pack.nodes(pop_data).filter(function(d) {
      return !d.hidden;
    }).reverse();
    pack_g.datum(pack_data);
    pack_nodes = pack_g.selectAll(".pack.node").data(pack_data).enter().append("g").attr("transform", function(d) {
      var cpoint, pt;
      cpoint = {
        x: max_size / 2,
        y: max_size / 2
      };
      pt = rotate(d, cpoint, -Math.PI / 2);
      d.pack_x = pt.x;
      d.pack_y = pt.y;
      return "translate(" + d.pack_x + ", " + d.pack_y + ")";
    }).attr("id", function(d) {
      return "pack-" + d.id;
    }).attr("class", function(d) {
      return "pack node " + d.id;
    });
    pack_nodes.append("circle").attr("r", function(d) {
      return d.r;
    });
    pop_labels = label_container.selectAll(".pack.label").data(pack_data).enter().append("div").attr("class", function(d) {
      return "pack label " + d.id;
    }).attr("id", function(d) {
      return "label-" + d.id;
    }).style("top", function(d) {
      return d.label_top = pack_g_offsetY + d.pack_y - d.r;
    }).style("left", function(d) {
      return d.label_left = pack_g_offsetX + d.pack_x - d.r;
    }).style("width", function(d) {
      return d.label_width = d.r * 2;
    }).style("height", function(d) {
      return d.label_height = d.r * 2;
    });
    pop_labels.append("p").html(function(d) {
      return "<strong>" + d.name + "</strong> " + (pop_format(d.value));
    });
    pop_label_links_data = pack_data.filter(function(d) {
      return d.label_pos;
    });
    pop_label_links = pack_g.selectAll("line.label-link").data(pop_label_links_data).enter().append("line").attr("class", "label-link").attr("x1", function(d) {
      return d.pack_x;
    }).attr("y1", function(d) {
      return d.pack_y;
    }).attr("x2", function(d) {
      var offset;
      offset = d.label_pos.x > 0 ? 0 : 100;
      return d.label_left + d.label_pos.x - pack_g_offsetX + offset;
    }).attr("y2", function(d) {
      return d.label_top + d.label_pos.y - pack_g_offsetY + 100 / 2;
    });
    force_data = [];
    last_force_data = force_data;
    force_nodes = force_g.selectAll(".force.node").data(force_data, function(d) {
      return d.id;
    });
    force_labels = label_container.selectAll(".power.label").data(force_data);
    force = d3.layout.force().gravity(0.05).size([300, 300]).charge(0).friction(0.3).on("tick", function(e) {
      force_nodes.each(collide(e.alpha, force_data)).attr("transform", function(d) {
        return "translate(" + d.x + ", " + d.y + ")";
      });
      return force_labels.style("transform", function(d) {
        var width_offset;
        width_offset = parseFloat(this.style.width) === 100 ? -50 + d.r : 0;
        d.force_x = d.x + force_g_offsetX - d.r + width_offset;
        d.force_y = d.y + force_g_offsetY - d.r;
        return "translate3d(" + d.force_x + "px, " + d.force_y + "px, 0px)";
      });
    });
    update_force_node = function() {
      var enter_nodes;
      force_nodes = force_g.selectAll(".force.node").data(force_data, function(d) {
        return d.id;
      });
      force_nodes.select("circle").transition().duration(1000).tween('force_r', function(d) {
        var i;
        console.log("changed", d.id);
        i = d3.interpolate(this.getAttribute("r") || 0, power_scale(d.value));
        return function(t) {
          d.r = i(t);
          return this.setAttribute("r", d.r);
        };
      });
      enter_nodes = force_nodes.enter().append("g").attr("class", "force node");
      enter_nodes.transition().duration(1000).tween("force_translate_enter", function(d) {
        var circle, enter_link_nodes, i_r, original_r, random_x, random_y, target, target_r;
        enter_link_nodes = last_force_data.filter(function(e) {
          var _ref;
          return ((_ref = d.enter) != null ? _ref.indexOf(e.id) : void 0) >= 0;
        });
        circle = d3.select(this).select("circle");
        target = enter_link_nodes[0];
        original_r = (target != null ? target.r : void 0) || 0;
        if (target) {
          random_x = random(-5, 5);
          random_y = random(-5, 5);
          d.px = target.px + random_x;
          d.py = target.py + random_y;
          d.x = target.x + random_x;
          d.y = target.y + random_y;
        }
        target_r = power_scale(d.value);
        i_r = d3.interpolate(original_r, target_r);
        d3.select(this).attr("transform", "translate(" + d.x + ", " + d.y + ")");
        return function(t) {
          d.r = i_r(t);
          d.collide_factor = t > 0.9 ? 1 : d3.scale.sqrt()(t);
          return circle.attr("r", d.r);
        };
      });
      enter_nodes.append("circle").attr("id", function(d) {
        return d.id;
      });
      force_nodes.exit().transition().duration(1000).tween("force_translate_exit", function(d) {
        var circle, exit_link_nodes, original, original_r, target;
        console.log("removed", d.id);
        exit_link_nodes = force_data.filter(function(e) {
          var _ref;
          return ((_ref = d.exit) != null ? _ref.indexOf(e.id) : void 0) >= 0;
        });
        target = exit_link_nodes[0];
        original = get_translate(this);
        circle = d3.select(this).select('circle');
        original_r = circle.attr("r");
        return function(t) {
          var pos;
          if (target) {
            pos = move_to(original, target, t);
            this.setAttribute("transform", "translate(" + pos.x + ", " + pos.y + ")");
          }
          return circle.attr("r", scale_to(original_r, (target != null ? target.r : void 0) || 0, t));
        };
      }).each("end", function() {
        return this.remove();
      });
      force_labels = label_container.selectAll(".power.label").data(force_data, function(d) {
        return d.id;
      });
      force_labels.attr("class", function(d) {
        return "power label " + d.id;
      }).attr("id", function(d) {
        return "label-" + d.id;
      }).style("width", function(d) {
        return Math.max(power_scale(d.value) * 2, 100);
      }).style("height", function(d) {
        return power_scale(d.value) * 2;
      }).select("p").html(function(d) {
        return "<strong>" + d.name + "</strong> " + (power_format(d.value)) + "x";
      }).style("opacity", 0).transition().duration(1000).style("opacity", 1);
      force_labels.enter().append("div").attr("class", function(d) {
        return "power label " + d.id;
      }).attr("id", function(d) {
        return "label-" + d.id;
      }).style("width", function(d) {
        return Math.max(power_scale(d.value) * 2, 100);
      }).style("height", function(d) {
        return power_scale(d.value) * 2;
      }).append("p").html(function(d) {
        return "<strong>" + d.name + "</strong> " + (power_format(d.value)) + "x";
      }).style("opacity", 0).transition().delay(first_run ? 0 : 500).duration(1000).style("opacity", 1);
      force_labels.exit().transition().duration(250).style("opacity", 0).each("end", function() {
        return this.remove();
      });
      force.nodes(force_data).start();
      return force_nodes.call(force.drag);
    };
    update_pack_node = function(depth) {
      pack_nodes.filter(function(d) {
        return d.depth === depth;
      }).classed("no-fill", false);
      pack_nodes.filter(function(d) {
        return d.depth !== depth;
      }).classed("no-fill", true);
      pop_labels.classed("hidden", true).filter(function(d) {
        return d.depth === depth || (depth >= 2 && d.id === "others");
      }).classed("hidden", false);
      pop_label_links.style("opacity", 0).filter(function(d) {
        return d.depth === depth;
      }).transition().duration(1000).style("opacity", 1);
      return pop_labels.filter(function(d) {
        return d.depth === depth && d.label_pos;
      }).style("width", 100).style("height", 100).style("top", function(d) {
        return d.label_top + d.label_pos.y;
      }).style("left", function(d) {
        return d.label_left + d.label_pos.x;
      });
    };
    show_link = function(pack_node, force_node) {
      body.classed("highlighted", true);
      if (!(typeof active_force_node !== "undefined" && active_force_node !== null ? active_force_node.size() : void 0) || !(typeof active_pack_node !== "undefined" && active_pack_node !== null ? active_pack_node.size() : void 0)) {
        return;
      }
      active_pack_node.classed("active", true);
      active_force_node.classed("active", true);
      active_force_label.classed("active", true);
      return active_pack_label.classed("active", true);
    };
    hide_link = function() {
      body.classed("highlighted", false);
      if (!(typeof active_force_node !== "undefined" && active_force_node !== null ? active_force_node.size() : void 0) || !(typeof active_pack_node !== "undefined" && active_pack_node !== null ? active_pack_node.size() : void 0)) {
        return;
      }
      active_pack_node.classed("active", false);
      active_force_node.classed("active", false);
      active_force_label.classed("active", false);
      return active_pack_label.classed("active", false);
    };
    active_pack_node = null;
    active_force_node = null;
    active_force_label = null;
    active_pack_label = null;
    update_active_links = function() {
      var active_links, point1, point2, radius1, radius2, tangents;
      if (!(active_force_node != null ? active_force_node.size() : void 0) || !(active_pack_node != null ? active_pack_node.size() : void 0)) {
        return;
      }
      point1 = {
        x: active_force_node.datum().x + force_g_offsetX,
        y: active_force_node.datum().y + force_g_offsetY
      };
      point2 = {
        x: active_pack_node.datum().pack_x + pack_g_offsetX,
        y: active_pack_node.datum().pack_y + pack_g_offsetY
      };
      radius1 = active_force_node.datum().r;
      radius2 = active_pack_node.datum().r;
      tangents = get_common_tangent(point1, point2, radius1, radius2);
      active_links = svg.selectAll("line.active-link").data(tangents).attr("x1", function(d) {
        return d[0][0];
      }).attr("y1", function(d) {
        return d[0][1];
      }).attr("x2", function(d) {
        return d[1][0];
      }).attr("y2", function(d) {
        return d[1][1];
      });
      active_links.enter().append("line").attr("class", "active-link").attr("x1", function(d) {
        return d[0][0];
      }).attr("y1", function(d) {
        return d[0][1];
      }).attr("x2", function(d) {
        return d[1][0];
      }).attr("y2", function(d) {
        return d[1][1];
      });
      return active_links.exit().remove();
    };
    force.on("tick.update-active-link", update_active_links);
    update_mouse_binding = function(depth) {
      pack_nodes.on("mousemove", function() {
        var pack_node_name;
        active_pack_node = d3.select(this);
        pack_node_name = active_pack_node.datum().name;
        active_force_node = force_nodes.filter(function(d) {
          return d.name === pack_node_name;
        });
        active_force_label = force_labels.filter(function(d) {
          return d.name === pack_node_name;
        });
        active_pack_label = pop_labels.filter(function(d) {
          return d.name === pack_node_name;
        });
        if ((active_pack_node != null ? active_pack_node.size() : void 0) && (active_force_node != null ? active_force_node.size() : void 0)) {
          show_link();
          return update_active_links();
        }
      }).on("mouseout", function() {
        hide_link();
        return active_force_node = active_pack_node = active_force_label = active_pack_label = null;
      });
      return force_nodes.on("mousemove", function() {
        var force_node_name;
        active_force_node = d3.select(this);
        force_node_name = active_force_node.datum().name;
        active_pack_node = pack_nodes.filter(function(d) {
          return d.name === force_node_name;
        });
        active_force_label = force_labels.filter(function(d) {
          return d.name === force_node_name;
        });
        active_pack_label = pop_labels.filter(function(d) {
          return d.name === force_node_name;
        });
        if ((active_pack_node != null ? active_pack_node.size() : void 0) && (active_force_node != null ? active_force_node.size() : void 0)) {
          show_link();
          return update_active_links();
        }
      }).on("mouseout", function() {
        hide_link();
        return active_force_node = active_pack_node = active_force_label = active_pack_label = null;
      });
    };
    cur_stage = "";
    cur_depth = 0;
    first_run = true;
    transitioning = false;
    update = function(stage, depth) {
      if (stage === cur_stage) {
        return;
      }
      if (transitioning) {
        return;
      }
      force_data = power_data[stage];
      last_force_data = power_data[cur_stage] || [];
      if (last_force_data) {
        force_data.forEach(function(d) {
          var match_nodes;
          match_nodes = last_force_data.filter(function(e) {
            return d.id === e.id;
          });
          return match_nodes.forEach(function(e) {
            d.x = e.x;
            d.px = e.px;
            d.y = e.y;
            return d.py = e.py;
          });
        });
      }
      update_force_node();
      update_pack_node(depth);
      update_mouse_binding(depth);
      cur_stage = stage;
      cur_depth = depth;
      log(cur_stage, cur_depth);
      first_run = false;
      transitioning = true;
      return setTimeout(function() {
        return transitioning = false;
      }, 1250);
    };
    update("stage1", 0);
    next = function() {
      if (cur_depth >= 3) {
        return;
      }
      return update("stage" + (cur_depth + 2), cur_depth + 1);
    };
    prev = function() {
      if (cur_depth <= 0) {
        return;
      }
      return update("stage" + cur_depth, cur_depth - 1);
    };
    d3.select("button#stage1").on("click", function() {
      return update("stage1", 0);
    });
    d3.select("button#stage2").on("click", function() {
      return update("stage2", 1);
    });
    d3.select("button#stage3").on("click", function() {
      return update("stage3", 2);
    });
    d3.select("button#stage4").on("click", function() {
      return update("stage4", 3);
    });
    d3.select("button#next").on("click", next);
    return d3.select("button#prev").on("click", prev);
  });

  init_power_data = function(data) {
    var ec_voter, ec_voter_power, nodes, power_data, sectors_length, stage_name;
    ec_voter = data.election_comittee.voter;
    ec_voter_power = data.registered_voter / ec_voter;
    sectors_length = data.election_comittee.sectors.length;
    power_data = {
      stage1: [
        {
          id: "all",
          name: "Registered Voters",
          value: 1
        }
      ],
      stage2: [
        {
          id: "all",
          name: "Others",
          value: 0
        }, {
          id: "ec-voters",
          name: "Voters for Election Comittee",
          value: data.registered_voter / ec_voter
        }
      ],
      stage3: [
        {
          id: "all",
          name: "Others",
          value: 0
        }
      ],
      stage4: [
        {
          id: "all",
          name: "Others",
          value: 0
        }
      ]
    };
    data.election_comittee.sectors.forEach(function(sector) {
      power_data.stage3.push({
        id: sector.id,
        name: sector.name,
        value: (ec_voter / sectors_length) / sector.count * ec_voter_power,
        exit: ["ec-voters"],
        enter: ["ec-voters"]
      });
      return power_data.stage4.push({
        id: sector.id,
        name: "Voted-in Election Comittee Members from " + sector.name,
        value: data.registered_voter / (data.election_comittee.seats_per_sector * sectors_length)
      });
    });
    for (stage_name in power_data) {
      nodes = power_data[stage_name];
      nodes.forEach(function(d) {
        return d.r = power_scale(d.value);
      });
    }
    return power_data;
  };

  init_pop_data = function(data) {
    var ec_voter, label_pos, pop_data;
    ec_voter = data.election_comittee.voter;
    label_pos = {
      "sector-lrw": {
        x: -120,
        y: -50
      },
      "sector-fhit": {
        x: -110,
        y: -20
      },
      "sector-hkcpb": {
        x: -130,
        y: 20
      },
      "sector-ehil": {
        x: 85,
        y: 10
      },
      "sector-lrw-cm": {
        x: -130,
        y: -125
      },
      "sector-fhit-cm": {
        x: -130,
        y: -70
      },
      "sector-hkcpb-cm": {
        x: -120,
        y: 10
      },
      "sector-ehil-cm": {
        x: 65,
        y: -45
      }
    };
    pop_data = {
      id: "all",
      name: "Registered Voters",
      value: data.registered_voter,
      children: [
        {
          id: "others",
          name: "Others",
          value: data.registered_voter - ec_voter
        }, {
          id: "ec-voters",
          name: "Voters for Election Comittee",
          value: ec_voter,
          children: []
        }
      ]
    };
    pop_data.children[1].children = data.election_comittee.sectors.map(function(sector) {
      return {
        id: sector.id,
        name: sector.name,
        value: sector.count,
        label_pos: label_pos[sector.id],
        children: [
          {
            id: "" + sector.id + "-cm",
            name: "Voted-in Election Comittee Members from " + sector.name,
            value: data.election_comittee.seats_per_sector,
            label_pos: label_pos["" + sector.id + "-cm"]
          }, {
            id: "" + sector.id + "-non-cm",
            name: "Election Comittee Non-members from " + sector.name,
            value: sector.count - data.election_comittee.seats_per_sector,
            hidden: true
          }
        ]
      };
    });
    return pop_data;
  };

  rotate = function(point, cpoint, angle) {
    var c, s, x, y;
    s = Math.sin(angle);
    c = Math.cos(angle);
    x = point.x - cpoint.x;
    y = point.y - cpoint.y;
    return {
      x: cpoint.x + x * c - y * s,
      y: cpoint.y + x * s + y * c
    };
  };

  collide = function(alpha, force_data) {
    var quadtree;
    alpha = alpha * 0.3;
    quadtree = d3.geom.quadtree(force_data);
    return function(d) {
      var nx1, nx2, ny1, ny2, padding, r;
      padding = 40;
      r = d.r + padding;
      nx1 = d.x - r;
      nx2 = d.x + r;
      ny1 = d.y - r;
      ny2 = d.y + r;
      return quadtree.visit(function(quad, x1, y1, x2, y2) {
        var collide_factor, l, x, y;
        if (quad.point && (quad.point !== d) && !quad.point.no_collide) {
          x = d.x - quad.point.x;
          y = d.y - quad.point.y;
          l = Math.sqrt(x * x + y * y);
          r = d.r + quad.point.r + padding;
          collide_factor = d.collide_factor || 1;
          if (l < r) {
            l = (l - r) / l * alpha * collide_factor;
            d.x -= x *= l;
            d.y -= y *= l;
            quad.point.x += x;
            quad.point.y += y;
          }
        }
        return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1;
      });
    };
  };

  find_centroid = function(pts) {
    var centroid, poly;
    pts = pts.map(function(pt) {
      return [pt.x, pt.y];
    });
    poly = d3.geom.polygon(pts);
    centroid = poly.centroid();
    return {
      x: centroid[0],
      y: centroid[1]
    };
  };

  move_to = function(original, target, t) {
    return {
      x: d3.interpolate(original.x, target.x)(t),
      y: d3.interpolate(original.y, target.y)(t)
    };
  };

  scale_to = function(original_r, target_r, t) {
    return d3.interpolate(original_r, target_r)(t);
  };

  get_translate = function(el) {
    var transform;
    transform = d3.transform(el.getAttribute("transform"));
    return {
      x: transform.translate[0],
      y: transform.translate[1]
    };
  };

  random = function(min, max) {
    return Math.random() * (max - min) + min;
  };

  get_common_tangent = function(p1, p2, r1, r2) {
    var angle1, angle2, dist, dx, dy, line1_end, line1_start, line2_end, line2_start;
    dx = p2.x - p1.x;
    dy = p2.y - p1.y;
    dist = Math.sqrt(dx * dx + dy * dy);
    angle1 = Math.atan2(dy, dx);
    angle2 = Math.acos((r1 - r2) / dist);
    line1_start = [p1.x + r1 * Math.cos(angle1 + angle2), p1.y + r1 * Math.sin(angle1 + angle2)];
    line1_end = [p2.x + r2 * Math.cos(angle1 + angle2), p2.y + r2 * Math.sin(angle1 + angle2)];
    line2_start = [p1.x + r1 * Math.cos(angle1 - angle2), p1.y + r1 * Math.sin(angle1 - angle2)];
    line2_end = [p2.x + r2 * Math.cos(angle1 - angle2), p2.y + r2 * Math.sin(angle1 - angle2)];
    return [[line1_start, line1_end], [line2_start, line2_end]];
  };

}).call(this);

//# sourceMappingURL=main3.map
