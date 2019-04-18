"use strict";

$(document).ready(function() {
  $('a.preview-tab[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var tab = $(e.target);
    var pane  = $(tab.attr('href'));
    var url = pane.data('content-url');
    var form = pane.parents('form');

    $.ajax({
      dataType: 'html',
      url: url,
      processData: false,
      contentType: false,
      data: form.serialize(),
      error: function(jqXHR, textStatus, errorThrown){
        pane.find('.loading').hide();
        pane.find('.content').html('<div class="alert alert-danger">Preview failed</div>');
      },
      success: function(data, textStatus, jqXHR){
        pane.find('.loading').hide();
        pane.find('.content').html(data);
        processAnalysisCharts();
      }
    });
  });

  $('a.preview-tab[data-toggle="tab"]').on('hidden.bs.tab', function (e) {
    var tab = $(e.target);
    var pane  = $(tab.attr('href'));
    pane.find('.loading').show();
    pane.find('.content').html('');
  });
});
