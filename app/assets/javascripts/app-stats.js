// App stats js

var ageData = [$('.apps_data_age_count').data('temp')];
ageName =[];
ageFreq = [];

for(i=0;i<ageData[0].length;i++)
{
    ageName[i] = ageData[0][i][0];
    ageFreq[i] = ageData[0][i][1];
}

var data = $('.apps_data_submission_dates').data('temp');

var row_width = $('.row').width();

var margin = {top: 20, right: 20, bottom: 30, left: 50},
    width = row_width - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

var parseDate = d3.time.format("%d-%b-%y").parse;

var x = d3.time.scale()
    .range([0, width]);

var y = d3.scale.linear()
    .range([height, 0]);

var xAxis = d3.svg.axis()
    .scale(x)
    .innerTickSize(-height)
    .tickPadding(10)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(y)
    .innerTickSize(-width)
    .tickPadding(10)
    .orient("left");

var line = d3.svg.line()
    .x(function(d) { return x(d.date); })
    .y(function(d) { return y(d.close); });

var svg = d3.select("#apps-submissions-graph").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

data.forEach(function(d) {
  d.date = parseDate(d.date);
  d.close = +d.close;
});

x.domain(d3.extent(data, function(d) { return d.date; }));
y.domain(d3.extent(data, function(d) { return d.close; }));

svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)

svg.append("g")
    .attr("class", "y axis")
    .call(yAxis)
  .append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", 6)
    .attr("dy", ".71em")
    .style("text-anchor", "end")
    .text("Applications submitted per day");

svg.append("path")
    .datum(data)
    .attr("class", "line")
    .attr("d", line);

var genderValues = [$('.apps_data_gender_count').data('temp')][0];
var genderGraph = new HorizontalBarGraph('#apps-gender-graph', [
  {label: "male", inner_label: genderValues["male"], value: genderValues["male"], color: "#00EDAB" },
  {label: "female",  inner_label: genderValues["female"],   value: genderValues["female"],  color: "#FFCE80" },
  {label: "non-binary",  inner_label: genderValues["non-binary"],   value: genderValues["non-binary"],  color: "#FF8099" },
  {label: "prefer-not",  inner_label: genderValues["prefer-not"],   value: genderValues["prefer-not"],  color: "#00EDAB" }
]);


var ageValues = [$('.apps_data_age_count').data('temp')][0];
var ageGraph = new HorizontalBarGraph('#apps-age-graph', [ageValues]);


// $statsOrange: #FFCE80;
// $statsOrange2: #FFBD54;
// $statsPink: #FF8099;
// $statsPink2: #FF5476;
var gradeValues = [$('.apps_data_grade_count').data('temp')][0];
// First Year, Second Year, Third Year, Fourth Year, Fifth Year, Graduate Student, Not a Student, High School Student
var gradeGraph = new HorizontalBarGraph('#apps-grade-graph', [
  {label: "First", inner_label: gradeValues["First Year"], value: gradeValues["First Year"], color: "#00EDAB" },
  {label: "Second",  inner_label: gradeValues["Second Year"],   value: gradeValues["Second Year"],  color: "#FFCE80" },
  {label: "Third",  inner_label: gradeValues["Third Year"],   value: gradeValues["Third Year"],  color: "#FF8099" },
  {label: "Fourth", inner_label: gradeValues["Fourth Year"], value: gradeValues["Fourth Year"], color: "#00EDAB" },
  {label: "Fifth +",  inner_label: gradeValues["Fifth Year +"],   value: gradeValues["Fifth Year +"],  color: "#FFCE80" },
  {label: "Graduate",  inner_label: gradeValues["Graduate Student"],   value: gradeValues["Graduate Student"],  color: "#FF8099" },
  {label: "High School Student",  inner_label: gradeValues["High School Student"],   value: gradeValues["High School Student"],  color: "#FFCE80" },
    {label: "N/A",  inner_label: gradeValues["Not a Student"],   value: gradeValues["Not a Student"],  color: "#00EDAB" }

]);

var hackathonValues = [$('.apps_data_hackathon_count').data('temp')][0];
// First Year, Second Year, Third Year, Fourth Year, Fifth Year, Graduate Student, Not a Student
var hackathonGraph = new HorizontalBarGraph('#apps-hackathon-graph', [
  {label: "0",  inner_label: hackathonValues[0][1],   value: hackathonValues[0][1], color: "#00EDAB" },
  {label: "1",  inner_label: hackathonValues[1][1],   value: hackathonValues[1][1],  color: "#FFCE80" },
  {label: "2",  inner_label: hackathonValues[2][1],   value: hackathonValues[2][1],  color: "#FF8099" },
  {label: "3",  inner_label: hackathonValues[3][1],   value: hackathonValues[3][1], color: "#00EDAB" },
  {label: "4",  inner_label: hackathonValues[4][1],   value: hackathonValues[4][1],  color: "#FFCE80" },
  {label: "5",  inner_label: hackathonValues[5][1],   value: hackathonValues[5][1],  color: "#00EDAB" },
  {label: "6",  inner_label: hackathonValues[6][1],   value: hackathonValues[6][1],  color: "#FFCE80" },
  {label: "7",  inner_label: hackathonValues[7][1],   value: hackathonValues[7][1],  color: "#FF8099" },
  {label: "8",  inner_label: hackathonValues[8][1],   value: hackathonValues[8][1],  color: "#FF8099" },
  {label: "9",  inner_label: hackathonValues[9][1],   value: hackathonValues[9][1], color: "#00EDAB" },
  {label: "10",  inner_label: hackathonValues[10][1],   value: hackathonValues[10][1],  color: "#FFCE80" },
  {label: "11",  inner_label: hackathonValues[11][1],   value: hackathonValues[11][1],  color: "#00EDAB" },
  {label: "12",  inner_label: hackathonValues[12][1],   value: hackathonValues[12][1],  color: "#FFCE80" },
  {label: "13",  inner_label: hackathonValues[13][1],   value: hackathonValues[13][1],  color: "#FF8099" },
  {label: "14",  inner_label: hackathonValues[14][1],   value: hackathonValues[14][1],  color: "#00EDAB" }
]);

genderGraph.draw();

// ageGraph.draw();

gradeGraph.draw();

hackathonGraph.draw();

var word_array = [
      ];

var data_common_words = [$('.apps_data_common_words').data('temp')][0].slice(12,82);

// Check if there are no words -- like on dev :P
if (data_common_words.length == 0) {
  console.log("bruh");
  data_common_words = ["I really want to attend SpartaHack because it sounds awesome!!! This is a default reason for attending SpartaHack."];
} else {
  for(i=0;i<70;i++)
  {
      word_array[i] = {text: data_common_words[i][0], weight: data_common_words[i][1]}
  }

  $("#apps-wordcloud").jQCloud(word_array, {
    removeOverflowing: false,
  });
}