var min_size = 2;
var max_size = 140;
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

var svg = d3.select('svg');
var container = d3.select('.container');

d3.json('data.json', function draw (err, data) {
  var pop_scale = d3.scale.sqrt().domain([0, data.registered_voter]).range([min_size, max_size]);
  var power_scale = d3.scale.sqrt().domain([0, 355]).range([max_size, min_size]);

  var power_label = svg.append('text')
    .html('Relative Voting Power')
    .attr('class', 'circle-label')
    .attr('x', cx_left)
    .attr('y', label_y);

  var pop_label = svg.append('text')
    .html('Population')
    .attr('class', 'circle-label')
    .attr('x', cx_right)
    .attr('y', label_y);

  // var description = body.append('text')
  //   .html(first_desc)
  //   .attr('class', 'description')
  //   .attr('x', desc_x)
  //   .attr('y', desc_y)
  //   .call(wrap, 260);

  var description = container
    .append('div')
      .attr('class', 'description')
      .style('top', desc_y)
    .append('p')
      .html(first_desc)
      .attr('class', 'description');

  // registered voter
  var power_base = svg.append('circle').datum(data.registered_voter)
    .attr('r', function (d) { return pop_scale(d); })
    .attr('cx', cx_left)
    .attr('cy', cy);

  var pop_base = svg.append('circle').datum(data.registered_voter)
    .attr('r', function (d) { return pop_scale(d); })
    .attr('cx', cx_right)
    .attr('cy', cy);

  var power_base_label = svg.append('text').datum(data.registered_voter).attr('x', cx_left).attr('y', cy)
  power_base_label.append('tspan').attr('class', 'strong').text('Registered Voter ')
  power_base_label.append('tspan').attr('class', 'details').text(function (d) { return '(' + vote_power(d) + 'x)'; })

  var pop_base_label = svg.append('text').datum(data.registered_voter).attr('x', cx_right).attr('y', cy)
  pop_base_label.append('tspan').attr('class', 'strong').text('Registered Voter ')
  pop_base_label.append('tspan').attr('class', 'details').text(function (d) { return '(' + si_format(d) + ')'; })

  setTimeout(stage2, 500);

  function stage2 () {
    var ec_voters_pop = svg.append('circle').datum(data.election_comittee.voter)
      .attr('r', function (d) { return pop_scale(data.registered_voter); })
      .attr('cx', cx_right)
      .attr('cy', function (d) { return cy; })
      // .attr('cy', function (d) { return cy + pop_scale(data.registered_voter) - pop_scale(d); })
      .style('opacity', 0);

    ec_voters_pop
      .transition().duration(500).delay(1)
        .attr('r', function (d) { return pop_scale(d); })
        .style('opacity', 1)
      .transition('bounce').duration(500).delay(750).ease('bounce')
        .attr('cy', function (d) { return cy + pop_scale(data.registered_voter) - pop_scale(d); })
        .each('end', stage2_label);

    pop_base.transition().duration(500)
      .style('fill-opacity', 0);

    power_base.transition().duration(500)
      .attr('r', min_size)
      .attr('cx', cx_left - max_size)
      .attr('cy', cy - max_size)

    power_base_label.select('tspan.details').text('(0x)');
    power_base_label.select('tspan.strong').text('Others ');
    power_base_label.transition().duration(500)
      .attr('x', cx_left - max_size)
      .attr('y', cy - max_size - 20)

    var power_ec_voter = svg.append('circle').datum(data.election_comittee.voter)
      .attr('r', 0)
      .attr('cx', cx_left)
      .attr('cy', cy)
      .transition().duration(500)
        .attr('r', function (d) { return vote_power_scaled(d); })
  }

  function stage2_label () {
    // debugger;
    var pop_ec_voter_label = svg.append('text').datum(data.registered_voter)
      .attr('x', cx_right).attr('y', cy)
    pop_ec_voter_label.style('opacity', 0)
      .transition().style('opacity', 1)
    pop_ec_voter_label.append('tspan').attr('class', 'strong').text('Voter for Election Comittee ')
    pop_ec_voter_label.append('tspan').attr('class', 'details').text(function (d) { return '(' + si_format(d) + ')'; })

    var power_ec_voter_label = svg.append('text').datum(data.registered_voter)
      .attr('x', cx_left).attr('y', cy)
    pop_ec_voter_label.style('opacity', 0)
      .transition().style('opacity', 1)
    power_ec_voter_label.append('tspan').attr('class', 'strong').text('Voter for Election Comittee ')
    power_ec_voter_label.append('tspan').attr('class', 'details').text(function (d) { return '(' + vote_power(d) + 'x)'; })
  }

  function vote_power_scaled (d, total) {
    return power_scale(vote_power(d, total));
  }

  function vote_power (d, total) {
    total = total || data.registered_voter;
    return d3.format('.0f')(total / d);
  }
});

// http://bl.ocks.org/mbostock/7555321
function wrap(text, width) {
  text.each(function() {
    var text = d3.select(this);
    var words = text.text().split(/\s+/).reverse();
    var word;
    var line = [];
    var lineNumber = 0;
    var lineHeight = 1.1; // em
    var y = text.attr('y');
    var x = text.attr('x');
    var dy = parseFloat(text.attr('dy')) || 0;
    var tspan = text.text(null).append('tspan')
      .attr('x', x)
      .attr('y', y)
      .attr('dy', dy + 'em');
    while (word = words.pop()) {
      line.push(word);
      tspan.text(line.join(' '));
      if (tspan.node().getComputedTextLength() > width) {
        line.pop();
        tspan.text(line.join(' '));
        line = [word];
        tspan = text.append('tspan')
          .attr('x', x)
          .attr('y', y)
          .attr('dy', ++lineNumber * lineHeight + dy + 'em')
          .text(word);
      }
    }
  });
}
