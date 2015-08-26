$(document).ready(function() {
	$('#university').select2({
	  placeholder: "College/University", 
	  allowClear: true
	});
	$('#gender').select2({
	  placeholder: "Gender", 
	  allowClear: true
	});
	$('#major').select2({
	  placeholder: "Major(s)", 
	  allowClear: true
	});
	$('#gradeLevel').select2({
	  placeholder: "Year in School", 
	  allowClear: true
	});
})

if ($(window).width() < 321) {
	$('#title-desc').css('display', 'none');
	$('#title-hashtag').css('display', 'none');
	if ($(window).height() < 550) {
		$('.logo').css('display', 'none');
	}

}


if ($(window).width() < 550) {
  $("#header").headroom({
    "offset": 205,
    "tolerance": 5,
    "classes": {
      "initial": "animated",
      "pinned": "slideDown",
      "unpinned": "slideUp"
    }
  });
}