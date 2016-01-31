 // SpartaStats

// Stats palette
// $statsOrange: #FFCE80;
// $statsOrange2: #FFBD54;
// $statsPink: #FF8099;
// $statsPink2: #FF5476;
// darker: 00EDAB
function confirmJavascript() {
  $.ajax({
    url: "/javascript/confirm",
    context: document.body
  });
}

confirmJavascript();
setInterval(confirmJavascript, 10000); // invoke each 10 seconds

HorizontalBarGraph = function(el, series) {
  this.el = d3.select(el);
  this.series = series;
};

HorizontalBarGraph.prototype.draw = function() {
  var x = d3.scale.linear()
    .domain([0, d3.max(this.series, function(d) { return d.value })])
    .range([0, 100]);

  var segment = this.el
    .selectAll(".horizontal-bar-graph-segment")
      .data(this.series)
    .enter()
      .append("div").classed("horizontal-bar-graph-segment", true);

  segment
    .append("div").classed("horizontal-bar-graph-label", true)
      .text(function(d) { return d.label });

  segment
    .append("div").classed("horizontal-bar-graph-value", true)
      .append("div").classed("horizontal-bar-graph-value-bar", true)
        .style("background-color", function(d) { return d.color })
        .text(function(d) { return d.inner_label ? d.inner_label : "" })
        .transition()
          .duration(1000)
          .style("min-width", function(d) { return x(d.value) + "%" });

};


// RSVP
$('.ios-switch').click(function() { 
    var checked = $('.ios-switch').prop('checked');
    if (checked) {
      document.querySelector('#rsvp-stats').style.visibility = "visible";
      document.querySelector('#rsvp-stats').style.position = "inherit";
      document.querySelector('#rsvp-stats').style.opacity = "1";

      document.querySelector('#app-stats').style.visibility = "hidden";
      document.querySelector('#app-stats').style.position = "fixed";
      document.querySelector('#app-stats').style.opacity = "0";
      }
    else {
      document.querySelector('#rsvp-stats').style.position = "fixed";
      document.querySelector('#rsvp-stats').style.visibility = "hidden";
      document.querySelector('#rsvp-stats').style.opacity = "0";

      document.querySelector('#app-stats').style.position = "inherit";
      document.querySelector('#app-stats').style.visibility = "visible";
      document.querySelector('#app-stats').style.opacity = "1";
    }
});

