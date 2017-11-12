function fieldsSwitcher() {
  if ($('#port_type').val() == 'pressure_sensor') {
    $('#extra_port').attr('disabled', false);
  } else {
    $('#extra_port').attr('disabled', true);
  }
}
