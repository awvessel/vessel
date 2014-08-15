var ipc = require('ipc');
$(function() {

  var $alert = $('.alert');
  var $input = $('input');

  $('button').on('click', function(e) {
    e.preventDefault();
    value = $input.val();
    if (value.length > 0) {
      $alert.addClass('hidden');
      ipc.send('setURL', value);
    } else {
      $alert.removeClass('hidden');
    }
  });

});
