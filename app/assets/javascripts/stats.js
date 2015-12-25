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

var ageData = [$('.data_age_count').data('temp')];
ageName =[];
ageFreq = [];

for(i=0;i<ageData[0].length;i++)
{
    ageName[i] = ageData[0][i][0];
    ageFreq[i] = ageData[0][i][1];
}

var margin = {top: 40, right: 20, bottom: 30, left: 40},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

var formatPercent = d3.format(".0%");

var x = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

var y = d3.scale.linear()
    .range([height, 0]);

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left")
    .tickFormat(formatPercent);

var svg = d3.select("#age-graph").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

svg.append("g")
      .attr("class", "x axis");

svg.append("g")
      .attr("class", "y axis");


data = ageData[0];
x.domain(data.map(function(d) { return d.letter; }));
y.domain([0, d3.max(data, function(d) { return d.frequency; })]);

svg.select(".x.axis").data(data).transition()
  .attr("transform", "translate(0," + height + ")")
  .call(xAxis);


var bars = svg.selectAll(".bar")
  .data(data);

bars.select('rect').transition()
  .attr("y", function(d) { return y(d.frequency); })
  .attr("height", function(d) { return height - y(d.frequency); })

var bars = bars.enter()
  .append("g")
	 	  .attr('class', 'bar')
  .append("rect")
    .attr("x", function(d) { return x(d.letter); })
    .attr("width", x.rangeBand())
    .attr("y", function(d) { return y(d.frequency); })
    .attr("height", function(d) { return height - y(d.frequency); });



var genderValues = [$('.data_gender_count').data('temp')["male"], $('.data_gender_count').data('temp')["female"], $('.data_gender_count').data('temp')["nonbinary"]];
var genderGraph = new HorizontalBarGraph('#gender-graph', [
  {label: "male", inner_label: genderValues[0], value: genderValues[0], color: "#00EDAB" },
  {label: "female",  inner_label: genderValues[1],   value: genderValues[1],  color: "#FFCE80" },
  {label: "nonbinary",  inner_label: genderValues[2],   value: genderValues[2],  color: "#FF8099" }
]);

genderGraph.draw();

