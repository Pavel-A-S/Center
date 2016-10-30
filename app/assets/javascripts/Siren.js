function siren(url, text, audio) {

  // Send to and get data from the server at first time
  dataRequest(url);

  // Create repeater for sending to and getting data from the server
  clearInterval(window.sirenUpdateInterval);
  window.sirenUpdateInterval = setInterval(function() {
                                            dataRequest(url);
                                          }, 5000);

  // Send data to the server
  function dataRequest(url) {

    // Send request to the server
    $.ajax({
      type: "POST",
      url: url,
      data: JSON.stringify({ 'command':'GetState' }),
      contentType: 'application/json; charset=utf-8',
      dataType: 'json',
      async: true,
      success: function(answer) {
        mapData(answer);
      },
      timeout: 50000
    });
  }

  function mapData(answer) {
    if (answer.state == true && !$('#siren_state').hasClass('siren_on')) {
      $('#siren_state').addClass('siren_on');
      $('#siren_state').text(text);
      $('#siren_state').append(audio);
    } else if (answer.state == false) {
      $('#siren_state').removeClass('siren_on');
      $('#siren_state').empty();
    }
  }
}
