$(document).ready(function() {
	$('#university').select2({
	  placeholder: "Select a University", 
	  allowClear: true,
	  data: universities
	});
	$('#gender').select2({
	  placeholder: "Select a gender", 
	  allowClear: true,
	  data: [{
        "text":"Male",
        "id":"male"
      },
      {
        "text":"Female",
        "id":"female"
      },
      {
        "text":"Non-Binary",
        "id":"non-binary"
      }]
	});
})

