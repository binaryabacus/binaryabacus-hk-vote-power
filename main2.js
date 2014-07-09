var min_size = 1;
var max_size = 300;
var circle_spacing = 50;
var circle_offsetY = 0;
var label_margin = 40;
var desc_margin = 20;
var cx_left = window.innerWidth / 2 - max_size - circle_spacing;
var cy = window.innerHeight / 2 - max_size - circle_offsetY;
var cx_right = window.innerWidth / 2 + max_size + circle_spacing;
var label_y = cy + max_size+ label_margin;
var desc_x = window.innerWidth / 2;
var desc_y = label_y + desc_margin;
var si_format = d3.format('.3s');

var circle_fill = '#f4f4f4';
var stroke_fill = '#DDDBDB';

var first_desc = 'If you are a <strong>registered voter</strong> under universal suffarage, you have the <strong>same</strong> voting power than anyone else';

var body = d3.select('body');
var svg = d3.select('svg');
var force_g_offsetX = 100;
var force_g_offsetY = 200;
var pack_g_offsetX = 450;
var pack_g_offsetY = 200;
var force_g = svg.append('g').attr('transform', 'translate(' + force_g_offsetX + ',' + force_g_offsetY + ')');
var pack_g = svg.append('g').attr('transform', 'translate(' + pack_g_offsetX + ',' + pack_g_offsetY + ')');
var container = d3.select('.container');

d3.json('data.json', function draw (err, data) {
  // var pop_scale = d3.scale.pow().exponent(0.25).domain([0, data.registered_voter]).range([min_size, max_size]);
  var pop_scale = d3.scale.sqrt().domain([0, data.registered_voter]).range([min_size, max_size]);
  // var power_scale = d3.scale.sqrt().domain([0, 355]).range([max_size, min_size]);
  var power_scale = d3.scale.linear().domain([0, max_size]).range([max_size, min_size]);

  var pack_root = {
    id: 'all',
    name: 'Registered Voter',
    value: data.registered_voter,
    label: { stage1: { size: 'big' } },
    children: [
      {
        id: 'non-voters',
        name: 'Non-voters',
        value: data.registered_voter - data.election_comittee.voter,
      }, {
        id: 'ec-voters',
        name: 'Voters for Election Comittee',
        value: data.election_comittee.voter,
        children: []
      }
    ]
  };

  pack_root.children[1].children = data.election_comittee.sectors.map(function (sector) {
    return {
      id: sector.id,
      name: sector.name,
      value: sector.count,
      children: [
        {
          id: sector.id + '-cm',
          name: 'Voted-in Election Comittee Members from ' + sector.name,
          value: data.election_comittee.seats_per_sector,
        }, {
          id: sector.id + '-non-cm',
          name: 'Election Comittee Non-members from ' + sector.name,
          value: sector.count - data.election_comittee.seats_per_sector,
          hidden: true
        }
      ]
    };
  });

  var label_styles = {
    'stage1': [
      { id: 'all', size: 'big', fill: true, position: 'fit' },
    ],
    'stage2': [
      { id: 'non-voters', size: 'big', fill: false, position: 'fit' },
      { id: 'ec-voters', size: 'big', fill: true, position: 'fit' },
    ],
    'stage3': [
      { id: 'non-voters', size: 'big' },
      { id: 'sector-ftit', size: 'small', position: { x: 100, y: 100 } },
      { id: 'sector-ehil', size: 'small', position: { x: 100, y: 100 } },
      { id: 'sector-lrw', size: 'small', position: { x: 100, y: 100 } },
      { id: 'sector-hkcpb', size: 'small', position: { x: 100, y: 100 } },
    ],
    'stage4': [
      { id: 'sector-ftit-cm', size: 'small', position: { x: 100, y: 100 }, pointer: false }
    ]
  };

  var pack = d3.layout.pack()
    // .size([window.innerWidth, window.innerHeight])
    .size([max_size, max_size])
    // .value(function(d) { return pop_scale(d.value); })
    // .value(function(d) { return d.value; })
    // .radius(Math.sqrt)
    // .radius(function (d) { return d.value; })
    // .radius(Math.sqrt)
    // .radius(100)

  var pack_node = pack.nodes(pack_root).filter(function (d) { return !d.hidden; });

  var node = pack_g.datum(pack_root).selectAll('.pack.node')
    .data(pack_node)
    .enter().append('g')
      .attr('transform', function(d) {
        var cpoint = { x: max_size / 2, y: max_size / 2 };
        var pt = rotate(d, cpoint, -Math.PI / 2);
        d.pack_x = pt.x;
        d.pack_y = pt.y;
        return 'translate(' + d.pack_x + ',' + d.pack_y + ')';
      })
      .attr('class', function(d) { return d.children ? 'pack node' : 'pack leaf node'; })
      .attr('data-id', function (d) { return d.id; })

  node.append('circle')
    .attr('r', function (d) { return d.r; });

  // node.filter(function (d) { return d.label !== 'none'; }).append('text')
  //   .attr('class', 'label')
  //   .text(function (d) { return d.name; })
  //   .call(wrap, 100)
  //   .each(function (d) {
  //     var width = this.offsetWidth;
  //     var circleWidth = d3.select(this.parentNode.querySelector('circle')).attr('r');

  //     if (width > circleWidth) {
  //       d.label_overflow = true;
  //     }
  //   })
  //   .style('opacity', function (d) {
  //     // TODO external labeling
  //     return d.label_overflow ? 0 : 1;
  //   });

  var pack_labels = container.selectAll('.pack.label').data(pack_node)
    .enter().append('div')
      .attr('class', function (d) { return 'pack label'; })
      .attr('id', function (d) { return 'label-' + d.id; })
      .style('top', function (d) { return pack_g_offsetY + d.pack_y - d.r; })
      .style('left', function (d) { return pack_g_offsetX + d.pack_x - d.r; })
      .style('width', function (d) { return d.r * 2; })
      .style('height', function (d) { return d.r * 2; })
  pack_labels.append('p')
    .html(function (d) {
      return '<strong>' + d.name + '</strong> ' + vote_power(d.value) + 'x'; 
    });

  // var force_data = [].concat(pack_root).concat(pack_root.children);
  var force_data = [].concat(pack_root);
  var force = d3.layout.force()
    .nodes(force_data)
    .links([])
    .size([max_size, max_size])
    .charge(function (d) { return -20 * power_scale(d.r); })

  var force_node = force_g.selectAll('.force.node').data(force_data)
    .enter().append('g')
      .attr('transform', function(d) {
        return 'translate(' + d.x + ',' + d.y + ')';
      })
      .attr('id', function (d) { return 'power-' + d.id; })
  force_node.append('circle')
    .attr('r', function (d) { return power_scale(d.r); })

  force.start();
  force.on('tick', function (e) {
    force_node.attr('transform', function(d) {
      return 'translate(' + d.x + ',' + d.y + ')';
    });
  });

  function update (stage) {
    body.attr('class', stage);
  }

  update('stage1');

  // window.pack = pack;
  // window.pack_root = pack_root;

  function vote_power_scaled (d, total) {
    return power_scale(vote_power(d, total));
  }

  function vote_power (d, total) {
    total = total || data.registered_voter;
    return d3.format('.0f')(total / d);
  }
});

// http://stackoverflow.com/questions/2259476/rotating-a-point-about-another-point-2d
function rotate (point, cpoint, angle) {
  var s = Math.sin(angle);
  var c = Math.cos(angle);

  var x = point.x - cpoint.x;
  var y = point.y - cpoint.y;

  return {
    x: cpoint.x + x * c - y * s,
    y: cpoint.y + x * s + y * c,
  };
}

// http://bl.ocks.org/mbostock/7555321
function wrap(text, width) {
  text.each(function() {
    var text = d3.select(this);
    var words = text.text().split(/\s+/).reverse();
    var word;
    var line = [];
    var lineNumber = 0;
    var lineHeight = 1.1; // em
    var x = text.attr('x') || 0;
    var y = text.attr('y') || 0;
    var dy = parseFloat(text.attr('dy')) || 0;
    var tspan = text.text(null).append('tspan').attr('x', x).attr('y', y).attr('dy', dy + 'em');
    while (word = words.pop()) {
      line.push(word);
      tspan.text(line.join(' '));
      if (tspan.node().getComputedTextLength() > width) {
        line.pop();
        tspan.text(line.join(' '));
        line = [word];
        tspan = text.append('tspan').attr('x', x).attr('y', y).attr('dy', ++lineNumber * lineHeight + dy + 'em').text(word);
      }
    }
  });
}
