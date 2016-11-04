function tablefilter(term) {
  term = term.value.toLowerCase();
  $('tbody tr').removeClass('odd').removeClass('invisible').each(function() {
    var text;
    if (text = $(this).children('td')[0]) {
      if (text.innerHTML.toLowerCase().indexOf(term) < 0) {
        $(this).addClass('invisible');
      }
    }
  });
  $('tbody tr:not(.invisible)').filter(':odd').addClass('odd');
}
