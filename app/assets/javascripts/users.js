$(document).ready(function() {	

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
});