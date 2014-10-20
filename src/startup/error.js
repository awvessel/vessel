var ipc = require('ipc');
$(function() {
  $('.message').html(document.location.hash.substring(1));
  $('[data-dismiss="window"]').click(function(event){
    ipc.send('app:quit', 'error');
  });
});
