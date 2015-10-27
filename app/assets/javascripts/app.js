function createSelects() {
	$('#university').select2({
	  placeholder: "What university do you attend?", 
	  allowClear: true
	});
	$('#gender').select2({
	  placeholder: "Gender", 
	  allowClear: true,
	});
	$('#birthmonth').select2({
	  placeholder: "Birth Month", 
	  allowClear: true
	});
	$('#birthday').select2({
	  placeholder: "Birth Day", 
	  allowClear: true
	});
	$('#birthyear').select2({
	  placeholder: "Birth Year", 
	  allowClear: true
	});
	$('#major').select2({
	  placeholder: "Field of study", 
	  allowClear: true
	});
	$('#gradeLevel').select2({
	  placeholder: "Year of school", 
	  allowClear: true
	});
	$('#hackathons').select2({
	  placeholder: "What other MLH hackathons have you attended?", 
	  multiple:true
	});
}

$(document).ready(function() {	
	createSelects();

	$('b[role="presentation"]').hide();
	$('.select2-selection__arrow').append('<i class="fa fa-angle-down"></i>');	
	$('.select2-container--open').append('<i class="fa fa-angle-up"></i>');	

	$("#github").click(function() {
		if ($("#github").val() === "") {
			$("#github").val('http://www.github.com/');
		}
	})
	$("#linkedIn").click(function() {
		if ($("#linkedIn").val() === "") {
			$("#linkedIn").val('https://www.linkedin.com/in/');
		}
	})

	$("#devPost").click(function() {
		if ($("#devPost").val() === "") {
			$("#devPost").val('http://www.devpost.com/');
		}
	})

	$("#website").click(function() {
		if ($("#website").val() === "") {
			$("#website").val('http://www.');
		}
	})

	$("#coolLink").click(function() {
		if ($("#coolLink").val() === "") {
			$("#coolLink").val('http://');
		}
	})

	$("#application").on("click", function(e){
		e.preventDefault();
		console.log($('#major').val())
	})

})

$(window).resize(function() {
	createSelects();
})

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

$(function() {
    var pull        = $('#pull');
        menu        = $('.mobile');
 
    $(pull).on('click', function(e) {
        e.preventDefault();
        menu.slideToggle();
    });

    $('.mobile li a').on('click', function(e) {
        menu.slideToggle();
    });

});