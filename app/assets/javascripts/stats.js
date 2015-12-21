// SpartaStats

// Stats palette
// $statsOrange: #FFCE80;
// $statsOrange2: #FFBD54;
// $statsPink: #FF8099;
// $statsPink2: #FF5476;
// darker: 00EDAB

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

VerticalBarGraph = function(el, series) {
  this.el = d3.select(el);
  this.series = series;
};

VerticalBarGraph.prototype.draw = function() {
  var x = d3.scale.linear()
    .domain([0, d3.max(this.series, function(d) { return d.value })])
    .range([0, 100]);

  var segment = this.el
    .selectAll(".vertical-bar-graph-segment")
      .data(this.series)
    .enter()
      .append("div").classed("vertical-bar-graph-segment", true);

  segment
    .append("div").classed("vertical-bar-graph-label", true)
      .text(function(d) { return d.label });

  segment
    .append("div").classed("vertical-bar-graph-value", true)
      .append("div").classed("vertical-bar-graph-value-bar", true)
        .style("background-color", function(d) { return d.color })
        .text(function(d) { return d.inner_label ? d.inner_label : "" })
        .transition()
          .duration(1000)
          .style("min-width", function(d) { return x(d.value) + "%" });

};


var genderValues = [$('.data_gender_count').data('temp')["male"], $('.data_gender_count').data('temp')["female"], $('.data_gender_count').data('temp')["nonbinary"]];
var genderGraph = new HorizontalBarGraph('#gender-graph', [
  {label: "male", inner_label: genderValues[0], value: genderValues[0], color: "#00EDAB" },
  {label: "female",  inner_label: genderValues[1],   value: genderValues[1],  color: "#FFCE80" },
  {label: "nonbinary",  inner_label: genderValues[2],   value: genderValues[2],  color: "#FF8099" }
]);
var ageGraph = new HorizontalBarGraph('#age-graph', [

]);
genderGraph.draw();
ageGraph.draw();