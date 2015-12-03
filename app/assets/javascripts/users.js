$(document).ready(function() {	

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

	function confirmJavascript() {
	  $.ajax({
	    url: "/javascript/confirm",
	    context: document.body
	  })
	}

	confirmJavascript();
	setInterval(confirmJavascript, 10000); // invoke each 10 seconds

});