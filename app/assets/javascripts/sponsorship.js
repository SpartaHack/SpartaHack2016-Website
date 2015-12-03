function readURL(input) {
	if (input.files && input.files[0]) {
	  var reader = new FileReader();

	  reader.onload = function (e) {
	    $('#img_prev')
	      .attr('src', e.target.result)
	  };

	  reader.readAsDataURL(input.files[0]);
	}
}

$(document).ready(function() {	
	$('#level').select2({
	  placeholder: "Level of Sponsorship", 
	  allowClear: true
	});

	$('b[role="presentation"]').hide();
	$('.select2-selection__arrow').append('<i class="fa fa-angle-down"></i>');	
	$('.select2-container--open').append('<i class="fa fa-angle-up"></i>');	


	if ($(window).width() < 775) {
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

});