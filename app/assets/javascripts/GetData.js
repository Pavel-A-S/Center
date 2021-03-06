// Main function which updates data on the page every X seconds
function getData(ports_parameters, url, location, ports_with_ranges) {

  // Parse ports with ranges
  var ports = JSON.parse(ports_with_ranges);

  // Send to and get data from the server at first time
  dataRequest(ports_parameters, null, url, location, null);

  // Create repeater for sending to and getting data from the server
  clearInterval(window.dataUpdateInterval);
  window.dataUpdateInterval = setInterval(
    function() {
      dataRequest(ports_parameters, null, url, location, ports);
    }, 5000);
}

// Main function which listens buttons
function trigger(ports_parameters, url, e, location, ports_with_ranges) {

  // Parse ports with ranges
  var ports = JSON.parse(ports_with_ranges);

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
    dataRequest(ports_parameters, button_id, url, location, ports);
  }
}

// Send data to the server
function dataRequest(ports_parameters, button_id, url, location,
                                                       ports_with_ranges) {
  var ports = ports_with_ranges;

  if (ports != null) {
    for (var i = 0; i < ports.length; i++) {
      ports[i][2] = $('#select_' + ports[i][0]).val();
    }
  }

  // Prepare message
  if (button_id != null) {
    var message = { 'command':'GetData',
                    'location':location,
                    'ports_parameters':ports_parameters,
                    'ports_with_ranges':ports,
                    'button_id':button_id }
  } else {
    var message = { 'command':'GetData',
                    'location':location,
                    'ports_parameters':ports_parameters,
                    'ports_with_ranges':ports }
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

      var accepted_for_danger_state = ['reed_switch',
                                       'motion_sensor',
                                       'temperature_sensor',
                                       'pressure_sensor',
                                       'leak_sensor',
                                       'smoke_sensor',
                                       'connection_checker'].indexOf(type)

      var accepted_for_success_state = ['switch', 'arming_switch'].indexOf(type)

//========================= Data for detailed page =============================

      if (location == 'page') {
        var disabled = 'panel-default';
        var info = 'panel-info';
        var danger = 'panel-danger';
        var warning = 'panel-warning';
        var success = 'panel-success';
        var target = $('#port_' + id).parent();

        if (type == 'temperature_sensor') {
          if (p.state == 7) {
            $('#port_' + id).text(p.temperature);
          } else {
            $('#port_' + id).text(p.temperature).append(' &deg;C');
          }
        } else if (common_port != -1) {
          $('#port_' + id).text(p.text);
        } else if (type == 'pressure_sensor') {
          $('#port_' + id).text(p.text);
        } else if (type == 'controller_raw_data') {
          $('#port_' + id).empty();
          var simpleHtml = "<div class='controller-raw-data-table'><table>" +
                           "<thead><tr><th>" +
                           p.ports_data[0].name +
                           '</th><th>' +
                           p.ports_data[0].state +
                           '</th><th>' +
                           p.ports_data[0].voltage +
                           '</th></tr></thead><tbody>';
          for (var z = 1; z < p.ports_data.length; z++) {
            simpleHtml = simpleHtml +
            '<tr><td>' +
            p.ports_data[z].name +
            "</td><td class='no-line-break'>" +
            p.ports_data[z].state +
            '</td><td>' +
            p.ports_data[z].voltage +
            '</td></tr>';
          }

          simpleHtml = simpleHtml + '</tbody></table></div>';
          $('#port_' + id).html(simpleHtml);
        } else if (type == 'switch' || type == 'arming_switch') {
          $('#port_' + id).text(p.text);
          $('#button_text_' + id).text(p.button_text);
        } else if (type == 'temperature_chart') {
          var a = MyChart(p.chart_data, id, p.text, p.axis_y_title);
        } else if (type == 'voltage_chart') {
          var a = MyChart(p.chart_data, id, p.text, p.axis_y_title);
        } else if (type == 'connection_checker') {
          $('#port_' + id).text(p.created_at);
        } else if (type == 'controller_log') {
          var selected_value = $('#select_' + id).val();
          $('#port_' + id).empty();
          var simpleHtml = "<div class='log_table'><table><thead><tr><th>" +
                           p.records[0].event_id +
                           '</th><th>' +
                           p.records[0].created_at +
                           '</th><th>' +
                           p.records[0].description +
                           '</th></tr></thead><tbody>';
          for (var z = 1; z < p.records.length; z++) {
            simpleHtml = simpleHtml +
            '<tr><td>' +
            p.records[z].event_id +
            "</td><td class='no-line-break'>" +
            p.records[z].created_at +
            '</td><td>' +
            p.records[z].description +
            '</td></tr>';
          }

          simpleHtml = simpleHtml + '</tbody></table></div>';
          $('#port_' + id).html(simpleHtml);

          simpleHtml = '<select id="select_' + id + '">' +
                       '<option value="5">5</option>' +
                       '<option value="10">10</option>' +
                       '<option value="30">30</option>' +
                       '<option value="60">60</option>' +
                       '<option value="100">100</option></select>';
          $("#port_" + id).append('<b>' + p.text + '</b>&nbsp;');
          $("#port_" + id).append(simpleHtml);
          if (selected_value != undefined) {
            $('#select_' + id).val(selected_value);
          }
        }

//======================== Data for main page ==================================
      } else if (location == 'user_index') {
        var target = $('#' + p.location_id + '_' + id);
        var disabled = 'port-disabled';
        var info = 'alert-info';
        var danger = 'alert-danger';
        var warning = 'alert-warning';
        var success = 'alert-success';

        if (type == 'temperature_sensor') {
          if (p.state == 7) {
            var title = p.temperature;
          } else {
            var title = p.temperature + " &deg;C";
          }
        } else if (type == 'temperature_chart') {
          var title = p.title;
        } else if (common_port != -1) {
          var title = p.text;
        } else if (type == 'switch' || type == 'arming_switch') {
          var title = p.text;
        } else if (type == 'connection_checker') {
          var title = target.attr('data-last-connection') + '<br>' +
                                                            p.created_at;
        } else if (type == 'controller_log') {
          var title = p.title;
        } else if (type == 'controller_raw_data') {
          var title = p.title;
        } else if (type == 'voltage_chart') {
          var title = p.title;
        } else if (type == 'pressure_sensor') {
          var title = p.text;
        }

        target.attr('data-original-title', title)
              .tooltip({ 'placement': 'bottom' });

        // Select panels for highlighting
        if ((p.color == 'danger' || p.state == 1) &&
          accepted_for_danger_state != -1 &&
          p.port_type != 'connection_checker') {

          if (danger_panels.indexOf(p.location_id) == -1) {
            danger_panels[i] = p.location_id;
          }

        } else if ((p.state == 0 || p.state == 7) &&
                  accepted_for_danger_state != -1) {

          if (info_panels.indexOf(p.location_id) == -1) {
            info_panels[i] = p.location_id;
          }
        }
      }

      // Change color of icons on the main page or color of panels on detail
      // page if state
      if (p.state == 1 && accepted_for_danger_state != -1) {
        target.removeClass(info).removeClass(warning).removeClass(disabled)
                                                     .addClass(danger);
      } else if (p.state == 1 && accepted_for_success_state != -1) {
        target.removeClass(info).removeClass(warning).removeClass(danger)
                                                     .removeClass(disabled)
                                                     .addClass(success);
      } else if (p.state == 0) {
        target.removeClass(danger).removeClass(warning).removeClass(success)
                                                       .removeClass(disabled)
                                                       .addClass(info);
      } else if (p.state == 7) {
        target.removeClass(danger).removeClass(warning).removeClass(success)
                                                       .removeClass(info)
                                                       .addClass(disabled);
      }

      // Change color of icons on the main page or color of panels on detail
      // page if timeout
      if ((p.state != 1 ||
          (p.state == 1 && accepted_for_success_state != -1)) &&
          p.color == 'warning') {
        target.removeClass(info).removeClass(danger).removeClass(disabled)
                                                    .addClass(warning);
      } else if (p.color == 'danger') {
        target.removeClass(info).removeClass(warning).removeClass(disabled)
                                                     .addClass(danger);
      } else if (p.color == 'grey') {
        target.removeClass(info).removeClass(warning).removeClass(danger)
                                                     .addClass(disabled);
      }
    }

    // Highlight panels on main page in normal state
    for (var i = 0; i < info_panels.length; i++) {
      $('#location_' + info_panels[i]).removeClass('panel-danger')
                                      .addClass('panel-info');
    }
    // Highlight panels on main page in alert state
    for (var i = 0; i < danger_panels.length; i++) {
      $('#location_' + danger_panels[i]).removeClass('panel-info')
                                        .addClass('panel-danger');
    }

    // Enable disabled button on detail page
    if (answer.button_id != 'no_buttons') {
      $('#button_' + answer.button_id).attr('data-status', 'nothing');
      $('#button_' + answer.button_id).attr('disabled', false);
    }
  }
}

function MyChart(answer, port_id, text, axis_y_title) {

  // Initialize variables for chart
  var margin = {top: 20, right: 20, bottom: 30, left: 50},
      width = 640 - margin.left - margin.right,
      height = 300 - margin.top - margin.bottom;

  var x = d3.scaleTime()
      .range([0, width]);

  var y = d3.scaleLinear()
      .range([height, 0]);

  var y_zoom = 2;
  var x_ticks = 5;

  // Set functions for ejecting input data
  var line = d3.line()
      .x(function(d) { return x(d[1]); })
      .y(function(d) { return y(d[0]); });

  // Select right function
  if (!$('#svg_chart_' + port_id).length) {
    createChart(answer, axis_y_title);
  } else {
    updateChart(answer);
  }

  // Function for creating chart
  function createChart(raw_data, axis_y_title) {

    $("#port_" + port_id).empty();

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
       .attr("class", "grid")
       .attr("transform", "translate(0," + height + ")")
       .call(d3.axisBottom(x).ticks(x_ticks).tickSize(-height).tickFormat(""));
    svg.append("g")
       .attr("class", "grid")
       .call(d3.axisLeft(y).tickSize(-width).tickFormat(""))

    svg.append("text")
       .attr("class", "axis-title")
       .attr("transform", "rotate(-90)")
       .attr("y", 6)
       .attr("dy", ".71em")
       .style("text-anchor", "end")
       .text(axis_y_title);
    svg.append("path")
       .datum(data)
       .attr("class", "line")
       .attr("d", line);

    svg.append("g")
       .attr("class", "axis axis--x")
       .attr("transform", "translate(0," + height + ")")
       .call(d3.axisBottom(x).ticks(x_ticks));
    svg.append("g")
       .attr("class", "axis axis--y")
       .call(d3.axisLeft(y))

    var simpleHtml = '<select id="select_' + port_id + '">' +
                     '<option value="1">1</option>' +
                     '<option value="2">2</option>' +
                     '<option value="3">3</option>' +
                     '<option value="4">4</option>' +
                     '<option value="5">5</option>' +
                     '<option value="6">6</option>' +
                     '<option value="7">7</option>' +
                     '<option value="8">8</option>' +
                     '<option value="9">9</option>' +
                     '<option value="10">10</option>' +
                     '<option value="11">11</option>' +
                     '<option value="12">12</option>' +
                     '<option value="13">13</option>' +
                     '<option value="14">14</option></select>';

    $("#port_" + port_id).append('<b>' + text + '</b>&nbsp;');
    $("#port_" + port_id).append(simpleHtml);
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
    svg.select('g.axis--x').call(d3.axisBottom(x).ticks(x_ticks));

    svg.select('.line').attr('d', line(data));
  }
}
