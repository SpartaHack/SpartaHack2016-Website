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

BigHorizontalBarGraph = function(el, series) {
  series = series[0];
  console.log(series);
  var newSeries = [];
  for(i=0;i<series.length;i++)
  {
    newSeries[i] = {label: series[i][0], inner_label: series[i][1], value: series[i][1], color: "#00EDAB" };
  }
  this.el = d3.select(el);
  this.series = newSeries;
};

BigHorizontalBarGraph.prototype.draw = function() {
  console.log(this.series);

  return HorizontalBarGraph.prototype.draw();
}

var ageData = [$('.data_age_count').data('temp')];
ageName =[];
ageFreq = [];

for(i=0;i<ageData[0].length;i++)
{
    ageName[i] = ageData[0][i][0];
    ageFreq[i] = ageData[0][i][1];
}



var genderValues = [$('.data_gender_count').data('temp')["male"], $('.data_gender_count').data('temp')["female"], $('.data_gender_count').data('temp')["nonbinary"]];
var genderGraph = new HorizontalBarGraph('#gender-graph', [
  {label: "male", inner_label: genderValues[0], value: genderValues[0], color: "#00EDAB" },
  {label: "female",  inner_label: genderValues[1],   value: genderValues[1],  color: "#FFCE80" },
  {label: "nonbinary",  inner_label: genderValues[2],   value: genderValues[2],  color: "#FF8099" }
]);


var ageValues = [$('.data_age_count').data('temp')][0];
var ageGraph = new BigHorizontalBarGraph('#age-graph', [ageValues]);


// $statsOrange: #FFCE80;
// $statsOrange2: #FFBD54;
// $statsPink: #FF8099;
// $statsPink2: #FF5476;
var gradeValues = [$('.data_grade_count').data('temp')][0];
// First Year, Second Year, Third Year, Fourth Year, Fifth Year, Graduate Student, Not a Student
var gradeGraph = new HorizontalBarGraph('#grade-graph', [
  {label: "First Year", inner_label: gradeValues["First Year"], value: gradeValues["First Year"], color: "#00EDAB" },
  {label: "Second Year",  inner_label: gradeValues["Second Year"],   value: gradeValues["Second Year"],  color: "#FFCE80" },
  {label: "Third Year",  inner_label: gradeValues["Third Year"],   value: gradeValues["Third Year"],  color: "#FF8099" },
  {label: "Fourth Year", inner_label: gradeValues["Fourth Year"], value: gradeValues["Fourth Year"], color: "#00EDAB" },
  {label: "Fifth Year",  inner_label: gradeValues["Fifth Year"],   value: gradeValues["Fifth Year"],  color: "#FFCE80" },
  {label: "Fifth Year +",  inner_label: gradeValues["Fifth Year +"],   value: gradeValues["Fifth Year +"],  color: "#00EDAB" },
  {label: "Graduate Student",  inner_label: gradeValues["Graduate Student"],   value: gradeValues["Graduate Student"],  color: "#FFCE80" },
  {label: "Not a Student",  inner_label: gradeValues["Not a Student"],   value: gradeValues["Not a Student"],  color: "#FF8099" }
]);


genderGraph.draw();

// ageGraph.draw();

gradeGraph.draw();

