"use strict"

// function chartSuccess(d, c, chartIndex, noAdvice) {

//   var chartDiv = c.renderTo;
//   var $chartDiv = $(chartDiv);
//   var chartType = d.chart1_type;
//   var seriesData = d.series_data;
//   var yAxisLabel = d.y_axis_label;

//   if (! noAdvice) {
//     var titleH3 = $chartDiv.prev('h3');

//     if (chartIndex == 0) {
//       titleH3.text(d.title);
//     } else {
//       titleH3.before('<hr class="analysis"/>');
//       titleH3.text(d.title);
//     }

//     var adviceHeader = d.advice_header;
//     var adviceFooter = d.advice_footer;

//     if (adviceHeader !== undefined) {
//       $chartDiv.before('<div>' + adviceHeader + '</div>');
//     }

//     if (adviceFooter !== undefined) {
//       $chartDiv.after('<div>' + adviceFooter + '</div>');
//     }
//   }

//   console.log("################################");
//   console.log(d.title);
//   console.log("################################");

//   if (chartType == 'bar' || chartType == 'column' || chartType == 'line') {
//     barColumnLine(d, c, chartIndex, seriesData, yAxisLabel, chartType);

//   // Scatter
//   } else if (chartType == 'scatter') {
//     scatter(d, c, chartIndex, seriesData, yAxisLabel);

//   // Pie
//   } else if (chartType == 'pie') {
//     pie(d, c, chartIndex, seriesData, $chartDiv);
//   }
//   c.hideLoading();
// }

$(document).ready(function() {
  if ($("div.simulator-chart").length ) {
    $("div.simulator-chart").each(function(){
      var thisId = this.id;
      var thisChart = Highcharts.chart(thisId, commonChartOptions);
      var chartType = $(this).data('chart-type');
      var chartIndex = $(this).data('chart-index');
      var dataPath = $(this).data('chart-json');
      var noAdvice = $(this).is("[data-no-advice]");

      if (dataPath == undefined) {
        var currentPath = window.location.href
        dataPath = currentPath.substr(0, currentPath.lastIndexOf("/")) + '/chart.json?chart_type=' + chartType;
      }
      console.log(chartType);
      console.log(dataPath);
      thisChart.showLoading();

      $.ajax({
        type: 'GET',
        async: true,
        dataType: "json",
        url: dataPath,
        success: function (returnedData) {
          chartSuccess(returnedData.charts[0], thisChart, chartIndex, noAdvice);
        },
        error: function(broken) {
          console.log("broken");
          var titleH3 = $('div#chart_wrapper_' + chartIndex + ' h3');
          titleH3.text('There was a problem ' + currentText);
          $('div#chart_' + chartIndex).remove();
        }
      });
    });

    $('#new_simulator').on('submit', function(e) {
      e.preventDefault();
      var data = $("#new_simulator :input").serializeArray();

      var currentPath = window.location.href
      var dataPath = currentPath.substr(0, currentPath.lastIndexOf("/")) + '.json';

      $.post(dataPath, data).done(function(data) {
        var chart = $('div#chart_0').highcharts();
        console.log(data);
        chart.series[1].setData(data.charts[0].series_data[0].data);
      });
    });
  }
});
