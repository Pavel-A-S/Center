// Main function which updates data on the page every X seconds
function getData(ports_parameters, url) {

  // Send to and get data from the server at first time
  dataRequest(ports_parameters, null, url);

  // Create repeater for sending to and getting data from the server
  if (typeof dataUpdateInterval === 'undefined' ||
             dataUpdateInterval === null) {
    window.dataUpdateInterval = setInterval(function() {
                                              dataRequest(ports_parameters,
                                                          null, url);
                                            }, 5000);
  }
}

// Main function which listens buttons
function trigger(ports_parameters, url, e) {

  // Determine pressed element
  var button_id = 'undefined';
  if ($(e.target).hasClass('port_button')) {
    var button_id = e.target.id;
  } else if ($(e.target).hasClass('port_button_glyphicon')) {
    var button_id = $(e.target).parent().attr('id');
  }

  // If button is pressed
  if (button_id != 'undefined') {

    // Disable pressed button
    $('#' + button_id).attr('disabled', true);
    $('#' + button_id).attr('data-status', 'ready');

    // Eject input information
    var data = JSON.parse(ports_parameters);
    var button_ids = [];

    // Select all buttons
    for (var i = 0; i < data.length; i++) {
      if (data[i].port_type == 'switch') {
        button_ids.push(['button_' + data[i].port_id, data[i].port_id]);
      }
    }

    // Select pressed buttons
    var selected_buttons = [];
    for (var i = 0; i < button_ids.length; i++) {
      if ($('#' + button_ids[i][0]).attr('disabled') == 'disabled' &&
          $('#' + button_ids[i][0]).attr('data-status') == 'ready') {

        selected_buttons.push(button_ids[i][1]);

        $('#' + button_ids[i][0]).attr('data-status', 'await');
      }
    }

    // Send data to the server
    dataRequest(ports_parameters, selected_buttons, url);
  }
}

// Send data to the server
function dataRequest(ports_parameters, buttons, url) {

  if (buttons === null) {
    var selected_buttons = [];
  } else {
    var selected_buttons = buttons;
  }

  // Prepare message
  if (selected_buttons.length > 0) {
    var message = { 'command':'GetData',
                    'ports_parameters':ports_parameters,
                    'selected_buttons':JSON.stringify(selected_buttons) }
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
      mapData(answer);
    },
    timeout: 50000
  });
}

// Distribute gathered information from the server on the page
function mapData(answer) {

  if (answer.ports_parameters != undefined) {

    // Distribute information depend on a port type
    for (var i = 0; i < answer.ports_parameters.length; i++) {
      var p = answer.ports_parameters[i];
      if (p.port_type == 'temperature_sensor') {
        $('#port_' + p.port_id).text(p.temperature).append(' &deg;C');
      } else if (p.port_type == 'reed_switch') {
        $('#port_' + p.port_id).text(p.text);
      } else if (p.port_type == 'motion_sensor') {
        $('#port_' + p.port_id).text(p.text);
      } else if (p.port_type == 'leak_sensor') {
        $('#port_' + p.port_id).text(p.text);
      } else if (p.port_type == 'switch') {
        $('#port_' + p.port_id).text(p.text);
        $('#button_text_' + p.port_id).text(p.button_text);
      } else if (p.port_type == 'temperature_chart') {
        var a = MyChart(p.chart_data, p.port_id);
      } else if (p.port_type == 'connection_checker') {
        $('#port_' + p.port_id).text(p.created_at);
        if (p.state == 1) {
          $('#port_' + p.port_id).parent().removeClass('panel-info')
                                          .addClass('panel-danger');
        } else {
          $('#port_' + p.port_id).parent().removeClass('panel-danger')
                                          .addClass('panel-info');
        }
      }
    }

    // Enable disabled button
    if (answer.selected_buttons != 'no_buttons') {
      for (var i = 0; i < answer.selected_buttons.length; i++) {
        $('#button_' + answer.selected_buttons[i]).attr('data-status',
                                                        'nothing');
        $('#button_' + answer.selected_buttons[i]).attr('disabled', false);
      }
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
    var svg = d3.select("#port_" + port_id).append("svg")
        .attr("class", "center_chart")
        .attr("id", "svg_chart_" + port_id)
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

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
