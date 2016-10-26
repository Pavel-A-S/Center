// Main function which updates data on the page every X seconds
function getData(ports_parameters, url, location) {

  // Send to and get data from the server at first time
  dataRequest(ports_parameters, null, url, location);

  // Create repeater for sending to and getting data from the server
//  if (typeof dataUpdateInterval === 'undefined' ||
//             dataUpdateInterval === null) {
    clearInterval(window.dataUpdateInterval);
    window.dataUpdateInterval = setInterval(function() {
                                              dataRequest(ports_parameters,
                                                          null,
                                                          url,
                                                          location);
                                            }, 5000);
  }
//}

// Main function which listens buttons
function trigger(ports_parameters, url, e, location) {

  // Determine pressed element
  var button_id = 'undefined';
  if ($(e.target).hasClass('port_button')) {
    var button_id = e.target.id;
  } else if ($(e.target).hasClass('port_button_glyphicon')) {
    var button_id = $(e.target).parent().attr('id');
  } else if ($(e.target).hasClass('port_button_text')) {
    var button_id = $(e.target).parent().attr('id');
  }

  // If button is pressed
  if (button_id != 'undefined') {

    // Disable pressed button
    $('#' + button_id).attr('disabled', true);
    $('#' + button_id).attr('data-status', 'await');

    // Send data to the server
    dataRequest(ports_parameters, button_id, url, location);
  }
}

// Send data to the server
function dataRequest(ports_parameters, button_id, url, location) {

  // Prepare message
  if (button_id != null) {
    var message = { 'command':'GetData',
                    'ports_parameters':ports_parameters,
                    'button_id':button_id }
  } else {
    var message = { 'command':'GetData', 'ports_parameters':ports_parameters }
  }

  // Send request to the server
  $.ajax({
    type: "POST",
    url: url,
    data: JSON.stringify(message),
    contentType: 'application/json; charset=utf-8',
    dataType: 'json',
    async: true,
    success: function(answer) {
      mapData(answer, location);
    },
    timeout: 50000
  });
}

// Distribute gathered information from the server on the page
function mapData(answer, location) {

  if (answer.ports_parameters != undefined) {

    // For main panels highlighting
    var danger_panels = [];
    var info_panels = [];

    // Distribute information depend on a port type
    for (var i = 0; i < answer.ports_parameters.length; i++) {
      var p = answer.ports_parameters[i];
      var id = p.port_id;
      var type = p.port_type;

      var common_port = ['reed_switch',
                         'motion_sensor',
                         'smoke_sensor',
                         'leak_sensor'].indexOf(type)

      if (location == 'page') {
        var info = 'panel-info';
        var danger = 'panel-danger';
        var warning = 'panel-warning';
        var success = 'panel-success';
        var target = $('#port_' + id).parent();

        if (type == 'temperature_sensor') {
          $('#port_' + id).text(p.temperature).append(' &deg;C');
        } else if (common_port != -1) {
          $('#port_' + id).text(p.text);
        } else if (type == 'switch' || type == 'arming_switch') {
          $('#port_' + id).text(p.text);
          $('#button_text_' + id).text(p.button_text);
        } else if (type == 'temperature_chart') {
          var a = MyChart(p.chart_data, id);
        } else if (type == 'connection_checker') {
          $('#port_' + id).text(p.created_at);
        }

      } else if (location == 'user_index') {
        var target = $('#' + p.location_id + '_' + id);
        var info = 'alert-info';
        var danger = 'alert-danger';
        var warning = 'alert-warning';
        var success = 'alert-success';
      }

      var accepted_for_danger_state = ['reed_switch',
                                       'motion_sensor',
                                       'temperature_sensor',
                                       'leak_sensor',
                                       'smoke_sensor',
                                       'connection_checker'].indexOf(type)

      var accepted_for_success_state = ['switch', 'arming_switch'].indexOf(type)

      // Select panels for highlighting
      if ((p.color == 'danger' || p.state == 1) &&
          accepted_for_danger_state != -1 && p.type != 'connection_checker') {
        if (danger_panels.indexOf(p.location_id) == -1) {
          danger_panels[i] = p.location_id;
        }
      } else if (p.state == 0 && accepted_for_danger_state != -1) {
        if (info_panels.indexOf(p.location_id) == -1) {
          info_panels[i] = p.location_id;
        }
      }

      // Change color
      if (p.state == 1 && accepted_for_danger_state != -1) {
        target.removeClass(info).removeClass(warning).addClass(danger);
      } else if (p.state == 1 && accepted_for_success_state != -1) {
        target.removeClass(info).removeClass(warning).addClass(success);
      } else if (p.state == 0 && accepted_for_danger_state != -1) {
        target.removeClass(danger).removeClass(warning).addClass(info);
      } else if (p.state == 0 && accepted_for_success_state != -1) {
        target.removeClass(success).removeClass(warning).addClass(info);
      }

      // Change color if timeout
      if ((p.state != 1 ||
          (p.state == 1 && accepted_for_success_state != -1)) &&
          p.color == 'warning') {
        target.removeClass(info).removeClass(danger).addClass(warning);
      } else if (p.color == 'danger') {
        target.removeClass(info).removeClass(warning).addClass(danger);
      }
    }

    // Highlight panels in normal state
    for (var i = 0; i < info_panels.length; i++) {
      $('#location_' + info_panels[i]).removeClass('panel-danger')
                                      .addClass('panel-info');
    }
    // Highlight panels in alert state
    for (var i = 0; i < danger_panels.length; i++) {
      $('#location_' + danger_panels[i]).removeClass('panel-info')
                                        .addClass('panel-danger');
    }

    // Enable disabled button
    if (answer.button_id != 'no_buttons') {
      $('#button_' + answer.button_id).attr('data-status', 'nothing');
      $('#button_' + answer.button_id).attr('disabled', false);
    }
  }
}

function MyChart(answer, port_id) {

  // Initialize variables for chart
  var margin = {top: 20, right: 20, bottom: 30, left: 50},
      width = 640 - margin.left - margin.right,
      height = 300 - margin.top - margin.bottom;

  var x = d3.scaleTime()
      .range([0, width]);

  var y = d3.scaleLinear()
      .range([height, 0]);

  var y_zoom = 2;

  // Set functions for ejecting input data
  var line = d3.line()
      .x(function(d) { return x(d[1]); })
      .y(function(d) { return y(d[0]); });

  // Select right function
  if (!$('#svg_chart_' + port_id).length) {
    createChart(answer);
  } else {
    updateChart(answer);
  }

  // Function for creating chart
  function createChart(raw_data) {

    // Append chart to div
    var svg = d3.select("#port_" + port_id)
                .append("svg")
                .attr("class", "center_chart")
                .attr("id", "svg_chart_" + port_id)
                .attr("width", width + margin.left + margin.right)
                .attr("height", height + margin.top + margin.bottom)
                .append("g")
                .attr("transform", "translate(" + margin.left + "," + margin.top
                                                                    + ")");

    // Prepare data from json
    var data = raw_data;
    for (var i = 0; i<data.length; i++) {
      data[i][1] = new Date(data[i][1]);
    }

    // Prepare scales
    x.domain(d3.extent(data, function(d) { return d[1]; }));
    value = d3.extent(data, function(d) { return d[0]; });
    y.domain([value[0] - y_zoom, value[1] + y_zoom]);

    // Set data
    svg.append("g")
       .attr("class", "axis axis--x")
       .attr("transform", "translate(0," + height + ")")
       .call(d3.axisBottom(x));
    svg.append("g")
       .attr("class", "axis axis--y")
       .call(d3.axisLeft(y))
    svg.append("text")
       .attr("class", "axis-title")
       .attr("transform", "rotate(-90)")
       .attr("y", 6)
       .attr("dy", ".71em")
       .style("text-anchor", "end")
       .text("Temperature");
    svg.append("path")
       .datum(data)
       .attr("class", "line")
       .attr("d", line);
  }

  // Function for updating existing chart
  function updateChart(raw_data) {

    // Select chart
    var svg = d3.select('svg#svg_chart_' + port_id);

    // Prepare data from json
    var data = raw_data;
    for (var i = 0; i<data.length; i++) {
      data[i][1] = new Date(data[i][1]);
    }

    // Prepare scales
    x.domain(d3.extent(data, function(d) { return d[1]; }));
    value = d3.extent(data, function(d) { return d[0]; });
    y.domain([value[0] - y_zoom, value[1] + y_zoom]);

    // Update data
    svg.select('g.axis--y').call(d3.axisLeft(y));
    svg.select('g.axis--x').call(d3.axisBottom(x));
    svg.select('.line').attr('d', line(data));
  }
}
